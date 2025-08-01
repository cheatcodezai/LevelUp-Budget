//
//  Item.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - User Model
struct User: Codable {
    let id: String
    let email: String?
    let name: String?
    let authProvider: AuthProvider
    
    enum AuthProvider: String, Codable, CaseIterable {
        case apple = "Apple"
        case google = "Google"
        case email = "Email"
        case faceID = "FaceID"
        case local = "Local"
    }
    
    init(id: String, email: String?, name: String?, authProvider: AuthProvider) {
        self.id = id
        self.email = email
        self.name = name
        self.authProvider = authProvider
    }
}

@Model
final class BillItem {
    var title: String = ""
    var amount: Double = 0.0
    var dueDate: Date = Date()
    var isPaid: Bool = false
    var notes: String = ""
    var category: String = "General"
    var isRecurring: Bool = false
    var recurrenceType: String?
    var endDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(title: String, amount: Double, dueDate: Date, isPaid: Bool = false, notes: String = "", category: String = "General", isRecurring: Bool = false, recurrenceType: String? = nil, endDate: Date? = nil) {
        self.title = title
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.notes = notes
        self.category = category
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.endDate = endDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class SavingsGoal {
    var title: String = ""
    var category: String = ""
    var goalType: String = "Savings"
    var targetAmount: Double = 0.0
    var currentAmount: Double = 0.0
    var targetDate: Date = Date()
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(title: String, category: String, goalType: String = "Savings", targetAmount: Double, currentAmount: Double = 0.0, targetDate: Date, notes: String = "") {
        self.title = title
        self.category = category
        self.goalType = goalType
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class UserSettings {
    var monthlyBudget: Double = 2000.0
    var notificationsEnabled: Bool = true
    var darkModeEnabled: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(monthlyBudget: Double = 2000.0, notificationsEnabled: Bool = true, darkModeEnabled: Bool = false) {
        self.monthlyBudget = monthlyBudget
        self.notificationsEnabled = notificationsEnabled
        self.darkModeEnabled = darkModeEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - BillItem Extensions
extension BillItem {
    var isOverdue: Bool {
        return !isPaid && dueDate < Date()
    }
    
    var daysUntilDue: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    var statusColor: Color {
        if isPaid {
            return .green
        } else if isOverdue {
            return .red
        } else if daysUntilDue <= 7 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var statusText: String {
        if isPaid {
            return "Paid"
        } else if isOverdue {
            return "Overdue"
        } else if daysUntilDue <= 7 {
            return "Due Soon"
        } else {
            return "Upcoming"
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
}

// MARK: - SavingsGoal Extensions
extension SavingsGoal {
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var isCompleted: Bool {
        return currentAmount >= targetAmount
    }
    
    var isOverdue: Bool {
        return Date() > targetDate && !isCompleted
    }
    
    var statusColor: Color {
        if isCompleted {
            return .green
        } else if isOverdue {
            return .red
        } else {
            return .blue
        }
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var remainingAmount: Double {
        return max(targetAmount - currentAmount, 0)
    }
    
    var formattedTargetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: targetAmount)) ?? "$0.00"
    }
    
    var formattedCurrentAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: currentAmount)) ?? "$0.00"
    }
    
    var formattedRemainingAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: remainingAmount)) ?? "$0.00"
    }
    
    var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetDate)
    }
    
    var statusText: String {
        if progress >= 1.0 {
            return "Completed"
        } else if isOverdue {
            return "Overdue"
        } else {
            return "In Progress"
        }
    }
}

// MARK: - UserSettings Extensions
extension UserSettings {
    var formattedMonthlyBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: monthlyBudget)) ?? "$0.00"
    }
}

