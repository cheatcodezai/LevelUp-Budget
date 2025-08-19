//
//  NotificationManager.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import Foundation
import UserNotifications
import SwiftData
import Firebase

// MARK: - Notification Manager with Firebase Cloud Messaging Support
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // Published properties for UI updates
    @Published var isPushNotificationsEnabled = false
    @Published var apnsToken: String?
    @Published var notificationError: String?
    @Published var pendingNotificationsCount = 0
    
    private init() {
        setupPushNotifications()
        setupNotificationCategories()
    }
    
    // MARK: - Push Notification Setup
    
    /// Setup push notifications
    private func setupPushNotifications() {
        // Request permission for notifications
        requestPermission()
    }
    
    /// Setup notification categories and actions
    private func setupNotificationCategories() {
        // Bill reminder category with actions
        let markAsPaidAction = UNNotificationAction(
            identifier: "MARK_AS_PAID",
            title: "Mark as Paid",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind Later",
            options: [.foreground]
        )
        
        let billCategory = UNNotificationCategory(
            identifier: "BILL_REMINDER",
            actions: [markAsPaidAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Savings goal category
        let updateProgressAction = UNNotificationAction(
            identifier: "UPDATE_PROGRESS",
            title: "Update Progress",
            options: [.foreground]
        )
        
        let savingsCategory = UNNotificationCategory(
            identifier: "SAVINGS_GOAL",
            actions: [updateProgressAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([billCategory, savingsCategory])
        print("✅ Notification categories registered")
    }
    
    /// Request permission for push notifications
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isPushNotificationsEnabled = granted
                if granted {
                    print("✅ Push notification permission granted")
                    // Register for remote notifications
                    DispatchQueue.main.async {
                        #if os(iOS)
                        UIApplication.shared.registerForRemoteNotifications()
                        #elseif os(macOS)
                        NSApplication.shared.registerForRemoteNotifications()
                        #endif
                    }
                    
                    // Schedule notifications for existing bills
                    self?.scheduleNotificationsForAllBills()
                } else {
                    print("❌ Push notification permission denied")
                    if let error = error {
                        self?.notificationError = error.localizedDescription
                    }
                }
            }
        }
    }
    
    /// Get APNs token for device identification
    func getAPNsToken() {
        // APNs token is handled in AppDelegate
        print("📱 APNs token handling is done in AppDelegate")
    }
    
    /// Send APNs token to your server (placeholder implementation)
    /// - Parameter token: The APNs token to send
    private func sendTokenToServer(token: String) {
        // TODO: Implement server communication to store APNs token
        // This would typically involve sending the token to your backend
        // so you can send push notifications to this specific device
        print("📱 APNs token ready to send to server: \(token)")
    }
    
    // MARK: - Local Notification Methods (Existing Functionality)
    
    /// Schedule a bill reminder notification
    /// - Parameter bill: The BillItem to schedule a reminder for
    func scheduleBillReminder(for bill: BillItem) {
        guard !bill.isPaid else { return }
        
        // Cancel any existing notifications for this bill
        cancelNotification(for: bill)
        
        let calendar = Calendar.current
        let now = Date()
        let dueDate = bill.dueDate
        
        // Calculate days until due
        let daysUntilDue = calendar.dateComponents([.day], from: now, to: dueDate).day ?? 0
        
        // Schedule notification for 1 day before due date
        if daysUntilDue > 1 {
            let oneDayBefore = calendar.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
            
            let content = UNMutableNotificationContent()
            content.title = "Bill Due Tomorrow"
            content.body = "\(bill.title) - $\(bill.formattedAmount) is due tomorrow"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "BILL_REMINDER"
            content.userInfo = [
                "billId": bill.title,
                "billAmount": bill.amount,
                "billDueDate": bill.dueDate.timeIntervalSince1970
            ]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneDayBefore),
                repeats: false
            )
            
            // Create shorter, more reliable identifier
            let identifier = "bill-reminder-\(bill.title.hashValue)-\(bill.dueDate.timeIntervalSince1970)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling 1-day reminder: \(error)")
                } else {
                    print("✅ 1-day reminder scheduled for: \(bill.title) on \(oneDayBefore)")
                    self.updatePendingNotificationsCount()
                }
            }
        }
        
        // Schedule notification for the due date itself
        if daysUntilDue >= 0 {
            let content = UNMutableNotificationContent()
            content.title = "Bill Due Today"
            content.body = "\(bill.title) - $\(bill.formattedAmount) is due today!"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "BILL_REMINDER"
            content.userInfo = [
                "billId": bill.title,
                "billAmount": bill.amount,
                "billDueDate": bill.dueDate.timeIntervalSince1970
            ]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate),
                repeats: false
            )
            
            // Create shorter, more reliable identifier
            let identifier = "bill-due-\(bill.title.hashValue)-\(bill.dueDate.timeIntervalSince1970)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling due date notification: \(error)")
                } else {
                    print("✅ Due date notification scheduled for: \(bill.title) on \(dueDate)")
                    self.updatePendingNotificationsCount()
                }
            }
        }
    }
    
    /// Cancel notification for a specific bill
    /// - Parameter bill: The BillItem to cancel notifications for
    func cancelNotification(for bill: BillItem) {
        let identifiers = [
            "bill-reminder-\(bill.title.hashValue)-\(bill.dueDate.timeIntervalSince1970)",
            "bill-due-\(bill.title.hashValue)-\(bill.dueDate.timeIntervalSince1970)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled notifications for: \(bill.title)")
        updatePendingNotificationsCount()
    }
    
    /// Schedule reminders for all unpaid bills
    func scheduleAllBillReminders() {
        // This would be called when the app starts or when bills are updated
        // Implementation would iterate through all unpaid bills and schedule reminders
        print("📅 Scheduling reminders for all unpaid bills...")
    }
    
    /// Schedule notifications for all unpaid bills
    func scheduleNotificationsForAllBills() {
        print("📅 Scheduling notifications for all unpaid bills...")
        
        // This function will be called from the main app when bills are loaded
        // For now, we'll just log that it was called
        // The actual implementation will be called from views that have access to the model context
        
        // TODO: This would need access to the model context to fetch all bills
        // Implementation would look something like:
        // let descriptor = FetchDescriptor<BillItem>(predicate: #Predicate<BillItem> { bill in
        //     !bill.isPaid
        // })
        // let bills = try? modelContext.fetch(descriptor)
        // bills?.forEach { scheduleBillReminder(for: $0) }
    }
    
    /// Schedule notifications for all bills (called from views with model context)
    /// - Parameter bills: Array of bills to schedule notifications for
    func scheduleNotificationsForBills(_ bills: [BillItem]) {
        print("📅 Scheduling notifications for \(bills.count) bills...")
        
        let unpaidBills = bills.filter { !$0.isPaid }
        print("📅 Found \(unpaidBills.count) unpaid bills to schedule notifications for")
        
        for bill in unpaidBills {
            scheduleBillReminder(for: bill)
        }
        
        updatePendingNotificationsCount()
    }
    
    /// Update the count of pending notifications
    private func updatePendingNotificationsCount() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotificationsCount = requests.count
            }
        }
    }
    
    /// Clear all pending notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        updatePendingNotificationsCount()
        print("🗑️ All notifications cleared")
    }
    
    /// Test notification function - sends a notification immediately
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from LevelUp Budget"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "BILL_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending test notification: \(error)")
            } else {
                print("✅ Test notification scheduled (will appear in 5 seconds)")
                self.updatePendingNotificationsCount()
            }
        }
    }
    
    /// Schedule notification for a savings goal milestone
    /// - Parameter goal: The SavingsGoal to schedule a notification for
    func scheduleSavingsGoalNotification(for goal: SavingsGoal) {
        let content = UNMutableNotificationContent()
        content.title = "Savings Goal Update"
        content.body = "You're \(goal.progressPercentage)% to your goal: \(goal.title)"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "SAVINGS_GOAL"
        content.userInfo = [
            "goalId": goal.title,
            "goalProgress": goal.progressPercentage,
            "goalTarget": goal.targetAmount
        ]
        
        // Schedule for 9 AM tomorrow
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nineAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nineAM),
            repeats: false
        )
        
        let identifier = "savings-goal-\(goal.title.hashValue)-\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling savings goal notification: \(error)")
            } else {
                print("✅ Savings goal notification scheduled for: \(goal.title)")
                self.updatePendingNotificationsCount()
            }
        }
    }
    
    /// Get all pending notifications for debugging
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Pending notifications: \(requests.count)")
            for request in requests {
                print("  - \(request.identifier): \(request.content.title) - \(request.content.body)")
            }
            DispatchQueue.main.async {
                self.pendingNotificationsCount = requests.count
            }
        }
    }
    
    // MARK: - Push Notification Handling
    
    /// Handle incoming push notification
    /// - Parameter userInfo: The notification payload
    func handlePushNotification(userInfo: [AnyHashable: Any]) {
        print("📨 Received push notification: \(userInfo)")
        
        // TODO: Handle different types of push notifications
        // This is where you would parse the notification payload
        // and take appropriate action based on the notification type
        
        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                let title = alert["title"] as? String ?? "LevelUp Budget"
                let body = alert["body"] as? String ?? "You have a new notification"
                print("📢 Push notification: \(title) - \(body)")
            }
        }
        
        // Example: Handle bill due reminders
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "bill_reminder":
                print("💰 Bill reminder notification received")
                // TODO: Navigate to bills view or show bill details
            case "savings_update":
                print("🎯 Savings update notification received")
                // TODO: Navigate to savings view
            default:
                print("📱 Unknown notification type: \(notificationType)")
            }
        }
    }
    
    /// Handle notification actions
    /// - Parameters:
    ///   - identifier: The action identifier
    ///   - userInfo: The notification user info
    func handleNotificationAction(identifier: String, userInfo: [AnyHashable: Any]) {
        print("🔘 Notification action tapped: \(identifier)")
        
        switch identifier {
        case "MARK_AS_PAID":
            if let billId = userInfo["billId"] as? String {
                print("💰 Marking bill as paid: \(billId)")
                // TODO: Update bill status in database
            }
            
        case "SNOOZE":
            if let billId = userInfo["billId"] as? String {
                print("⏰ Snoozing bill reminder: \(billId)")
                // TODO: Reschedule notification for later
            }
            
        case "UPDATE_PROGRESS":
            if let goalId = userInfo["goalId"] as? String {
                print("🎯 Updating savings progress: \(goalId)")
                // TODO: Navigate to savings goal update
            }
            
        default:
            print("❓ Unknown notification action: \(identifier)")
        }
    }
    
    /// Check if notifications are enabled and request permission if needed
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Notification settings: \(settings)")
                self.isPushNotificationsEnabled = settings.authorizationStatus == .authorized
                
                // If not authorized, request permission
                if settings.authorizationStatus == .notDetermined {
                    self.requestPermission()
                }
            }
        }
    }
}

// MARK: - APNs Token Management

extension NotificationManager {
    /// Update APNs token
    func updateAPNsToken(_ token: String) {
        DispatchQueue.main.async {
            self.apnsToken = token
            self.sendTokenToServer(token: token)
        }
    }
} 