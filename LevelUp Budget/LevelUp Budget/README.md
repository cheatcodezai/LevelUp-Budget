# LevelUp Budget

A comprehensive budgeting app built with SwiftUI and SwiftData, featuring iCloud sync for seamless data management across devices.

## Features

- **Bill Management**: Track bills, due dates, and payments
- **Savings Goals**: Set and monitor savings targets
- **Budget Tracking**: Monitor monthly income vs. expenses
- **iCloud Sync**: Automatic data synchronization across devices
- **Push Notifications**: Bill reminders and due date alerts
- **Cross-Platform**: iOS, iPadOS, and macOS support

## CloudKit Sync Features

### Automatic Sync
- **Periodic Sync**: Automatically syncs every 5 minutes when the app is active
- **App Activation**: Syncs when the app becomes active or foreground
- **View Navigation**: Syncs when navigating to Bills or Savings views
- **Data Changes**: Automatically syncs when bills or savings goals are added/edited

### Manual Sync
- **Dashboard Sync Button**: Manual sync button in the main dashboard
- **Sync Status Card**: Real-time sync status display with manual sync option
- **Toolbar Sync**: Quick sync button in the navigation toolbar

### Sync Triggers
- App launch and foreground activation
- Navigation between main views
- Adding/editing bills or savings goals
- Periodic background sync (every 5 minutes)
- Manual sync requests

## Notification System

### Bill Notifications
- **Due Date Reminders**: Notifications when bills are due
- **Advance Warnings**: 1-day advance reminders for upcoming bills
- **Interactive Actions**: Mark as paid, snooze, or dismiss notifications
- **Automatic Scheduling**: Notifications are scheduled when bills are created/updated

### Savings Goal Notifications
- **Progress Updates**: Notifications for savings goal milestones
- **Interactive Actions**: Update progress directly from notifications
- **Smart Timing**: Notifications scheduled at optimal times (9 AM)

### Notification Features
- **Permission Management**: Automatic permission requests with user control
- **Status Monitoring**: Real-time notification status and pending count
- **Test Notifications**: Built-in test functionality to verify setup
- **Category Support**: Organized notification categories with custom actions

### Notification Settings
- **Toggle Controls**: Enable/disable notifications per category
- **Status Display**: Real-time notification permission and scheduling status
- **Manual Controls**: Test notifications and manage preferences
- **Automatic Setup**: Notifications configured automatically on app launch

## TestFlight Sync Troubleshooting

If you're experiencing sync issues on TestFlight:

1. **Check iCloud Status**: Ensure you're signed into iCloud on both devices
2. **Network Connection**: Verify both devices have stable internet connections
3. **Manual Sync**: Use the "Sync Now" button in the dashboard
4. **App Restart**: Try restarting the app on both devices
5. **Check Console**: Look for sync-related logs in the console

### Common Sync Issues
- **Guest Users**: CloudKit sync is disabled for guest users
- **Network Timeout**: Sync may fail if network is unstable
- **iCloud Restrictions**: Some enterprise environments may restrict iCloud access

## TestFlight Notification Troubleshooting

If notifications aren't working on TestFlight:

1. **Check Permissions**: Ensure notifications are enabled in app settings
2. **Test Notifications**: Use the "Test Notification" button in settings
3. **Permission Status**: Check notification status in Settings > Notifications
4. **App Restart**: Restart the app after granting permissions
5. **Device Settings**: Verify notifications are enabled in device settings

### Common Notification Issues
- **Permission Denied**: User must manually enable notifications in settings
- **Background App Refresh**: Ensure background app refresh is enabled
- **Do Not Disturb**: Check if Do Not Disturb mode is active
- **Focus Modes**: Verify focus modes aren't blocking notifications

## Technical Details

- **CloudKit Container**: `iCloud.com.cheatcodez.LevelupBudget`
- **Data Models**: Bills and Savings Goals with automatic conflict resolution
- **Sync Strategy**: Bidirectional sync with intelligent merging
- **Conflict Resolution**: Timestamp-based conflict resolution with data quality scoring
- **Notification Categories**: BILL_REMINDER and SAVINGS_GOAL with custom actions
- **Permission Handling**: Automatic permission requests with fallback options

## Development

Built with:
- SwiftUI 5.0+
- SwiftData
- CloudKit
- UserNotifications
- Network framework

## Support

For sync issues or feature requests, please check the console logs and provide device information for troubleshooting.
