//
//  AuthViewModel.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
#if os(iOS)
import GoogleSignIn
import AuthenticationServices
import CryptoKit
#endif

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    #if os(iOS)
    private var currentNonce: String?
    #endif
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        // Add error handling for Firebase Auth initialization
        do {
            _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor in
                    if let user = user {
                        self?.currentUser = User(
                            id: user.uid,
                            email: user.email,
                            name: user.displayName,
                            authProvider: .email // Default for macOS
                        )
                    } else {
                        self?.currentUser = nil
                    }
                }
            }
        } catch {
            print("❌ Firebase Auth initialization error: \(error.localizedDescription)")
            // Don't show error to user for initialization issues
        }
    }
    
    // MARK: - Email/Password Authentication
    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            await MainActor.run {
                self.currentUser = User(
                    id: authResult.user.uid,
                    email: authResult.user.email,
                    name: authResult.user.displayName,
                    authProvider: .email
                )
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                // Provide more user-friendly error messages
                let errorMessage = self.getUserFriendlyErrorMessage(error)
                self.errorMessage = errorMessage
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    func createAccount(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            await MainActor.run {
                self.currentUser = User(
                    id: authResult.user.uid,
                    email: authResult.user.email,
                    name: authResult.user.displayName,
                    authProvider: .email
                )
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                // Provide more user-friendly error messages
                let errorMessage = self.getUserFriendlyErrorMessage(error)
                self.errorMessage = errorMessage
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Apple Sign-In
    #if os(iOS)
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = AppleSignInDelegate(authViewModel: self)
        authorizationController.presentationContextProvider = AppleSignInPresentationContextProvider()
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unable to fetch identity token"
                showError = true
                isLoading = false
                return
            }
            
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch identity token"
                showError = true
                isLoading = false
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize token string from data"
                showError = true
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    await MainActor.run {
                        self.currentUser = User(
                            id: result.user.uid,
                            email: result.user.email,
                            name: result.user.displayName,
                            authProvider: .apple
                        )
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        self.isLoading = false
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
    #endif
    
    // MARK: - Google Sign-In
    #if os(iOS)
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error"
            showError = true
            isLoading = false
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            errorMessage = "No root view controller found"
            showError = true
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Unable to get ID token"
                showError = true
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            await MainActor.run {
                self.currentUser = User(
                    id: authResult.user.uid,
                    email: authResult.user.email,
                    name: authResult.user.displayName,
                    authProvider: .google
                )
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
    #endif
    
    // MARK: - Guest Sign-In
    func signInAsGuest() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            
            await MainActor.run {
                self.currentUser = User(
                    id: authResult.user.uid,
                    email: nil,
                    name: "Guest User",
                    authProvider: .email // Use email as fallback for macOS
                )
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Helper Methods
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        // Handle Firebase Auth errors properly
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .networkError:
                return "Network error. Please check your internet connection and try again."
            case .userNotFound:
                return "Account not found. Please check your email and password."
            case .wrongPassword:
                return "Incorrect password. Please try again."
            case .invalidEmail:
                return "Invalid email address. Please enter a valid email."
            case .weakPassword:
                return "Password is too weak. Please choose a stronger password."
            case .emailAlreadyInUse:
                return "An account with this email already exists."
            case .tooManyRequests:
                return "Too many failed attempts. Please try again later."
            case .userDisabled:
                return "This account has been disabled. Please contact support."
            default:
                return "An error occurred. Please try again."
            }
        } else {
            // Fallback for other types of errors
            return error.localizedDescription
        }
    }
}

// MARK: - Apple Sign-In Delegates
#if os(iOS)
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        authViewModel.handleAppleSignInResult(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authViewModel.handleAppleSignInResult(.failure(error))
    }
}

class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}
#endif

// MARK: - Auth Error
enum AuthError: Error, LocalizedError {
    case invalidCredential
    case configurationError
    case presentationError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credentials"
        case .configurationError:
            return "Configuration error"
        case .presentationError:
            return "Presentation error"
        }
    }
} 