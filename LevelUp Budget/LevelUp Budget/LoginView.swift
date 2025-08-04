import SwiftUI
#if os(iOS) || os(macOS)
import AuthenticationServices
#endif

// MARK: - Conditional View Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

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
                    // Apple Sign-In Button (iOS and macOS)
                    #if os(iOS)
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        Task {
                            await authViewModel.handleAppleSignInResult(result)
                        }
                    })
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 400 : .infinity)
                    #elseif os(macOS)
                    // macOS Apple Sign-In button with matching styling
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
                    
                    // Google Sign-In Button (iOS and macOS)
                    #if os(iOS)
                    EnhancedSignInButton(
                        icon: "globe",
                        text: "Sign in with Google",
                        backgroundColor: .white,
                        foregroundColor: .black,
                        action: {
                            print("🔐 Google Sign-In button tapped")
                            Task {
                                await authViewModel.signInWithGoogle()
                            }
                        }
                    )
                    #elseif os(macOS)
                    // macOS Google Sign-In button
                    EnhancedSignInButton(
                        icon: "globe",
                        text: "Sign in with Google",
                        backgroundColor: Color.blue,
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
                    #if os(iOS)
                    EnhancedSignInButton(
                        icon: "envelope",
                        text: "Sign in with Email",
                        backgroundColor: .white,
                        foregroundColor: .black,
                        action: {
                            print("🔐 Email Sign-In button tapped")
                            showingEmailSignIn = true
                        }
                    )
                    #else
                    EnhancedSignInButton(
                        icon: "envelope",
                        text: "Sign in with Email",
                        backgroundColor: Color.gray,
                        foregroundColor: .white,
                        action: {
                            print("🔐 Email Sign-In button tapped")
                            showingEmailSignIn = true
                        }
                    )
                    #endif
                    
                    // Divider for iPad and macOS
                    #if os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .padding(.vertical, 8)
                    }
                    #elseif os(macOS)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    #endif
                    
                    // Continue without signing in
                    #if os(iOS)
                    EnhancedSignInButton(
                        icon: "person.crop.circle",
                        text: "Continue without signing in",
                        backgroundColor: Color.gray.opacity(0.2),
                        foregroundColor: .white,
                        action: {
                            print("🔐 Guest Sign-In button tapped")
                            Task {
                                await authViewModel.signInAsGuest()
                            }
                        }
                    )
                    #else
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
                    #endif
                }
                .padding(.horizontal, 40)
                #if os(iOS)
                .if(UIDevice.current.userInterfaceIdiom == .pad) { view in
                    view
                        .frame(maxWidth: .infinity)
                        .frame(alignment: .center)
                }
                #endif
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                
                Text(text)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 8)
            #if os(iOS)
            .if(UIDevice.current.userInterfaceIdiom == .pad) { view in
                view
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
            }
            #endif
            #if os(macOS)
            .frame(maxWidth: 400)
            #endif
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Button View for Sign In/Create Account
struct CustomButtonView: View {
    let text: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text(text)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.133, green: 0.773, blue: 0.369))
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 8)
            #if os(iOS)
            .if(UIDevice.current.userInterfaceIdiom == .pad) { view in
                view
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
            }
            #endif
            #if os(macOS)
            .frame(maxWidth: 400)
            #endif
        }
        .disabled(isLoading)
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
        #if os(macOS)
        // macOS - completely rebuilt with clean, modern UI
        ZStack {
            // Clean background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Main content card
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0, green: 1, blue: 0.4), lineWidth: 2)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                    }
                    
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Enter your details to continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.top, 40)
                
                // Form Fields - Completely rebuilt
                VStack(spacing: 16) {
                    if isSignUp {
                        CleanTextField(
                            text: $name,
                            placeholder: "Full Name",
                            icon: "person"
                        )
                    }
                    
                    CleanTextField(
                        text: $email,
                        placeholder: "Email Address",
                        icon: "envelope"
                    )
                    
                    CleanSecureField(
                        text: $password,
                        placeholder: "Password",
                        icon: "lock"
                    )
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: 500)
                
                // Sign In/Up Button - Custom styling
                CustomButtonView(
                    text: isSignUp ? "Create Account" : "Sign In",
                    icon: isSignUp ? "person.badge.plus" : "arrow.right",
                    isLoading: authViewModel.isLoading,
                    action: {
                        Task {
                            if isSignUp {
                                await authViewModel.createAccount(email: email, password: password, name: name)
                            } else {
                                await authViewModel.signInWithEmail(email: email, password: password)
                            }
                            dismiss()
                        }
                    }
                )
                .padding(.top, 8)
                
                // Toggle Sign In/Up with consistent styling
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSignUp.toggle()
                    }
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
                
                // Cancel Button with consistent macOS look
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
                .padding(.top, 20)
                
                Spacer()
            }
            .frame(maxWidth: 600)
            .frame(maxHeight: 700)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") { }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
        #else
        // iOS - use NavigationView as before
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        // Logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.133, green: 0.773, blue: 0.369), lineWidth: 2) // #22C55E
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.369)) // #22C55E
                        }
                        .shadow(color: Color(red: 0.133, green: 0.773, blue: 0.369).opacity(0.3), radius: 12) // #22C55E
                        
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your details to continue")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        if isSignUp {
                            ModernTextField(
                                text: $name,
                                placeholder: "Full Name",
                                icon: "person"
                            )
                        }
                        
                        ModernTextField(
                            text: $email,
                            placeholder: "Email Address",
                            icon: "envelope"
                        )
                        
                        ModernSecureField(
                            text: $password,
                            placeholder: "Password",
                            icon: "lock"
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    // Sign In/Up Button
                    CustomButtonView(
                        text: isSignUp ? "Create Account" : "Sign In",
                        icon: isSignUp ? "person.badge.plus" : "arrow.right",
                        isLoading: authViewModel.isLoading,
                        action: {
                            Task {
                                if isSignUp {
                                    await authViewModel.createAccount(email: email, password: password, name: name)
                                } else {
                                    await authViewModel.signInWithEmail(email: email, password: password)
                                }
                                dismiss()
                            }
                        }
                    )
                    .disabled(authViewModel.isLoading)
                    
                    // Toggle Sign In/Up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.369)) // #22C55E
                    }
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.369)) // #22C55E
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") { }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
        #endif
    }
}

// MARK: - Modern Text Field Components
struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .accentColor(Color(red: 0, green: 1, blue: 0.4)) // #00FF66
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 16, weight: .medium))
                }
                .onTapGesture {
                    isFocused = true
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color(red: 0, green: 1, blue: 0.4).opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        #if os(macOS)
        .frame(maxWidth: 500)
        #endif
        .onTapGesture {
            isFocused = true
        }
    }
}

struct ModernSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            SecureField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .accentColor(Color(red: 0, green: 1, blue: 0.4)) // #00FF66
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 16, weight: .medium))
                }
                .onTapGesture {
                    isFocused = true
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color(red: 0, green: 1, blue: 0.4).opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        #if os(macOS)
        .frame(maxWidth: 500)
        #endif
        .onTapGesture {
            isFocused = true
        }
    }
}

// MARK: - macOS Specific Text Field Components
#if os(macOS)
struct CleanTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .accentColor(Color(red: 0, green: 1, blue: 0.4))
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    isFocused = true
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color(red: 0, green: 1, blue: 0.4).opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .frame(maxWidth: 500)
        .onTapGesture {
            isFocused = true
        }
    }
}

struct CleanSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            SecureField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .accentColor(Color(red: 0, green: 1, blue: 0.4))
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    isFocused = true
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color(red: 0, green: 1, blue: 0.4).opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .frame(maxWidth: 500)
        .onTapGesture {
            isFocused = true
        }
    }
}
#endif

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
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
