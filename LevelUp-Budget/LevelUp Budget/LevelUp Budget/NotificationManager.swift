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
        
        let content = UNMutableNotificationContent()
        content.title = "Bill Due Soon"
        content.body = "\(bill.title) - $\(bill.formattedAmount) is due in \(bill.daysUntilDue) days"
        content.sound = .default
        
        // Schedule notification for the due date
        let dueDate = bill.dueDate
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day], from: dueDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "bill-\(bill.title)-\(bill.dueDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Bill reminder scheduled for: \(bill.title)")
            }
        }
    }
    
    /// Cancel notification for a specific bill
    /// - Parameter bill: The bill to cancel notifications for
    func cancelNotification(for bill: BillItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["bill-\(bill.title)-\(bill.dueDate.timeIntervalSince1970)"]
        )
    }
    
    /// Schedule reminders for all unpaid bills
    func scheduleAllBillReminders() {
        // This would be called when the app starts or when bills are updated
        // Implementation would iterate through all unpaid bills and schedule reminders
        print("📅 Scheduling reminders for all unpaid bills...")
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