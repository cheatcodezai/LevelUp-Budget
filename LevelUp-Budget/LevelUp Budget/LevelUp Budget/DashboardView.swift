import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bills: [BillItem]
    @Query private var savingsGoals: [SavingsGoal]
    @Query private var userSettings: [UserSettings]
    
    var body: some View {
        ContentView()
            .toolbar {
                #if os(iOS) || os(tvOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        print("Sign out button tapped")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Sign Out") {
                        print("Sign out button tapped")
                    }
                }
                #endif
            }
            .onAppear {
                print("📊 DashboardView appeared")
            }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [BillItem.self, SavingsGoal.self, UserSettings.self], inMemory: true)
} 