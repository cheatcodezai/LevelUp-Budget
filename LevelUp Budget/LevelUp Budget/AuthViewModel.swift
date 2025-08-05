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
#elseif os(macOS)
import AuthenticationServices
import CryptoKit
#endif

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    #if os(iOS) || os(macOS)
    private var currentNonce: String?
    private var authorizationController: ASAuthorizationController?
    private var appleSignInDelegate: AppleSignInDelegate?
    private var appleSignInPresentationContextProvider: AppleSignInPresentationContextProvider?
    #endif
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured, skipping auth state listener")
            return
        }
        
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    let newUser = User(
                        id: user.uid,
                        email: user.email,
                        name: user.displayName,
                        authProvider: .email // Default for macOS
                    )
                    self?.currentUser = newUser
                    // Notify CloudKitManager about the user change
                    CloudKitManager.shared.updateGuestStatus(userId: newUser.id)
                } else {
                    self?.currentUser = nil
                    // Notify CloudKitManager that no user is signed in
                    CloudKitManager.shared.updateGuestStatus(userId: nil)
                }
            }
        }
    }
    
    // MARK: - Enhanced Email/Password Authentication with Network Diagnostics
    func signInWithEmail(email: String, password: String) async {
        print("🔍 Starting email sign-in for: \(email)")
        isLoading = true
        errorMessage = nil
        
        // Enhanced network diagnostics for macOS
        #if os(macOS)
        print("🔍 Running network diagnostics for macOS...")
        let networkStatus = await performNetworkDiagnostics()
        if !networkStatus.isConnected {
            await MainActor.run {
                self.errorMessage = "Network connectivity issue detected. Please check your internet connection and try again."
                self.showError = true
                self.isLoading = false
            }
            return
        }
        #endif
        
        // Verify Firebase is properly configured
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase not configured")
            await MainActor.run {
                self.errorMessage = "Firebase configuration error. Please restart the app."
                self.showError = true
                self.isLoading = false
            }
            return
        }
        
        print("🔍 Proceeding with Firebase Auth...")
        
        do {
            print("🔍 Attempting Firebase Auth sign-in...")
            let authResult = try await withTimeout(seconds: 30) {
                try await Auth.auth().signIn(withEmail: email, password: password)
            }
            print("✅ Firebase Auth sign-in successful for user: \(authResult.user.uid)")
            
            await MainActor.run {
                self.currentUser = User(
                    id: authResult.user.uid,
                    email: authResult.user.email,
                    name: authResult.user.displayName,
                    authProvider: .email
                )
                self.isLoading = false
                print("✅ User object created and loading state updated")
            }
            
        } catch {
            print("❌ Firebase Auth sign-in failed: \(error.localizedDescription)")
            await MainActor.run {
                // Enhanced error handling with more specific messages
                let errorMessage = self.getEnhancedUserFriendlyErrorMessage(error)
                self.errorMessage = errorMessage
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    func createAccount(email: String, password: String, name: String) async {
        print("🔍 Starting account creation for: \(email)")
        isLoading = true
        errorMessage = nil
        
        // Enhanced network diagnostics for macOS
        #if os(macOS)
        print("🔍 Running network diagnostics for macOS...")
        let networkStatus = await performNetworkDiagnostics()
        if !networkStatus.isConnected {
            await MainActor.run {
                self.errorMessage = "Network connectivity issue detected. Please check your internet connection and try again."
                self.showError = true
                self.isLoading = false
            }
            return
        }
        #endif
        
        // Verify Firebase is properly configured
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase not configured")
            await MainActor.run {
                self.errorMessage = "Firebase configuration error. Please restart the app."
                self.showError = true
                self.isLoading = false
            }
            return
        }
        
        print("🔍 Proceeding with Firebase Auth...")
        
        do {
            print("🔍 Attempting Firebase Auth account creation...")
            let authResult = try await withTimeout(seconds: 30) {
                try await Auth.auth().createUser(withEmail: email, password: password)
            }
            print("✅ Firebase Auth account creation successful for user: \(authResult.user.uid)")
            
            print("🔍 Updating user profile with name...")
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            print("✅ User profile updated successfully")
            
            await MainActor.run {
                self.currentUser = User(
                    id: authResult.user.uid,
                    email: authResult.user.email,
                    name: authResult.user.displayName,
                    authProvider: .email
                )
                self.isLoading = false
                print("✅ User object created and loading state updated")
            }
            
        } catch {
            print("❌ Firebase Auth account creation failed: \(error.localizedDescription)")
            await MainActor.run {
                // Enhanced error handling with more specific messages
                let errorMessage = self.getEnhancedUserFriendlyErrorMessage(error)
                self.errorMessage = errorMessage
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Apple Sign-In
    func signInWithApple() async {
        #if os(iOS) || os(macOS)
        print("🍎 Starting Apple Sign-In process...")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        print("🍎 Generated nonce: \(nonce)")
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        print("🍎 Created Apple ID request with nonce hash: \(sha256(nonce))")
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        // Create and retain the delegate and presentation context provider
        let delegate = AppleSignInDelegate(authViewModel: self)
        let presentationContextProvider = AppleSignInPresentationContextProvider()
        
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = presentationContextProvider
        
        // Retain the authorization controller and delegates to prevent deallocation
        self.authorizationController = authorizationController
        self.appleSignInDelegate = delegate
        self.appleSignInPresentationContextProvider = presentationContextProvider
        
        print("🍎 Starting authorization requests...")
        authorizationController.performRequests()
        #endif
    }
    
    // MARK: - Handle SignInWithAppleButton Result
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        print("🍎 Apple Sign-In result received: \(result)")
        
        // Clear all the retained references
        await MainActor.run {
            self.authorizationController = nil
            self.appleSignInDelegate = nil
            self.appleSignInPresentationContextProvider = nil
        }
        
        switch result {
        case .success(let authorization):
            print("🍎 Apple Sign-In authorization successful")
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                print("🍎 Error: Unable to fetch identity token")
                await MainActor.run {
                    self.errorMessage = "Unable to fetch identity token"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            guard let nonce = currentNonce else {
                print("🍎 Error: Invalid state - no nonce found")
                await MainActor.run {
                    self.errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("🍎 Error: Unable to fetch identity token")
                await MainActor.run {
                    self.errorMessage = "Unable to fetch identity token"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("🍎 Error: Unable to serialize token string from data")
                await MainActor.run {
                    self.errorMessage = "Unable to serialize token string from data"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            print("🍎 Creating Firebase credential with Apple ID token")
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            do {
                print("🍎 Signing in to Firebase with Apple credential...")
                let result = try await Auth.auth().signIn(with: credential)
                print("🍎 Firebase sign-in successful for user: \(result.user.uid)")
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
                print("🍎 Firebase sign-in failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                }
            }
            
        case .failure(let error):
            print("🍎 Apple Sign-In failed: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    #if os(iOS) || os(macOS)
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
    #endif
    
    #if os(iOS) || os(macOS)
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
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
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
    #elseif os(macOS)
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        // For macOS, we'll show an error message since Google Sign-In requires additional setup
        await MainActor.run {
            self.errorMessage = "Google Sign-In for macOS requires additional configuration. Please use Apple Sign-In or Email Sign-In instead."
            self.showError = true
            self.isLoading = false
        }
    }
    #endif
    
    // MARK: - Guest Sign-In
    func signInAsGuest() async {
        isLoading = true
        errorMessage = nil
        
        // Create a local guest user without Firebase Auth calls
        await MainActor.run {
            let guestUser = User(
                id: "guest_\(UUID().uuidString)",
                email: nil,
                name: "Guest User",
                authProvider: .local
            )
            self.currentUser = guestUser
            self.isLoading = false
            
            // Notify CloudKitManager about the guest user
            CloudKitManager.shared.updateGuestStatus(userId: guestUser.id)
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
    
    // MARK: - Enhanced Network Diagnostics for macOS
    #if os(macOS)
    private func performNetworkDiagnostics() async -> NetworkStatus {
        print("🔍 Performing comprehensive network diagnostics...")
        
        var status = NetworkStatus()
        
        // Test basic connectivity
        let connectivityResult = await checkBasicConnectivity()
        status.isConnected = connectivityResult
        
        if !connectivityResult {
            print("❌ Basic connectivity test failed")
            return status
        }
        
        // Test Firebase-specific endpoints
        let firebaseResult = await checkFirebaseConnectivity()
        status.canReachFirebase = firebaseResult
        
        if !firebaseResult {
            print("❌ Firebase connectivity test failed")
            return status
        }
        
        // Test DNS resolution
        let dnsResult = await checkDNSResolution()
        status.dnsWorking = dnsResult
        
        print("✅ Network diagnostics completed:")
        print("   - Basic connectivity: \(connectivityResult)")
        print("   - Firebase connectivity: \(firebaseResult)")
        print("   - DNS resolution: \(dnsResult)")
        
        return status
    }
    
    private func checkBasicConnectivity() async -> Bool {
        let testUrls = [
            "https://www.apple.com",
            "https://www.google.com",
            "https://www.cloudflare.com"
        ]
        
        for urlString in testUrls {
            do {
                let url = URL(string: urlString)!
                let (_, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Basic connectivity confirmed with \(urlString)")
                        return true
                    }
                }
            } catch {
                print("❌ Failed to connect to \(urlString): \(error.localizedDescription)")
                continue
            }
        }
        
        return false
    }
    
    private func checkFirebaseConnectivity() async -> Bool {
        let firebaseUrls = [
            "https://firebase.google.com",
            "https://console.firebase.google.com"
        ]
        
        for urlString in firebaseUrls {
            do {
                let url = URL(string: urlString)!
                let (_, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Firebase connectivity confirmed with \(urlString)")
                        return true
                    }
                }
            } catch {
                print("❌ Failed to connect to Firebase endpoint \(urlString): \(error.localizedDescription)")
                continue
            }
        }
        
        return false
    }
    
    private func checkDNSResolution() async -> Bool {
        let domains = ["google.com", "firebase.google.com", "apple.com"]
        
        for domain in domains {
            do {
                let host = try await withCheckedThrowingContinuation { continuation in
                    DispatchQueue.global().async {
                        let host = CFHostCreateWithName(nil, domain as CFString).takeRetainedValue()
                        CFHostStartInfoResolution(host, .addresses, nil)
                        
                        var success: DarwinBoolean = false
                        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? {
                            continuation.resume(returning: addresses.count > 0)
                        } else {
                            continuation.resume(throwing: NSError(domain: "DNS", code: -1, userInfo: nil))
                        }
                    }
                }
                if host {
                    print("✅ DNS resolution working for \(domain)")
                    return true
                }
            } catch {
                print("❌ DNS resolution failed for \(domain): \(error.localizedDescription)")
                continue
            }
        }
        
        return false
    }
    #endif
    
    // MARK: - Enhanced Error Handling
    private func getEnhancedUserFriendlyErrorMessage(_ error: Error) -> String {
        print("🔍 Analyzing error: \(error.localizedDescription)")
        
        // Handle Firebase Auth errors properly
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .networkError:
                return "Network connection issue. Please check your internet connection and try again. If the problem persists, try restarting the app."
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
            case .operationNotAllowed:
                return "Email/password sign-in is not enabled. Please contact support."
            case .invalidCredential:
                return "Invalid credentials. Please check your email and password."
            default:
                return "Authentication error: \(authError.localizedDescription). Please try again."
            }
        } else {
            // Handle other types of errors
            let errorDescription = error.localizedDescription.lowercased()
            
            if errorDescription.contains("network") || errorDescription.contains("connection") {
                return "Network connection issue. Please check your internet connection and try again."
            } else if errorDescription.contains("timeout") {
                return "Request timed out. Please check your internet connection and try again."
            } else if errorDescription.contains("firebase") {
                return "Firebase configuration error. Please restart the app."
            } else {
                return "An unexpected error occurred: \(error.localizedDescription). Please try again."
            }
        }
    }
    
    // MARK: - Helper Methods
    private func checkNetworkConnectivity() async -> Bool {
        print("🔍 Checking network connectivity...")
        
        // Try multiple URLs to ensure connectivity
        let testUrls = [
            "https://www.apple.com",
            "https://www.google.com", 
            "https://www.cloudflare.com"
        ]
        
        for urlString in testUrls {
            do {
                print("🔍 Testing connectivity with: \(urlString)")
                let url = URL(string: urlString)!
                let (_, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Network connectivity confirmed with \(urlString) - Status: \(httpResponse.statusCode)")
                    return httpResponse.statusCode == 200
                }
            } catch {
                print("❌ Failed to connect to \(urlString): \(error.localizedDescription)")
                continue
            }
        }
        
        print("❌ All network connectivity tests failed")
        return false
    }
    
    // MARK: - Timeout Helper
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AuthError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Network Status Structure
#if os(macOS)
struct NetworkStatus {
    var isConnected: Bool = false
    var canReachFirebase: Bool = false
    var dnsWorking: Bool = false
}
#endif

// MARK: - Apple Sign-In Delegates
#if os(iOS) || os(macOS)
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple Sign-In delegate: Authorization completed successfully")
        Task {
            await authViewModel.handleAppleSignInResult(.success(authorization))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("🍎 Apple Sign-In delegate: Authorization failed with error: \(error.localizedDescription)")
        Task {
            await authViewModel.handleAppleSignInResult(.failure(error))
        }
    }
}

class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("🍎 Apple Sign-In: Getting presentation anchor")
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ Apple Sign-In: No window found on iOS")
            fatalError("No window found")
        }
        print("🍎 Apple Sign-In: Using iOS window for presentation")
        return window
        #elseif os(macOS)
        guard let window = NSApplication.shared.windows.first else {
            print("❌ Apple Sign-In: No window found on macOS")
            fatalError("No window found")
        }
        print("🍎 Apple Sign-In: Using macOS window for presentation")
        return window
        #endif
    }
}
#endif

// MARK: - Auth Error
enum AuthError: Error, LocalizedError {
    case invalidCredential
    case configurationError
    case presentationError
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credentials"
        case .configurationError:
            return "Configuration error"
        case .presentationError:
            return "Presentation error"
        case .timeout:
            return "Operation timed out. Please try again."
        }
    }
} 