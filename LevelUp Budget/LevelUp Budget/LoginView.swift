import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEmailSignIn = false
    @State private var isLoading = false
    @State private var logoScale: CGFloat = 0.9
    @State private var logoOpacity: Double = 0.0
    @State private var cardOffset: CGFloat = 50
    @State private var cardOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Solid black background for dark mode compatibility
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                
                // Header Logo & Welcome Section
                VStack(spacing: 20) {
                    // Animated Logo
                    ZStack {
                        // Green rounded square outline
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0, green: 1, blue: 0.4), lineWidth: 2)
                            .frame(width: 70, height: 70)
                        
                        // Upward-right arrow inside square
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                    }
                    .shadow(color: Color(red: 0, green: 1, blue: 0.4).opacity(0.3), radius: 15)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Brand Text with enhanced styling
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("LEVEL")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                            
                            Text("UP")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }
                        
                        Text("BUDGET")
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(.white)
                    }
                    
                    Text("Track smarter. Save faster.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Authentication Card with Enhanced Dark Theme
                VStack(spacing: 16) {
                    // Apple Sign-In Button (iOS only)
                    #if os(iOS)
                    EnhancedSignInButton(
                        icon: "applelogo",
                        text: "Sign in with Apple",
                        backgroundColor: Color.black,
                        foregroundColor: .white,
                        action: {
                            print("🔐 Apple Sign-In button tapped")
                            Task {
                                await authViewModel.signInWithApple()
                            }
                        }
                    )
                    #endif
                    
                    // Google Sign-In Button (iOS only)
                    #if os(iOS)
                    EnhancedSignInButton(
                        icon: "globe",
                        text: "Sign in with Google",
                        backgroundColor: Color.blue.opacity(0.8),
                        foregroundColor: .white,
                        action: {
                            print("🔐 Google Sign-In button tapped")
                            Task {
                                await authViewModel.signInWithGoogle()
                            }
                        }
                    )
                    #endif
                    
                    // Email Sign-In Button
                    EnhancedSignInButton(
                        icon: "envelope",
                        text: "Sign in with Email",
                        backgroundColor: Color.gray.opacity(0.3),
                        foregroundColor: .white,
                        action: {
                            print("🔐 Email Sign-In button tapped")
                            showingEmailSignIn = true
                        }
                    )
                    
                    // Continue without signing in
                    EnhancedSignInButton(
                        icon: "person.crop.circle",
                        text: "Continue without signing in",
                        backgroundColor: Color.clear,
                        foregroundColor: .gray,
                        action: {
                            print("🔐 Guest Sign-In button tapped")
                            Task {
                                await authViewModel.signInAsGuest()
                            }
                        }
                    )
                }
                .padding(.horizontal, 40)
                .offset(y: cardOffset)
                .opacity(cardOpacity)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // TODO: Open Terms of Service
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                        
                        Text("and")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Button("Privacy Policy") {
                            // TODO: Open Privacy Policy
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                cardOffset = 0
                cardOpacity = 1.0
            }
        }
        .sheet(isPresented: $showingEmailSignIn) {
            EmailSignInView()
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") { }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
        .overlay {
            if authViewModel.isLoading {
                LoadingView()
            }
        }
    }
}

// MARK: - Enhanced Sign-In Button
struct EnhancedSignInButton: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(backgroundColor == Color.clear ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Email Sign-In View
struct EmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var name = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isSignUp ? "Create Account" : "Sign In")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        if isSignUp {
                            await authViewModel.createAccount(email: email, password: password, name: name)
                        } else {
                            await authViewModel.signInWithEmail(email: email, password: password)
                        }
                        dismiss()
                    }
                }) {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0, green: 1, blue: 0.4))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") { }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0, green: 1, blue: 0.4)))
                
                Text("Signing in...")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
} 