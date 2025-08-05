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
    
    private init() {
        setupPushNotifications()
    }
    
    // MARK: - Push Notification Setup
    
    /// Setup push notifications
    private func setupPushNotifications() {
        // Request permission for notifications
        requestPermission()
    }
    
    /// Request permission for push notifications
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
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
    /// - Parameter bill: The bill to schedule a reminder for
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
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneDayBefore),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "bill-reminder-\(bill.title)-\(bill.dueDate.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling 1-day reminder: \(error)")
                } else {
                    print("✅ 1-day reminder scheduled for: \(bill.title) on \(oneDayBefore)")
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
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "bill-due-\(bill.title)-\(bill.dueDate.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling due date notification: \(error)")
                } else {
                    print("✅ Due date notification scheduled for: \(bill.title) on \(dueDate)")
                }
            }
        }
    }
    
    /// Cancel notification for a specific bill
    /// - Parameter bill: The bill to cancel notifications for
    func cancelNotification(for bill: BillItem) {
        let identifiers = [
            "bill-reminder-\(bill.title)-\(bill.dueDate.timeIntervalSince1970)",
            "bill-due-\(bill.title)-\(bill.dueDate.timeIntervalSince1970)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled notifications for: \(bill.title)")
    }
    
    /// Schedule reminders for all unpaid bills
    func scheduleAllBillReminders() {
        // This would be called when the app starts or when bills are updated
        // Implementation would iterate through all unpaid bills and schedule reminders
        print("📅 Scheduling reminders for all unpaid bills...")
    }
    
    /// Schedule notifications for all unpaid bills
    func scheduleNotificationsForAllBills() {
        // This function should be called from the main app or when bills are loaded
        // For now, we'll add a placeholder that can be called from ContentView or App
        print("📅 Scheduling notifications for all unpaid bills...")
        
        // TODO: This would need access to the model context to fetch all bills
        // Implementation would look something like:
        // let descriptor = FetchDescriptor<BillItem>(predicate: #Predicate<BillItem> { bill in
        //     !bill.isPaid
        // })
        // let bills = try? modelContext.fetch(descriptor)
        // bills?.forEach { scheduleBillReminder(for: $0) }
    }
    
    /// Test notification function - sends a notification immediately
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from LevelUp Budget"
        content.sound = .default
        content.badge = 1
        
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
        }
    }
    
    /// Check current notification settings
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Notification settings: \(settings)")
                self.isPushNotificationsEnabled = settings.authorizationStatus == .authorized
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