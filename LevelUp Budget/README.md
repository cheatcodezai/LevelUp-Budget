# LevelUp Budget

A modern, clean SwiftUI budget app that helps you level up your finances! 💪

## Features

### Core Functionality
- **Bill Management**: Add, edit, and delete bills with due dates and amounts
- **Budget Tracking**: Monthly budget progress with visual indicators
- **Smart Reminders**: Local notifications for upcoming bill due dates
- **Multi-platform**: Runs on both macOS and iOS
- **Offline Storage**: SwiftData for local persistence
- **CloudKit Ready**: Structured for future CloudKit integration

### User Interface
- **Modern Design**: Clean, intuitive interface following Apple's design guidelines
- **Dark Mode Support**: Automatic dark/light mode adaptation
- **Dashboard**: Summary widgets showing key financial metrics
- **Search & Filter**: Find bills quickly with search and category filters
- **Progress Tracking**: Visual progress bars for budget usage

### Data Management
- **SwiftData Integration**: Modern persistence framework
- **Export Options**: CSV and JSON export functionality
- **Settings Management**: Configurable budget limits and notification preferences

## Architecture

### Data Model
The app uses a single `BillItem` model with the following properties:
- `title`: Bill name/description
- `amount`: Bill amount (Double)
- `dueDate`: When the bill is due
- `isPaid`: Payment status
- `notes`: Optional notes
- `category`: Bill category for organization
- `createdAt`/`updatedAt`: Timestamps for tracking

### Views Structure
- **ContentView**: Main tab-based navigation
- **DashboardView**: Summary and progress indicators
- **BillsListView**: List of all bills with search/filter
- **BillFormView**: Add/edit bill form
- **BillDetailView**: Detailed bill information
- **SettingsView**: App configuration and data export

### Key Components
- **NotificationManager**: Handles local notifications for bill reminders
- **Budget Progress**: Visual progress tracking with color-coded status
- **Export System**: Data export in multiple formats
- **Search & Filter**: Advanced bill discovery

## Getting Started

1. **Clone the repository**
2. **Open in Xcode**
3. **Build and run** on your preferred platform (iOS/macOS)

## Usage

### Adding Bills
1. Tap the "+" button in the Bills tab
2. Fill in bill details (title, amount, due date, category)
3. Add optional notes
4. Save the bill

### Managing Bills
- **View**: Tap any bill to see details
- **Edit**: Use the edit button in bill details
- **Delete**: Swipe left or use the menu in details
- **Mark Paid**: Toggle payment status in edit mode

### Dashboard
- **Budget Progress**: See how much of your monthly budget is used
- **Quick Stats**: Total bills, paid amounts, overdue items
- **Next Due**: Quick view of upcoming bills

### Settings
- **Budget Configuration**: Set monthly spending limits
- **Notifications**: Configure reminder preferences
- **Data Export**: Export bills as CSV or JSON
- **Appearance**: Choose light/dark/system theme

## Technical Details

### SwiftData Setup
```swift
@Model
final class BillItem {
    var title: String
    var amount: Double
    var dueDate: Date
    var isPaid: Bool
    var notes: String
    var category: String
    var createdAt: Date
    var updatedAt: Date
}
```

### Notification System
- Local notifications for bill due dates
- Configurable reminder timing
- Automatic permission requests

### Export System
- CSV export for spreadsheet compatibility
- JSON export for data portability
- Share sheet integration

## Future Enhancements

### Planned Features
- **CloudKit Sync**: Multi-device synchronization
- **Recurring Bills**: Automatic bill creation
- **Budget Categories**: Detailed spending analysis
- **Charts & Analytics**: Visual spending trends
- **Widgets**: iOS home screen widgets
- **Apple Watch**: Companion watch app

### Technical Improvements
- **Performance**: Optimize for large datasets
- **Accessibility**: Enhanced VoiceOver support
- **Localization**: Multi-language support
- **Testing**: Comprehensive unit and UI tests

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## License

This project is for educational purposes. Feel free to use and modify as needed.

---

**LevelUp Budget** - Level up your finances! 💪 