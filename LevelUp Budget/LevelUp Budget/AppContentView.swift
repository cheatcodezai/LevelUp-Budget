import SwiftUI
import SwiftData

struct AppContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Query private var userSettings: [UserSettings]
    
    private var settings: UserSettings {
        if let existingSettings = userSettings.first {
            return existingSettings
        } else {
            return UserSettings() // Return default settings if none exist
        }
    }
    
    var body: some View {
        Group {
            if authViewModel.currentUser != nil {
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
}

#Preview {
    AppContentView()
        .modelContainer(for: [BillItem.self, SavingsGoal.self, UserSettings.self], inMemory: true)
} 