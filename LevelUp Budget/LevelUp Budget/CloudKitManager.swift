//
//  CloudKitManager.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import Foundation
import CloudKit
import SwiftData
import Network

// MARK: - Network Monitor

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - CloudKit Manager for iCloud Sync
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // CloudKit container and database
    private var container: CKContainer? {
        // Use your specific CloudKit container identifier
        return CKContainer(identifier: "iCloud.com.cheatcodez.LevelupBudget")
    }
    
    private var privateDatabase: CKDatabase? {
        guard let container = container else { return nil }
        return container.privateCloudDatabase
    }
    
    // Record type constants
    private let billRecordType = "Bill"
    private let savingRecordType = "Saving"
    private let userSettingsRecordType = "UserSettings"
    
    // Published properties for UI updates
    @Published var isCloudKitAvailable = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isSyncing = false
    
    // Private properties for sync control
    private var syncTimer: Timer?
    private var lastSyncAttempt: Date?
    
    // Check if current user is a guest
    private var isGuestUser: Bool {
        // Check if the current user ID starts with "guest_"
        // This is a simple way to identify guest users
        return false // We'll set this based on the current user
    }
    
    // Method to update guest status based on current user
    func updateGuestStatus(userId: String?) {
        let isGuest = userId?.hasPrefix("guest_") ?? false
        if isGuest {
            print("ℹ️ Guest user detected - disabling CloudKit operations")
            DispatchQueue.main.async {
                self.isCloudKitAvailable = false
                self.syncError = nil
            }
        } else {
            print("ℹ️ Authenticated user detected - enabling CloudKit operations")
            // Re-enable CloudKit checks for authenticated users
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkCloudKitAvailability()
            }
        }
    }
    
    private init() {
        // Initialize without immediately checking CloudKit to prevent crashes
        print("🔧 CloudKitManager initialized")
        
        // For guest users, don't attempt CloudKit operations
        if isGuestUser {
            print("ℹ️ Guest user detected - skipping CloudKit initialization")
            return
        }
        
        // Delay the CloudKit availability check to prevent startup crashes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkCloudKitAvailability()
        }
        
        // Add immediate availability check for debugging (iPad optimized)
        #if os(iOS)
        DispatchQueue.global(qos: .utility).async {
            print("🔍 Checking CloudKit availability immediately...")
            self.checkCloudKitAvailability()
        }
        #else
        print("🔍 Checking CloudKit availability immediately...")
        checkCloudKitAvailability()
        #endif
        
        // Setup automatic sync timer
        setupAutomaticSync()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Automatic Sync Setup
    
    /// Setup automatic sync timer for periodic syncing
    private func setupAutomaticSync() {
        // Sync every 5 minutes when app is active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.triggerAutomaticSync()
        }
        
        print("⏰ Automatic sync timer set up (every 5 minutes)")
    }
    
    /// Trigger automatic sync if conditions are met
    private func triggerAutomaticSync() {
        // Only auto-sync if CloudKit is available and we haven't synced recently
        guard isCloudKitAvailable else {
            print("⏰ Auto-sync skipped - CloudKit not available")
            return
        }
        
        // Prevent too frequent sync attempts
        if let lastAttempt = lastSyncAttempt,
           Date().timeIntervalSince(lastAttempt) < 60 { // Minimum 1 minute between attempts
            print("⏰ Auto-sync skipped - too recent")
            return
        }
        
        print("⏰ Triggering automatic sync...")
        lastSyncAttempt = Date()
        
        // Notify that we want to sync (views will handle the actual sync)
        NotificationCenter.default.post(name: .cloudKitSyncRequested, object: nil)
    }
    
    /// Request immediate sync (called from views or other parts of the app)
    func requestSync() {
        guard isCloudKitAvailable else {
            print("⚠️ Sync requested but CloudKit not available")
            return
        }
        
        print("🔄 Manual sync requested...")
        print("🌐 Network: \(NetworkMonitor.shared.isConnected ? "Connected" : "Disconnected")")
        
        NotificationCenter.default.post(name: .cloudKitSyncRequested, object: nil)
    }
    
    // MARK: - CloudKit Availability Check
    
    /// Check if CloudKit is available and user is signed in
    func checkCloudKitAvailability() {
        // Skip CloudKit checks for guest users
        if isGuestUser {
            print("ℹ️ Skipping CloudKit check for guest user")
            return
        }
        
        guard let container = container else {
            DispatchQueue.main.async {
                self.isCloudKitAvailable = false
                self.syncError = "CloudKit container not available"
            }
            return
        }
        
        // Safely check CloudKit availability with timeout
        let timeoutTask = DispatchWorkItem {
            DispatchQueue.main.async {
                if !self.isCloudKitAvailable {
                    print("⚠️ CloudKit availability check timed out")
                    self.syncError = "iCloud connection timed out. Please check your internet connection."
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: timeoutTask)
        
        container.accountStatus { [weak self] accountStatus, error in
            // Cancel timeout if we get a response
            timeoutTask.cancel()
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit error: \(error.localizedDescription)")
                    self?.isCloudKitAvailable = false
                    self?.syncError = "iCloud connection error. Please check your internet connection."
                    return
                }
                
                switch accountStatus {
                case .available:
                    self?.isCloudKitAvailable = true
                    self?.syncError = nil
                    print("✅ CloudKit is available and user is signed in")
                case .noAccount:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "iCloud account not found. Please sign in to iCloud in Settings."
                    print("⚠️ No iCloud account found")
                case .restricted:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "iCloud access is restricted"
                    print("⚠️ iCloud access is restricted")
                case .couldNotDetermine:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "Could not determine iCloud status"
                    print("⚠️ Could not determine iCloud status")
                case .temporarilyUnavailable:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "iCloud temporarily unavailable"
                    print("⚠️ iCloud temporarily unavailable")
                @unknown default:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "Unknown iCloud status"
                    print("⚠️ Unknown iCloud status")
                }
            }
        }
    }
    
    // MARK: - Bill Operations
    
    /// Save a bill to CloudKit
    /// - Parameters:
    ///   - bill: The BillItem to save
    ///   - completion: Completion handler with success/failure result
    func saveBillToCloudKit(_ bill: BillItem, completion: @escaping (Bool, Error?) -> Void) {
        print("🔄 Attempting to save bill to CloudKit: \(bill.title)")
        print("🔍 CloudKit available: \(isCloudKitAvailable)")
        print("🔍 Database available: \(privateDatabase != nil)")
        
        guard isCloudKitAvailable, let _ = privateDatabase else {
            print("❌ CloudKit not available for bill save")
            completion(false, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"]))
            return
        }
        
        // Create CKRecord for the bill
        let record = CKRecord(recordType: billRecordType)
        record["name"] = bill.title
        record["amount"] = bill.amount
        record["dueDate"] = bill.dueDate
        record["isPaid"] = bill.isPaid
        record["notes"] = bill.notes
        record["category"] = bill.category
        record["isRecurring"] = bill.isRecurring
        record["recurrenceType"] = bill.recurrenceType
        record["endDate"] = bill.endDate
        record["createdAt"] = bill.createdAt
        record["updatedAt"] = bill.updatedAt
        
        // Save to CloudKit
        privateDatabase?.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to save bill to CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(false, error)
                } else {
                    print("✅ Bill saved to CloudKit successfully")
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Fetch all bills from CloudKit
    /// - Parameter completion: Completion handler with bills array or error
    func fetchBillsFromCloudKit(completion: @escaping ([BillItem]?, Error?) -> Void) {
        guard isCloudKitAvailable, let _ = privateDatabase else {
            completion(nil, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"]))
            return
        }
        
        // Create query for all bills
        let query = CKQuery(recordType: billRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        
        // Use the newer fetch method instead of deprecated perform
        let queryOperation = CKQueryOperation(query: query)
        var fetchedRecords: [CKRecord] = []
        
        queryOperation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
            case .failure(let error):
                print("❌ Failed to fetch record: \(error.localizedDescription)")
            }
        }
        
        queryOperation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Convert CKRecords to BillItems
                    let bills = fetchedRecords.compactMap { record -> BillItem? in
                        guard let name = record["name"] as? String,
                              let amount = record["amount"] as? Double,
                              let dueDate = record["dueDate"] as? Date else {
                            return nil
                        }
                        
                        let bill = BillItem(
                            title: name,
                            amount: amount,
                            dueDate: dueDate,
                            isPaid: record["isPaid"] as? Bool ?? false,
                            notes: record["notes"] as? String ?? "",
                            category: record["category"] as? String ?? "General",
                            isRecurring: record["isRecurring"] as? Bool ?? false,
                            recurrenceType: record["recurrenceType"] as? String,
                            endDate: record["endDate"] as? Date
                        )
                        
                        // Set timestamps if available
                        if let createdAt = record["createdAt"] as? Date {
                            bill.createdAt = createdAt
                        }
                        if let updatedAt = record["updatedAt"] as? Date {
                            bill.updatedAt = updatedAt
                        }
                        
                        return bill
                    }
                    
                    print("✅ Fetched \(bills.count) bills from CloudKit")
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                    completion(bills, nil)
                    
                case .failure(let error):
                    print("❌ Failed to fetch bills from CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(nil, error)
                }
            }
        }
        
        privateDatabase?.add(queryOperation)
    }
    
    // MARK: - Savings Operations
    
    /// Save a savings goal to CloudKit
    /// - Parameters:
    ///   - saving: The SavingsGoal to save
    ///   - completion: Completion handler with success/failure result
    func saveSavingToCloudKit(_ saving: SavingsGoal, completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudKitAvailable, let database = privateDatabase else {
            completion(false, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"]))
            return
        }
        
        // Create CKRecord for the savings goal
        let record = CKRecord(recordType: savingRecordType)
        record["goalName"] = saving.title
        record["targetAmount"] = saving.targetAmount
        record["currentAmount"] = saving.currentAmount
        record["category"] = saving.category
        record["goalType"] = saving.goalType
        record["targetDate"] = saving.targetDate
        record["notes"] = saving.notes
        record["createdAt"] = saving.createdAt
        record["updatedAt"] = saving.updatedAt
        
        // Save to CloudKit
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to save savings goal to CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(false, error)
                } else {
                    print("✅ Savings goal saved to CloudKit successfully")
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - UserSettings Operations
    
    /// Save user settings to CloudKit
    /// - Parameters:
    ///   - settings: The UserSettings to save
    ///   - completion: Completion handler with success/failure result
    func saveUserSettingsToCloudKit(_ settings: UserSettings, completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudKitAvailable, let database = privateDatabase else {
            completion(false, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"]))
            return
        }
        
        // Create CKRecord for user settings
        let record = CKRecord(recordType: userSettingsRecordType)
        record["monthlyBudget"] = settings.monthlyBudget
        record["monthlyIncome"] = settings.monthlyIncome
        record["notificationsEnabled"] = settings.notificationsEnabled
        record["darkModeEnabled"] = settings.darkModeEnabled
        record["createdAt"] = settings.createdAt
        record["updatedAt"] = settings.updatedAt
        
        // Save to CloudKit
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to save user settings to CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(false, error)
                } else {
                    print("✅ User settings saved to CloudKit successfully")
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Fetch user settings from CloudKit
    /// - Parameter completion: Completion handler with settings or error
    func fetchUserSettingsFromCloudKit(completion: @escaping (UserSettings?, Error?) -> Void) {
        guard isCloudKitAvailable, let database = privateDatabase else {
            completion(nil, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"]))
            return
        }
        
        // Create query for user settings
        let query = CKQuery(recordType: userSettingsRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        // Use the newer fetch method
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 1 // Only get the most recent settings
        var fetchedRecords: [CKRecord] = []
        
        queryOperation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
            case .failure(let error):
                print("❌ Failed to fetch user settings record: \(error.localizedDescription)")
            }
        }
        
        queryOperation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Get the first record from fetchedRecords
                    if let record = fetchedRecords.first {
                        // Convert CKRecord to UserSettings
                        let settings = UserSettings(
                            monthlyBudget: record["monthlyBudget"] as? Double ?? 2000.0,
                            monthlyIncome: record["monthlyIncome"] as? Double ?? 5000.0,
                            notificationsEnabled: record["notificationsEnabled"] as? Bool ?? true,
                            darkModeEnabled: record["darkModeEnabled"] as? Bool ?? false
                        )
                        
                        // Set timestamps if available
                        if let createdAt = record["createdAt"] as? Date {
                            settings.createdAt = createdAt
                        }
                        if let updatedAt = record["updatedAt"] as? Date {
                            settings.updatedAt = updatedAt
                        }
                        
                        print("✅ Fetched user settings from CloudKit")
                        self?.lastSyncDate = Date()
                        self?.syncError = nil
                        completion(settings, nil)
                        
                    } else {
                        print("ℹ️ No user settings found in CloudKit")
                        completion(nil, nil)
                    }
                    
                case .failure(let error):
                    print("❌ Failed to fetch user settings from CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(nil, error)
                }
            }
        }
        
        database.add(queryOperation)
    }
    
    /// Fetch all savings goals from CloudKit
    /// - Parameter completion: Completion handler with savings array or error
    func fetchSavingsFromCloudKit(completion: @escaping ([SavingsGoal]?, Error?) -> Void) {
        guard isCloudKitAvailable, let database = privateDatabase else {
            completion(nil, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"]))
            return
        }
        
        // Create query for all savings goals
        let query = CKQuery(recordType: savingRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "targetDate", ascending: true)]
        
        // Use the newer fetch method instead of deprecated perform
        let queryOperation = CKQueryOperation(query: query)
        var fetchedRecords: [CKRecord] = []
        
        queryOperation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                fetchedRecords.append(record)
            case .failure(let error):
                print("❌ Failed to fetch record: \(error.localizedDescription)")
            }
        }
        
        queryOperation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Convert CKRecords to SavingsGoals
                    let savings = fetchedRecords.compactMap { record -> SavingsGoal? in
                        guard let goalName = record["goalName"] as? String,
                              let targetAmount = record["targetAmount"] as? Double,
                              let currentAmount = record["currentAmount"] as? Double,
                              let targetDate = record["targetDate"] as? Date else {
                            return nil
                        }
                        
                        let saving = SavingsGoal(
                            title: goalName,
                            category: record["category"] as? String ?? "Savings",
                            goalType: record["goalType"] as? String ?? "Savings",
                            targetAmount: targetAmount,
                            currentAmount: currentAmount,
                            targetDate: targetDate,
                            notes: record["notes"] as? String ?? ""
                        )
                        
                        // Set timestamps if available
                        if let createdAt = record["createdAt"] as? Date {
                            saving.createdAt = createdAt
                        }
                        if let updatedAt = record["updatedAt"] as? Date {
                            saving.updatedAt = updatedAt
                        }
                        
                        return saving
                    }
                    
                    print("✅ Fetched \(savings.count) savings goals from CloudKit")
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                    completion(savings, nil)
                    
                case .failure(let error):
                    print("❌ Failed to fetch savings goals from CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(nil, error)
                }
            }
        }
        
        database.add(queryOperation)
    }
    
    // MARK: - Sync Operations
    
    /// Sync all local data to CloudKit
    /// - Parameters:
    ///   - bills: Array of local bills to sync
    ///   - savings: Array of local savings goals to sync
    ///   - userSettings: User settings to sync
    ///   - completion: Completion handler with sync result
    func syncAllDataToCloudKit(bills: [BillItem], savings: [SavingsGoal], userSettings: UserSettings?, completion: @escaping (Bool, Error?) -> Void) {
        // Check if CloudKit is available
        guard isCloudKitAvailable, let _ = privateDatabase else {
            print("⚠️ CloudKit not available for sync")
            completion(false, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"]))
            return
        }
        
        // Prevent recursive sync calls
        guard !isSyncing else {
            print("⚠️ Sync already in progress, skipping")
            completion(false, NSError(domain: "CloudKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Sync already in progress"]))
            return
        }
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        print("🔄 Starting CloudKit sync for \(bills.count) bills and \(savings.count) savings goals")
        
        let group = DispatchGroup()
        var syncErrors: [Error] = []
        var billsSynced = 0
        var savingsSynced = 0
        
        // Sync bills (iPad optimized with background queue)
        #if os(iOS)
        let syncQueue = DispatchQueue.global(qos: .utility)
        #else
        let syncQueue = DispatchQueue.main
        #endif
        
        for bill in bills {
            group.enter()
            let billTitle = bill.title
            let billAmount = bill.amount
            let billDueDate = bill.dueDate
            let billIsPaid = bill.isPaid
            let billNotes = bill.notes
            let billCategory = bill.category
            let billIsRecurring = bill.isRecurring
            let billRecurrenceType = bill.recurrenceType
            let billEndDate = bill.endDate
            let billCreatedAt = bill.createdAt
            let billUpdatedAt = bill.updatedAt
            
            syncQueue.async {
                // Create a temporary bill object for syncing
                let tempBill = BillItem(
                    title: billTitle,
                    amount: billAmount,
                    dueDate: billDueDate,
                    isPaid: billIsPaid,
                    notes: billNotes,
                    category: billCategory,
                    isRecurring: billIsRecurring,
                    recurrenceType: billRecurrenceType,
                    endDate: billEndDate
                )
                tempBill.createdAt = billCreatedAt
                tempBill.updatedAt = billUpdatedAt
                
                self.saveBillToCloudKit(tempBill) { success, error in
                    if success {
                        billsSynced += 1
                        print("✅ Synced bill: \(billTitle)")
                    } else if let error = error {
                        syncErrors.append(error)
                        print("❌ Failed to sync bill \(billTitle): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        // Sync savings goals (iPad optimized with background queue)
        for saving in savings {
            group.enter()
            let savingTitle = saving.title
            let savingCategory = saving.category
            let savingGoalType = saving.goalType
            let savingTargetAmount = saving.targetAmount
            let savingCurrentAmount = saving.currentAmount
            let savingTargetDate = saving.targetDate
            let savingNotes = saving.notes
            let savingCreatedAt = saving.createdAt
            let savingUpdatedAt = saving.updatedAt
            
            syncQueue.async {
                // Create a temporary savings goal object for syncing
                let tempSaving = SavingsGoal(
                    title: savingTitle,
                    category: savingCategory,
                    goalType: savingGoalType,
                    targetAmount: savingTargetAmount,
                    currentAmount: savingCurrentAmount,
                    targetDate: savingTargetDate,
                    notes: savingNotes
                )
                tempSaving.createdAt = savingCreatedAt
                tempSaving.updatedAt = savingUpdatedAt
                
                self.saveSavingToCloudKit(tempSaving) { success, error in
                    if success {
                        savingsSynced += 1
                        print("✅ Synced savings goal: \(savingTitle)")
                    } else if let error = error {
                        syncErrors.append(error)
                        print("❌ Failed to sync savings goal \(savingTitle): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        // Sync user settings if provided
        if let userSettings = userSettings {
            group.enter()
            syncQueue.async {
                self.saveUserSettingsToCloudKit(userSettings) { success, error in
                    if success {
                        print("✅ Synced user settings to CloudKit")
                    } else if let error = error {
                        syncErrors.append(error)
                        print("❌ Failed to sync user settings: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isSyncing = false
            
            if syncErrors.isEmpty {
                print("✅ CloudKit sync completed successfully: \(billsSynced) bills, \(savingsSynced) savings goals")
                self?.lastSyncDate = Date()
                self?.syncError = nil
                completion(true, nil)
            } else {
                let errorMessage = "Sync completed with \(syncErrors.count) errors"
                print("⚠️ \(errorMessage)")
                self?.syncError = errorMessage
                completion(false, NSError(domain: "CloudKit", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        }
    }
    
    /// Perform full bidirectional sync (upload local + download remote)
    /// - Parameters:
    ///   - bills: Array of local bills
    ///   - savings: Array of local savings goals
    ///   - userSettings: User settings to sync
    ///   - modelContext: SwiftData model context
    ///   - completion: Completion handler with sync result
    func performFullSync(bills: [BillItem], savings: [SavingsGoal], userSettings: UserSettings?, modelContext: ModelContext, completion: @escaping (Bool, Error?) -> Void) {
        print("🔄 Starting full bidirectional sync...")
        print("📊 Local bills count: \(bills.count)")
        print("🎯 Local savings count: \(savings.count)")
        print("🌐 Network: \(NetworkMonitor.shared.isConnected ? "Connected" : "Disconnected")")
        
        // First, upload local data to CloudKit
        syncAllDataToCloudKit(bills: bills, savings: savings, userSettings: userSettings) { [weak self] uploadSuccess, uploadError in
            if uploadSuccess {
                print("✅ Local data uploaded successfully, now downloading remote data...")
                
                // Then, download and merge remote data
                self?.fetchAndMergeRemoteData(modelContext: modelContext) { mergeSuccess, mergeError in
                    if mergeSuccess {
                        print("✅ Full sync completed successfully")
                        completion(true, nil)
                    } else {
                        print("⚠️ Upload successful but merge failed: \(mergeError?.localizedDescription ?? "Unknown error")")
                        completion(false, mergeError)
                    }
                }
            } else {
                print("❌ Upload failed: \(uploadError?.localizedDescription ?? "Unknown error")")
                completion(false, uploadError)
            }
        }
    }
    
    /// Fetch and merge remote data from CloudKit
    /// - Parameters:
    ///   - modelContext: SwiftData context for merging
    ///   - completion: Completion handler with merge result
    private func fetchAndMergeRemoteData(modelContext: ModelContext, completion: @escaping (Bool, Error?) -> Void) {
        print("📥 Fetching remote data from CloudKit...")
        
        let group = DispatchGroup()
        var mergeErrors: [Error] = []
        
        // Fetch bills
        group.enter()
        fetchBillsFromCloudKit { remoteBills, error in
            if let error = error {
                mergeErrors.append(error)
                print("❌ Failed to fetch remote bills: \(error.localizedDescription)")
            } else if let remoteBills = remoteBills {
                print("📥 Fetched \(remoteBills.count) remote bills")
                // TODO: Implement merge logic for bills
            }
            group.leave()
        }
        
        // Fetch savings
        group.enter()
        fetchSavingsFromCloudKit { remoteSavings, error in
            if let error = error {
                mergeErrors.append(error)
                print("❌ Failed to fetch remote savings: \(error.localizedDescription)")
            } else if let remoteSavings = remoteSavings {
                print("📥 Fetched \(remoteSavings.count) remote savings goals")
                // TODO: Implement merge logic for savings
            }
            group.leave()
        }
        
        // Fetch user settings
        group.enter()
        fetchUserSettingsFromCloudKit { remoteUserSettings, error in
            if let error = error {
                mergeErrors.append(error)
                print("❌ Failed to fetch remote user settings: \(error.localizedDescription)")
            } else if let remoteUserSettings = remoteUserSettings {
                print("📥 Fetched remote user settings: Income $\(remoteUserSettings.monthlyIncome), Budget $\(remoteUserSettings.monthlyBudget)")
                // Merge user settings
                self.mergeUserSettings(remoteUserSettings, modelContext: modelContext)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if mergeErrors.isEmpty {
                print("✅ Remote data fetched successfully")
                completion(true, nil)
            } else {
                let errorMessage = "Failed to fetch remote data: \(mergeErrors.count) errors"
                print("❌ \(errorMessage)")
                completion(false, NSError(domain: "CloudKit", code: 4, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        }
    }
    
    /// Fetch all data from CloudKit and return as tuple
    /// - Parameter completion: Completion handler with bills and savings arrays
    func fetchAllDataFromCloudKit(completion: @escaping (([BillItem]?, [SavingsGoal]?, Error?) -> Void)) {
        let group = DispatchGroup()
        var fetchedBills: [BillItem]?
        var fetchedSavings: [SavingsGoal]?
        var fetchError: Error?
        
        group.enter()
        fetchBillsFromCloudKit { bills, error in
            fetchedBills = bills
            if let error = error {
                fetchError = error
            }
            group.leave()
        }
        
        group.enter()
        fetchSavingsFromCloudKit { savings, error in
            fetchedSavings = savings
            if let error = error {
                fetchError = error
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(fetchedBills, fetchedSavings, fetchError)
        }
    }
    
    // MARK: - Merge Operations
    
    /// Merge user settings from CloudKit with local settings
    /// - Parameters:
    ///   - remoteSettings: UserSettings from CloudKit
    ///   - modelContext: SwiftData model context
    private func mergeUserSettings(_ remoteSettings: UserSettings, modelContext: ModelContext) {
        print("🔄 Merging user settings...")
        
        do {
            // Fetch local user settings
            let localSettings = try modelContext.fetch(FetchDescriptor<UserSettings>())
            
            if let localSetting = localSettings.first {
                // Update local settings with remote values if remote is newer
                if remoteSettings.updatedAt > localSetting.updatedAt {
                    print("📥 Updating local user settings with remote values")
                    localSetting.monthlyIncome = remoteSettings.monthlyIncome
                    localSetting.monthlyBudget = remoteSettings.monthlyBudget
                    localSetting.notificationsEnabled = remoteSettings.notificationsEnabled
                    localSetting.darkModeEnabled = remoteSettings.darkModeEnabled
                    localSetting.updatedAt = Date()
                    
                    try modelContext.save()
                    print("✅ User settings merged successfully")
                    
                    // Post notification to update UI
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
                    }
                } else {
                    print("ℹ️ Local user settings are up to date")
                }
            } else {
                // No local settings exist, create new ones
                print("📥 Creating new local user settings from CloudKit")
                let newSettings = UserSettings(
                    monthlyBudget: remoteSettings.monthlyBudget,
                    monthlyIncome: remoteSettings.monthlyIncome,
                    notificationsEnabled: remoteSettings.notificationsEnabled,
                    darkModeEnabled: remoteSettings.darkModeEnabled
                )
                newSettings.createdAt = remoteSettings.createdAt
                newSettings.updatedAt = remoteSettings.updatedAt
                
                modelContext.insert(newSettings)
                try modelContext.save()
                print("✅ New user settings created from CloudKit")
                
                // Post notification to update UI
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
                }
            }
        } catch {
            print("❌ Failed to merge user settings: \(error.localizedDescription)")
        }
    }
    
    /// Merge fetched CloudKit data with local SwiftData
    /// - Parameters:
    ///   - fetchedBills: Bills from CloudKit
    ///   - fetchedSavings: Savings goals from CloudKit
    ///   - localBills: Current local bills
    ///   - localSavings: Current local savings goals
    ///   - modelContext: SwiftData model context
    ///   - completion: Completion handler with merge result
    func mergeCloudKitData(
        fetchedBills: [BillItem]?,
        fetchedSavings: [SavingsGoal]?,
        localBills: [BillItem],
        localSavings: [SavingsGoal],
        modelContext: ModelContext,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        print("🔄 Starting CloudKit data merge...")
        
        var mergeErrors: [Error] = []
        var billsMerged = 0
        var savingsMerged = 0
        
        // Merge bills
        if let fetchedBills = fetchedBills {
            let (mergedBills, billErrors) = mergeBills(fetched: fetchedBills, local: localBills, modelContext: modelContext)
            billsMerged = mergedBills
            mergeErrors.append(contentsOf: billErrors)
        }
        
        // Merge savings goals
        if let fetchedSavings = fetchedSavings {
            let (mergedSavings, savingErrors) = mergeSavings(fetched: fetchedSavings, local: localSavings, modelContext: modelContext)
            savingsMerged = mergedSavings
            mergeErrors.append(contentsOf: savingErrors)
        }
        
        // Clean up any existing duplicates before saving
        cleanupDuplicates(bills: localBills, savings: localSavings, modelContext: modelContext)
        
        // Save changes to SwiftData
        do {
            try modelContext.save()
            print("✅ CloudKit merge completed: \(billsMerged) bills, \(savingsMerged) savings goals merged")
            completion(true, nil)
        } catch {
            print("❌ Failed to save merged data: \(error.localizedDescription)")
            completion(false, error)
        }
    }
    
    /// Merge bills from CloudKit with local bills
    /// - Parameters:
    ///   - fetched: Bills from CloudKit
    ///   - local: Current local bills
    ///   - modelContext: SwiftData model context
    /// - Returns: Tuple of (merged count, errors)
    private func mergeBills(fetched: [BillItem], local: [BillItem], modelContext: ModelContext) -> (Int, [Error]) {
        var mergedCount = 0
        let errors: [Error] = []
        
        print("🔄 Merging bills: \(fetched.count) from CloudKit, \(local.count) local")
        
        for fetchedBill in fetched {
            // Try to find matching local bill by title and due date
            let matchingLocal = local.first { localBill in
                localBill.title == fetchedBill.title &&
                Calendar.current.isDate(localBill.dueDate, inSameDayAs: fetchedBill.dueDate)
            }
            
            if let localBill = matchingLocal {
                // Update existing local bill if CloudKit version is newer
                if fetchedBill.updatedAt > localBill.updatedAt {
                    updateLocalBill(localBill, with: fetchedBill)
                    mergedCount += 1
                    print("✅ Updated local bill: \(fetchedBill.title)")
                } else {
                    print("ℹ️ Skipped bill (local is newer): \(fetchedBill.title)")
                }
            } else {
                // Check if we already have this bill in the database to prevent duplicates
                let existingBill = local.first { localBill in
                    localBill.title == fetchedBill.title &&
                    abs(localBill.dueDate.timeIntervalSince(fetchedBill.dueDate)) < 60 // Within 1 minute
                }
                
                if existingBill == nil {
                    // Add new bill from CloudKit
                    modelContext.insert(fetchedBill)
                    mergedCount += 1
                    print("✅ Added new bill from CloudKit: \(fetchedBill.title)")
                } else {
                    print("ℹ️ Skipped duplicate bill: \(fetchedBill.title)")
                }
            }
        }
        
        return (mergedCount, errors)
    }
    
    /// Merge savings goals from CloudKit with local savings goals
    /// - Parameters:
    ///   - fetched: Savings goals from CloudKit
    ///   - local: Current local savings goals
    ///   - modelContext: SwiftData model context
    /// - Returns: Tuple of (merged count, errors)
    private func mergeSavings(fetched: [SavingsGoal], local: [SavingsGoal], modelContext: ModelContext) -> (Int, [Error]) {
        var mergedCount = 0
        let errors: [Error] = []
        
        print("🔄 Merging savings: \(fetched.count) from CloudKit, \(local.count) local")
        
        for fetchedSaving in fetched {
            // Try to find matching local savings goal by title and target date
            let matchingLocal = local.first { localSaving in
                localSaving.title == fetchedSaving.title &&
                Calendar.current.isDate(localSaving.targetDate, inSameDayAs: fetchedSaving.targetDate)
            }
            
            if let localSaving = matchingLocal {
                // Update existing local savings goal if CloudKit version is newer
                if fetchedSaving.updatedAt > localSaving.updatedAt {
                    updateLocalSavingsGoal(localSaving, with: fetchedSaving)
                    mergedCount += 1
                    print("✅ Updated local savings goal: \(fetchedSaving.title)")
                } else {
                    print("ℹ️ Skipped savings goal (local is newer): \(fetchedSaving.title)")
                }
            } else {
                // Check if we already have this savings goal in the database to prevent duplicates
                let existingSaving = local.first { localSaving in
                    localSaving.title == fetchedSaving.title &&
                    abs(localSaving.targetDate.timeIntervalSince(fetchedSaving.targetDate)) < 86400 // Within 1 day
                }
                
                if existingSaving == nil {
                    // Add new savings goal from CloudKit
                    modelContext.insert(fetchedSaving)
                    mergedCount += 1
                    print("✅ Added new savings goal from CloudKit: \(fetchedSaving.title)")
                } else {
                    print("ℹ️ Skipped duplicate savings goal: \(fetchedSaving.title)")
                }
            }
        }
        
        return (mergedCount, errors)
    }
    
    /// Update local bill with data from CloudKit
    /// - Parameters:
    ///   - localBill: Local bill to update
    ///   - cloudBill: Bill data from CloudKit
    private func updateLocalBill(_ localBill: BillItem, with cloudBill: BillItem) {
        localBill.title = cloudBill.title
        localBill.amount = cloudBill.amount
        localBill.dueDate = cloudBill.dueDate
        localBill.isPaid = cloudBill.isPaid
        localBill.notes = cloudBill.notes
        localBill.category = cloudBill.category
        localBill.isRecurring = cloudBill.isRecurring
        localBill.recurrenceType = cloudBill.recurrenceType
        localBill.endDate = cloudBill.endDate
        localBill.updatedAt = cloudBill.updatedAt
    }
    
    /// Update local savings goal with data from CloudKit
    /// - Parameters:
    ///   - localSaving: Local savings goal to update
    ///   - cloudSaving: Savings goal data from CloudKit
    private func updateLocalSavingsGoal(_ localSaving: SavingsGoal, with cloudSaving: SavingsGoal) {
        localSaving.title = cloudSaving.title
        localSaving.category = cloudSaving.category
        localSaving.goalType = cloudSaving.goalType
        localSaving.targetAmount = cloudSaving.targetAmount
        localSaving.currentAmount = cloudSaving.currentAmount
        localSaving.targetDate = cloudSaving.targetDate
        localSaving.notes = cloudSaving.notes
        localSaving.updatedAt = cloudSaving.updatedAt
    }
    
    /// Clean up duplicate bills and savings goals
    /// - Parameters:
    ///   - bills: Array of local bills
    ///   - savings: Array of local savings goals
    ///   - modelContext: SwiftData model context
    func cleanupDuplicates(bills: [BillItem], savings: [SavingsGoal], modelContext: ModelContext) {
        print("🧹 Starting enhanced duplicate cleanup...")
        
        let originalBillCount = bills.count
        let originalSavingsCount = savings.count
        
        // Enhanced bill duplicate detection and cleanup
        let billsCleaned = cleanupDuplicateBills(bills: bills, modelContext: modelContext)
        
        // Enhanced savings duplicate detection and cleanup
        let savingsCleaned = cleanupDuplicateSavings(savings: savings, modelContext: modelContext)
        
        // Save all changes
        do {
            try modelContext.save()
            let finalBillCount = bills.count
            let finalSavingsCount = savings.count
            
            print("✅ Enhanced duplicate cleanup completed:")
            print("   📊 Bills: \(originalBillCount) → \(finalBillCount) (cleaned: \(billsCleaned))")
            print("   🎯 Savings: \(originalSavingsCount) → \(finalSavingsCount) (cleaned: \(savingsCleaned))")
            print("   🧹 Total duplicates removed: \(billsCleaned + savingsCleaned)")
            
        } catch {
            print("❌ Failed to save after cleanup: \(error.localizedDescription)")
        }
    }
    
    /// Enhanced duplicate bill cleanup with intelligent merging
    /// - Parameters:
    ///   - bills: Array of local bills
    ///   - modelContext: SwiftData model context
    /// - Returns: Number of duplicates cleaned
    private func cleanupDuplicateBills(bills: [BillItem], modelContext: ModelContext) -> Int {
        print("🔍 Analyzing bills for duplicates...")
        
        var duplicatesRemoved = 0
        
        // Create more intelligent grouping - normalize bill names for better matching
        let groupedBills = Dictionary(grouping: bills) { bill in
            let normalizedName = bill.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedDate = Calendar.current.startOfDay(for: bill.dueDate)
            return "\(normalizedName)_\(normalizedDate)"
        }
        
        for (groupKey, duplicateBills) in groupedBills {
            if duplicateBills.count > 1 {
                print("🔍 Found \(duplicateBills.count) potential duplicates for: \(groupKey)")
                
                // Sort by most recent update and data quality
                let sortedBills = duplicateBills.sorted { bill1, bill2 in
                    // Primary sort: most recent update
                    if bill1.updatedAt != bill2.updatedAt {
                        return bill1.updatedAt > bill2.updatedAt
                    }
                    
                    // Secondary sort: most complete data (more notes, better category)
                    let bill1Score = calculateBillQualityScore(bill1)
                    let bill2Score = calculateBillQualityScore(bill2)
                    return bill1Score > bill2Score
                }
                
                let bestBill = sortedBills.first!
                let duplicateBillsToDelete = Array(sortedBills.dropFirst())
                
                print("✅ Keeping best bill: '\(bestBill.title)' (updated: \(bestBill.updatedAt), score: \(calculateBillQualityScore(bestBill)))")
                
                // Delete duplicates
                for duplicateBill in duplicateBillsToDelete {
                    print("🗑️ Deleting duplicate: '\(duplicateBill.title)' (updated: \(duplicateBill.updatedAt), score: \(calculateBillQualityScore(duplicateBill)))")
                    modelContext.delete(duplicateBill)
                    duplicatesRemoved += 1
                }
            }
        }
        
        return duplicatesRemoved
    }
    
    /// Enhanced duplicate savings cleanup with intelligent merging
    /// - Parameters:
    ///   - savings: Array of local savings goals
    ///   - modelContext: SwiftData model context
    /// - Returns: Number of duplicates cleaned
    private func cleanupDuplicateSavings(savings: [SavingsGoal], modelContext: ModelContext) -> Int {
        print("🔍 Analyzing savings goals for duplicates...")
        
        var duplicatesRemoved = 0
        
        // Group by normalized name and target date
        let groupedSavings = Dictionary(grouping: savings) { saving in
            let normalizedName = saving.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedDate = Calendar.current.startOfDay(for: saving.targetDate)
            return "\(normalizedName)_\(normalizedDate)"
        }
        
        for (groupKey, duplicateSavings) in groupedSavings {
            if duplicateSavings.count > 1 {
                print("🔍 Found \(duplicateSavings.count) potential duplicates for: \(groupKey)")
                
                // Sort by most recent update and data quality
                let sortedSavings = duplicateSavings.sorted { saving1, saving2 in
                    // Primary sort: most recent update
                    if saving1.updatedAt != saving2.updatedAt {
                        return saving1.updatedAt > saving2.updatedAt
                    }
                    
                    // Secondary sort: most complete data
                    let saving1Score = calculateSavingsQualityScore(saving1)
                    let saving2Score = calculateSavingsQualityScore(saving2)
                    return saving1Score > saving2Score
                }
                
                let bestSaving = sortedSavings.first!
                let duplicateSavingsToDelete = Array(sortedSavings.dropFirst())
                
                print("✅ Keeping best savings goal: '\(bestSaving.title)' (updated: \(bestSaving.updatedAt), score: \(calculateSavingsQualityScore(bestSaving)))")
                
                // Delete duplicates
                for duplicateSaving in duplicateSavingsToDelete {
                    print("🗑️ Deleting duplicate: '\(duplicateSaving.title)' (updated: \(duplicateSaving.updatedAt), score: \(calculateSavingsQualityScore(duplicateSaving)))")
                    modelContext.delete(duplicateSaving)
                    duplicatesRemoved += 1
                }
            }
        }
        
        return duplicatesRemoved
    }
    
    /// Calculate quality score for a bill (higher = better)
    /// - Parameter bill: The bill to score
    /// - Returns: Quality score (0-100)
    private func calculateBillQualityScore(_ bill: BillItem) -> Int {
        var score = 0
        
        // Base score for having the bill
        score += 10
        
        // Bonus for complete information
        if !bill.notes.isEmpty { score += 5 }
        if bill.category != "General" { score += 3 }
        if bill.isRecurring { score += 2 }
        if bill.recurrenceType != nil { score += 2 }
        if bill.endDate != nil { score += 2 }
        
        // Bonus for recent activity
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: bill.updatedAt, to: Date()).day ?? 0
        if daysSinceUpdate <= 7 { score += 5 }
        else if daysSinceUpdate <= 30 { score += 3 }
        else if daysSinceUpdate <= 90 { score += 1 }
        
        return min(score, 100)
    }
    
    /// Calculate quality score for a savings goal (higher = better)
    /// - Parameter saving: The savings goal to score
    /// - Returns: Quality score (0-100)
    private func calculateSavingsQualityScore(_ saving: SavingsGoal) -> Int {
        var score = 0
        
        // Base score for having the savings goal
        score += 10
        
        // Bonus for complete information
        if !saving.notes.isEmpty { score += 5 }
        if saving.category != "Savings" { score += 3 }
        if saving.goalType != "Savings" { score += 2 }
        
        // Bonus for recent activity
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: saving.updatedAt, to: Date()).day ?? 0
        if daysSinceUpdate <= 7 { score += 5 }
        else if daysSinceUpdate <= 30 { score += 3 }
        else if daysSinceUpdate <= 90 { score += 1 }
        
        return min(score, 100)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Notification sent when CloudKit sync is requested
    static let cloudKitSyncRequested = Notification.Name("cloudKitSyncRequested")
    
    /// Notification sent when CloudKit data has changed
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
} 