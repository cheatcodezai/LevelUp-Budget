import SwiftUI
import SwiftData

struct AppContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Query private var userSettings: [UserSettings]
    @State private var isCheckingAuth = true
    
    private var settings: UserSettings {
        if let existingSettings = userSettings.first {
            return existingSettings
        } else {
            return UserSettings() // Return default settings if none exist
        }
    }
    
    var body: some View {
        Group {
            if isCheckingAuth {
                // Show loading while checking authentication
                LoadingView()
                    .onAppear {
                        checkAuthenticationStatus()
                    }
            } else if authViewModel.currentUser != nil {
                ContentView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        print("🎯 AppContentView - User authenticated, showing ContentView")
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        print("🎯 AppContentView - User not authenticated, showing LoginView")
                    }
            }
        }
        .onAppear {
            print("🎯 AppContentView appeared - auth state: \(authViewModel.currentUser != nil)")
        }
    }
    
    private func checkAuthenticationStatus() {
        print("🔍 Checking authentication status...")
        
        // Force authentication check
        let isAuthenticated = authViewModel.checkAuthenticationStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCheckingAuth = false
            print("🔍 Authentication check complete: \(isAuthenticated)")
        }
    }
}

#Preview {
    AppContentView()
        .modelContainer(for: [BillItem.self, SavingsGoal.self, UserSettings.self], inMemory: true)
} 