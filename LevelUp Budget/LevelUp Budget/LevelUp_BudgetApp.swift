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
        
        // Strategy 1: Try with in-memory storage
        print("🔄 Attempting in-memory storage...")
        let inMemoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
            print("✅ ModelContainer created successfully with in-memory storage")
            return container
        } catch {
            print("❌ Failed to create ModelContainer with in-memory storage: \(error)")
            print("📝 Error details: \(error.localizedDescription)")
            
            // Strategy 2: Try with default configuration
            print("🔄 Attempting default configuration...")
            do {
                let container = try ModelContainer(for: schema)
                print("✅ ModelContainer created successfully with default configuration")
                return container
            } catch {
                print("❌ Failed to create ModelContainer with default configuration: \(error)")
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
                        let container = try ModelContainer(for: singleSchema, configurations: [inMemoryConfig])
                        print("✅ ModelContainer created successfully with single model (BillItem)")
                        return container
                    } catch {
                        print("❌ Failed to create ModelContainer with single model: \(error)")
                        print("📝 Error details: \(error.localizedDescription)")
                        
                        // Final fallback - create a completely minimal container
                        print("🔄 Attempting completely minimal container...")
                        do {
                            let container = try ModelContainer(for: Schema([]), configurations: [inMemoryConfig])
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
        }
    }
}

