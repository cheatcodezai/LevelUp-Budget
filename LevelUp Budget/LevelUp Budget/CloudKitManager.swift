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
    
    private init() {
        // Initialize without immediately checking CloudKit to prevent crashes
        print("🔧 CloudKitManager initialized")
        
        // Delay the CloudKit availability check to prevent startup crashes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkCloudKitAvailability()
        }
    }
    
    // MARK: - CloudKit Availability Check
    
    /// Check if CloudKit is available and user is signed in
    func checkCloudKitAvailability() {
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
        
        // Perform query using deprecated API
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to fetch bills from CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(nil, error)
                } else {
                    // Convert CKRecords to BillItems
                    let bills = records?.compactMap { record -> BillItem? in
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
                    } ?? []
                    
                    print("✅ Fetched \(bills.count) bills from CloudKit")
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                    completion(bills, nil)
                }
            }
        }
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
        
        // Perform query using deprecated API
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to fetch savings goals from CloudKit: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    completion(nil, error)
                } else {
                    // Convert CKRecords to SavingsGoals
                    let savings = records?.compactMap { record -> SavingsGoal? in
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
                    } ?? []
                    
                    print("✅ Fetched \(savings.count) savings goals from CloudKit")
                    self?.lastSyncDate = Date()
                    self?.syncError = nil
                    completion(savings, nil)
                }
            }
        }
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
} 