//
//  AppDelegate.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import Foundation
import Firebase
import UserNotifications
#if os(macOS)
import AppKit
import AuthenticationServices
#elseif os(iOS)
import UIKit
import AuthenticationServices
#endif

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate: Application did finish launching")
        
        // Configure Firebase with error handling
        configureFirebase()
        
        // Setup push notifications
        setupPushNotifications()
    }
    
    private func configureFirebase() {
        // Check if Firebase is already configured
        if FirebaseApp.app() == nil {
            print("🔧 Configuring Firebase...")
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
        } else {
            print("ℹ️ Firebase already configured")
        }
    }
    
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        print("📱 AppDelegate: Received remote notification")
        // Handle remote notification
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 AppDelegate: Registered for remote notifications")
        // Handle device token registration
    }
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ AppDelegate: Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Push Notifications Setup
    
    private func setupPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Push notification permission granted")
            } else {
                print("❌ Push notification permission denied")
            }
            
            if let error = error {
                print("❌ Push notification setup error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("🚀 AppDelegate: Application did become active")
        // Handle app becoming active
    }
}

#elseif os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("🚀 AppDelegate: Application did finish launching")
        
        // Configure Firebase with error handling
        configureFirebase()
        
        // Setup push notifications
        setupPushNotifications()
        
        return true
    }
    
    private func configureFirebase() {
        // Check if Firebase is already configured
        if FirebaseApp.app() == nil {
            print("🔧 Configuring Firebase...")
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
        } else {
            print("ℹ️ Firebase already configured")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [String: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 AppDelegate: Received remote notification")
        // Handle remote notification
        completionHandler(.newData)
    }
    
    // Optional method for older iOS versions
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        print("📱 AppDelegate: Received remote notification (legacy)")
        // Handle remote notification
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 AppDelegate: Registered for remote notifications")
        // Handle device token registration
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ AppDelegate: Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Push Notifications Setup
    
    private func setupPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Push notification permission granted")
            } else {
                print("❌ Push notification permission denied")
            }
            
            if let error = error {
                print("❌ Push notification setup error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("🚀 AppDelegate: Application did become active")
        // Handle app becoming active
    }
}

#endif 