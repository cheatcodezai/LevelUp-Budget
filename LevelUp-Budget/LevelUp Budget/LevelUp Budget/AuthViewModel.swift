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
        // Always start with no user to ensure proper authentication flow
        self.currentUser = nil
        
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured, skipping auth state listener")
            // Ensure user is not authenticated when Firebase is unavailable
            self.currentUser = nil
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
        
        // Additional check: verify current Firebase auth state
        // For simulator testing, we might want to force a fresh login
        #if targetEnvironment(simulator)
        print("🔍 Running in simulator - forcing fresh authentication for testing")
        // In simulator, we can optionally force sign out for testing
        // Uncomment the next line if you want to force fresh login in simulator
        // try? Auth.auth().signOut()
        #endif
        
        if let currentUser = Auth.auth().currentUser {
            print("🔍 Found existing Firebase user: \(currentUser.uid)")
            let user = User(
                id: currentUser.uid,
                email: currentUser.email,
                name: currentUser.displayName,
                authProvider: .email
            )
            self.currentUser = user
            CloudKitManager.shared.updateGuestStatus(userId: user.id)
        } else {
            print("🔍 No existing Firebase user found")
            self.currentUser = nil
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
            print("✅ User signed out successfully")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error during sign out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Force Sign Out (for security)
    func forceSignOut() {
        // Force sign out regardless of Firebase state
        do {
            try Auth.auth().signOut()
        } catch {
            print("⚠️ Firebase sign out failed: \(error.localizedDescription)")
        }
        
        // Always clear the current user
        currentUser = nil
        print("✅ User force signed out")
    }
    
    // MARK: - Simulator Testing Helper
    #if targetEnvironment(simulator)
    /// Force sign out for simulator testing (removes auto-login)
    func forceSignOutForTesting() {
        print("🧪 Simulator testing mode - forcing sign out")
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            CloudKitManager.shared.updateGuestStatus(userId: nil)
            print("✅ Successfully signed out for testing")
        } catch {
            print("❌ Failed to sign out for testing: \(error.localizedDescription)")
        }
    }
    #endif
    
    // MARK: - Check Authentication Status
    func checkAuthenticationStatus() -> Bool {
        // Verify Firebase is configured
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured during auth check")
            currentUser = nil
            return false
        }
        
        // Check if there's a valid Firebase user
        if let firebaseUser = Auth.auth().currentUser {
            // Verify the user is still valid
            if firebaseUser.isEmailVerified || firebaseUser.providerData.contains(where: { $0.providerID == "apple.com" }) {
                print("✅ Valid Firebase user found: \(firebaseUser.uid)")
                return true
            } else {
                print("⚠️ Firebase user found but not verified: \(firebaseUser.uid)")
                forceSignOut()
                return false
            }
        } else {
            print("🔍 No Firebase user found during auth check")
            currentUser = nil
            return false
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