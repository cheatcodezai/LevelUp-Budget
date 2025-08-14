//
//  CloudKitManager.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import Foundation
import CloudKit
import SwiftData

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
    
    // Published properties for UI updates
    @Published var isCloudKitAvailable = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
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
        guard isCloudKitAvailable, let database = privateDatabase else {
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
        database.save(record) { [weak self] savedRecord, error in
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
        guard isCloudKitAvailable, let database = privateDatabase else {
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
        
        database.add(queryOperation)
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
    ///   - completion: Completion handler with sync result
    func syncAllDataToCloudKit(bills: [BillItem], savings: [SavingsGoal], completion: @escaping (Bool, Error?) -> Void) {
        // CloudKit is disabled for now to prevent crashes
        print("⚠️ CloudKit sync disabled - using local storage only")
        completion(false, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not configured"]))
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
    
    // MARK: - Duplicate Cleanup
    
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
    
    // MARK: - Full Sync Operations
    
    /// Perform full bidirectional sync (upload local + download remote)
    /// - Parameters:
    ///   - bills: Array of local bills
    ///   - savings: Array of local savings goals
    ///   - modelContext: SwiftData context for merging
    ///   - completion: Completion handler with sync result
    func performFullSync(bills: [BillItem], savings: [SavingsGoal], modelContext: ModelContext, completion: @escaping (Bool, Error?) -> Void) {
        print("🔄 Starting full bidirectional sync...")
        
        // First, upload local data to CloudKit
        syncAllDataToCloudKit(bills: bills, savings: savings) { [weak self] uploadSuccess, uploadError in
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
        fetchBillsFromCloudKit { [weak self] remoteBills, error in
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
        fetchSavingsFromCloudKit { [weak self] remoteSavings, error in
            if let error = error {
                mergeErrors.append(error)
                print("❌ Failed to fetch remote savings: \(error.localizedDescription)")
            } else if let remoteSavings = remoteSavings {
                print("📥 Fetched \(remoteSavings.count) remote savings goals")
                // TODO: Implement merge logic for savings
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
} 