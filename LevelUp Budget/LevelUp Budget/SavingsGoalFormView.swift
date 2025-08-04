//
//  SavingsGoalFormView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData

struct SavingsGoalFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var category = "General"
    @State private var goalType = "Savings"
    @State private var targetAmount = ""
    @State private var currentAmount = ""
    @State private var targetDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
    @State private var notes = ""
    @State private var showNotes = false
    
    let goal: SavingsGoal?
    let isEditing: Bool
    
    init(goal: SavingsGoal? = nil) {
        self.goal = goal
        self.isEditing = goal != nil
        
        if let goal = goal {
            _title = State(initialValue: goal.title)
            _category = State(initialValue: goal.category)
            _goalType = State(initialValue: goal.goalType)
            _targetAmount = State(initialValue: String(format: "%.2f", goal.targetAmount))
            _currentAmount = State(initialValue: String(format: "%.2f", goal.currentAmount))
            _targetDate = State(initialValue: goal.targetDate)
            _notes = State(initialValue: goal.notes)
        } else {
            // Provide sensible defaults for new goals
            _title = State(initialValue: "")
            _category = State(initialValue: "General")
            _goalType = State(initialValue: "Savings")
            _targetAmount = State(initialValue: "")
            _currentAmount = State(initialValue: "")
            _targetDate = State(initialValue: Date().addingTimeInterval(86400 * 30))
            _notes = State(initialValue: "")
        }
    }
    
    private let categories = [
        "General", "Trip", "House", "Car", "Emergency Fund",
        "Credit Card Payoff", "Investment", "Education", "Wedding",
        "Retirement", "Business", "Other"
    ]
    
    private let goalTypes = [
        "Savings", "Credit Card Payoff", "Debt Payoff", "Investment"
    ]
    
    private var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTargetAmount = targetAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else { return false }
        guard !trimmedTargetAmount.isEmpty else { return false }
        
        if let targetValue = Double(trimmedTargetAmount) {
            return targetValue > 0
        }
        return false
    }
    
    var body: some View {
        FormContainer {
            // Centered Content Container
            VStack(spacing: 24) {
                // App Logo at Top (for Mac and iPad)
                #if os(macOS) || targetEnvironment(macCatalyst)
                VStack(spacing: 20) {
                    // Custom Logo: Green rounded square with arrow
                    ZStack {
                        // Green rounded square outline
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0, green: 1, blue: 0.4), lineWidth: 2)
                            .frame(width: 60, height: 60)
                        
                        // Upward-right arrow inside square
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                    }
                    .shadow(color: Color(red: 0, green: 1, blue: 0.4).opacity(0.3), radius: 12)
                    
                    // Brand Text
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Text("LEVEL")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                            
                            Text("UP")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }
                        
                        Text("BUDGET")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
                #endif
                        
                        // Goal Information Section
                        FormSection(
                            title: "GOAL INFORMATION",
                            icon: "target",
                            iconColor: .blue
                        ) {
                            VStack(spacing: 20) {
                                // Goal Title
                                FormField(
                                    icon: "target",
                                    iconColor: .blue,
                                    label: "Goal Title",
                                    placeholder: "Enter goal title"
                                ) {
                                    TextField("Enter goal title", text: $title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .accentColor(.blue)
                                }
                                
                                // Category
                                FormField(
                                    icon: "tag",
                                    iconColor: .orange,
                                    label: "Category",
                                    placeholder: "Select category"
                                ) {
                                    Picker("Category", selection: $category) {
                                        ForEach(categories, id: \.self) { category in
                                            Text(category)
                                                .foregroundColor(.white)
                                                .tag(category)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .accentColor(.orange)
                                }
                                
                                // Goal Type
                                FormField(
                                    icon: "flag",
                                    iconColor: .purple,
                                    label: "Goal Type",
                                    placeholder: "Select goal type"
                                ) {
                                    Picker("Goal Type", selection: $goalType) {
                                        ForEach(goalTypes, id: \.self) { type in
                                            Text(type)
                                                .foregroundColor(.white)
                                                .tag(type)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .accentColor(.purple)
                                }
                            }
                        }
                        
                        // Amounts Section
                        FormSection(
                            title: "AMOUNTS",
                            icon: "dollarsign.circle.fill",
                            iconColor: .green
                        ) {
                            VStack(spacing: 20) {
                                // Target Amount
                                FormField(
                                    icon: "dollarsign.circle",
                                    iconColor: .green,
                                    label: "Target Amount",
                                    placeholder: "0.00"
                                ) {
                                    HStack(spacing: 8) {
                                        Text("$")
                                            .foregroundColor(.gray.opacity(0.7))
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        TextField("0.00", text: $targetAmount)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .accentColor(.green)
                                            #if os(iOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                    }
                                }
                                
                                // Current Amount
                                FormField(
                                    icon: "banknote",
                                    iconColor: .purple,
                                    label: "Current Amount",
                                    placeholder: "0.00"
                                ) {
                                    HStack(spacing: 8) {
                                        Text("$")
                                            .foregroundColor(.gray.opacity(0.7))
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        TextField("0.00", text: $currentAmount)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .accentColor(.purple)
                                            #if os(iOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                    }
                                }
                            }
                        }
                        
                        // Target Date Section
                        FormSection(
                            title: "TARGET DATE",
                            icon: "calendar",
                            iconColor: .indigo
                        ) {
                            VStack(spacing: 20) {
                                FormField(
                                    icon: "calendar",
                                    iconColor: .indigo,
                                    label: "Target Date",
                                    placeholder: "Select date"
                                ) {
                                    DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .accentColor(.indigo)
                                        .colorScheme(.dark)
                                }
                            }
                        }
                        
                        // Notes Section
                        FormSection(
                            title: "ADDITIONAL INFORMATION",
                            icon: "note.text",
                            iconColor: .indigo
                        ) {
                            VStack(spacing: 20) {
                                FormField(
                                    icon: "note.text",
                                    iconColor: .indigo,
                                    label: "Notes",
                                    placeholder: "Add notes (optional)"
                                ) {
                                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .accentColor(.indigo)
                                        .lineLimit(3...6)
                                }
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            PrimaryActionButton(
                                title: isEditing ? "Save Changes" : "Add Goal",
                                icon: isEditing ? "checkmark" : "plus",
                                isEnabled: isFormValid,
                                color: .green,
                                action: saveGoal
                            )
                            .accessibilityLabel(isEditing ? "Save changes" : "Add goal")
                            
                            SecondaryActionButton(
                                title: "Cancel",
                                icon: "xmark",
                                action: { dismiss() }
                            )
                            .accessibilityLabel("Cancel")
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: 600, alignment: .center)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
        .navigationTitle(isEditing ? "Edit Goal" : "Add Savings Goal")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func saveGoal() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTargetAmount = targetAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrentAmount = currentAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let targetValue = Double(trimmedTargetAmount), targetValue > 0 else { return }
        
        let currentValue = Double(trimmedCurrentAmount) ?? 0.0
        
        if let existingGoal = goal {
            // Update existing goal
            existingGoal.title = trimmedTitle
            existingGoal.category = category
            existingGoal.goalType = goalType
            existingGoal.targetAmount = targetValue
            existingGoal.currentAmount = currentValue
            existingGoal.targetDate = targetDate
            existingGoal.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            existingGoal.updatedAt = Date()
            
            // Sync updated goal to CloudKit (macOS only)
            #if os(macOS)
            CloudKitManager.shared.saveSavingToCloudKit(existingGoal) { success, error in
                if success {
                    print("✅ Updated savings goal synced to CloudKit: \(existingGoal.title)")
                } else if let error = error {
                    print("❌ Failed to sync updated savings goal to CloudKit: \(error.localizedDescription)")
                }
            }
            #endif
        } else {
            // Create new goal
            let newGoal = SavingsGoal(
                title: trimmedTitle,
                category: category,
                goalType: goalType,
                targetAmount: targetValue,
                currentAmount: currentValue,
                targetDate: targetDate,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            modelContext.insert(newGoal)
            
            // Sync new goal to CloudKit (macOS only)
            #if os(macOS)
            CloudKitManager.shared.saveSavingToCloudKit(newGoal) { success, error in
                if success {
                    print("✅ New savings goal synced to CloudKit: \(newGoal.title)")
                } else if let error = error {
                    print("❌ Failed to sync new savings goal to CloudKit: \(error.localizedDescription)")
                }
            }
            #endif
        }
        
        dismiss()
    }
}

#Preview {
    SavingsGoalFormView()
        .modelContainer(for: SavingsGoal.self, inMemory: true)
} 