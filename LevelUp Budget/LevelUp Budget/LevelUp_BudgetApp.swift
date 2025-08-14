//
//  LevelUp_BudgetApp.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct LevelUp_BudgetApp: App {
    
    // MARK: - App Delegate for Push Notifications
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var sharedModelContainer: ModelContainer {
        print("🔧 Starting ModelContainer initialization...")
        
        let schema = Schema([
            BillItem.self,
            SavingsGoal.self,
            UserSettings.self
        ])
        
        print("📋 Schema created with \(schema.entities.count) entities")
        
        // Strategy 1: Try with persistent storage (default)
        print("🔄 Attempting persistent storage...")
        do {
            let container = try ModelContainer(for: schema)
            print("✅ ModelContainer created successfully with persistent storage")
            return container
        } catch {
            print("❌ Failed to create ModelContainer with persistent storage: \(error)")
            print("📝 Error details: \(error.localizedDescription)")
            
            // Strategy 2: Try with explicit persistent configuration
            print("🔄 Attempting explicit persistent configuration...")
            let persistentConfig = ModelConfiguration(isStoredInMemoryOnly: false)
            do {
                let container = try ModelContainer(for: schema, configurations: [persistentConfig])
                print("✅ ModelContainer created successfully with explicit persistent configuration")
                return container
            } catch {
                print("❌ Failed to create ModelContainer with explicit persistent configuration: \(error)")
                print("📝 Error details: \(error.localizedDescription)")
                
                // Strategy 3: Try with minimal configuration
                print("🔄 Attempting minimal configuration...")
                let minimalConfig = ModelConfiguration()
                do {
                    let container = try ModelContainer(for: schema, configurations: [minimalConfig])
                    print("✅ ModelContainer created successfully with minimal configuration")
                    return container
                } catch {
                    print("❌ Failed to create ModelContainer with minimal configuration: \(error)")
                    print("📝 Error details: \(error.localizedDescription)")
                    
                    // Strategy 4: Try with just one model at a time to isolate the issue
                    print("🔄 Attempting with single model to isolate issue...")
                    do {
                        let singleSchema = Schema([BillItem.self])
                        let container = try ModelContainer(for: singleSchema)
                        print("✅ ModelContainer created successfully with single model (BillItem)")
                        return container
                    } catch {
                        print("❌ Failed to create ModelContainer with single model: \(error)")
                        print("📝 Error details: \(error.localizedDescription)")
                        
                        // Final fallback - create a completely minimal container
                        print("🔄 Attempting completely minimal container...")
                        do {
                            let container = try ModelContainer(for: Schema([]))
                            print("✅ ModelContainer created successfully with empty schema")
                            return container
                        } catch {
                            print("❌ Failed to create even minimal ModelContainer: \(error)")
                            print("📝 Error details: \(error.localizedDescription)")
                            fatalError("Could not create ModelContainer: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    #if os(iOS)
                    // Configure tab bar appearance globally - all tabs same color
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = UIColor.black
                    
                    // All states use white text/icons for consistency
                    appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
                    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                        .foregroundColor: UIColor.white
                    ]
                    
                    appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                        .foregroundColor: UIColor.white
                    ]
                    
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                    #endif
                    
                    // Trigger automatic duplicate cleanup on app launch
                    print("🚀 App launched - scheduling duplicate cleanup...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        triggerAutomaticDuplicateCleanup()
                    }
                }
        }
    }
    
    // MARK: - Automatic Duplicate Cleanup
    
    /// Trigger automatic duplicate cleanup when safe to do so
    private func triggerAutomaticDuplicateCleanup() {
        print("🧹 Triggering automatic duplicate cleanup...")
        
        // Only run cleanup if CloudKit is available and user is authenticated
        guard CloudKitManager.shared.isCloudKitAvailable else {
            print("⚠️ CloudKit not available - skipping duplicate cleanup")
            return
        }
        
        // Run cleanup in background to avoid blocking UI
        Task {
            await performBackgroundDuplicateCleanup()
        }
    }
    
    /// Perform duplicate cleanup in background
    private func performBackgroundDuplicateCleanup() async {
        print("🔍 Starting background duplicate cleanup...")
        
        // Small delay to ensure app is fully loaded
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Get current data for cleanup
        let modelContainer = sharedModelContainer
        let modelContext = ModelContext(modelContainer)
        
        // Fetch current bills and savings
        let billDescriptor = FetchDescriptor<BillItem>()
        let savingsDescriptor = FetchDescriptor<SavingsGoal>()
        
        do {
            let bills = try modelContext.fetch(billDescriptor)
            let savings = try modelContext.fetch(savingsDescriptor)
            
            print("📊 Found \(bills.count) bills and \(savings.count) savings goals for cleanup")
            
            // Run the enhanced cleanup on main thread to avoid concurrency issues
            await MainActor.run {
                CloudKitManager.shared.cleanupDuplicates(bills: bills, savings: savings, modelContext: modelContext)
            }
            
            print("✅ Background duplicate cleanup completed")
            
        } catch {
            print("❌ Error during background cleanup: \(error.localizedDescription)")
        }
    }
}

