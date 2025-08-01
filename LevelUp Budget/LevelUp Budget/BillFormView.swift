//
//  BillFormView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData

struct BillFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var category = "General"
    @State private var notes = ""
    @State private var isPaid = false
    @State private var showNotes = false
    @State private var isRecurring = false
    @State private var recurrenceType = "None"
    @State private var endDate = Date().addingTimeInterval(86400 * 365) // 1 year from now
    @State private var hasNoEndDate = false
    
    let bill: BillItem?
    let isEditing: Bool
    
    init(bill: BillItem? = nil) {
        self.bill = bill
        self.isEditing = bill != nil
        
        if let bill = bill {
            _title = State(initialValue: bill.title)
            _amount = State(initialValue: String(format: "%.2f", bill.amount))
            _dueDate = State(initialValue: bill.dueDate)
            _category = State(initialValue: bill.category)
            _notes = State(initialValue: bill.notes)
            _isPaid = State(initialValue: bill.isPaid)
            _isRecurring = State(initialValue: bill.isRecurring)
            _recurrenceType = State(initialValue: bill.recurrenceType ?? "None")
            _endDate = State(initialValue: bill.endDate ?? Date().addingTimeInterval(86400 * 365))
            _hasNoEndDate = State(initialValue: bill.endDate == nil)
        } else {
            // Provide sensible defaults for new bills
            _title = State(initialValue: "")
            _amount = State(initialValue: "")
            _dueDate = State(initialValue: Date().addingTimeInterval(86400 * 7)) // 7 days from now
            _category = State(initialValue: "General")
            _notes = State(initialValue: "")
            _isPaid = State(initialValue: false)
            _isRecurring = State(initialValue: false)
            _recurrenceType = State(initialValue: "None")
            _endDate = State(initialValue: Date().addingTimeInterval(86400 * 365))
            _hasNoEndDate = State(initialValue: false)
        }
    }
    
    private let categories = [
        "General", "Housing", "Utilities", "Transportation",
        "Food", "Entertainment", "Healthcare", "Insurance",
        "Debt", "Subscriptions", "Other"
    ]
    
    private let recurrenceOptions = [
        "None", "Daily", "Weekly", "Monthly", "Yearly"
    ]
    
    private var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else { return false }
        guard !trimmedAmount.isEmpty else { return false }
        
        if let amountValue = Double(trimmedAmount) {
            return amountValue > 0
        }
        return false
    }
    
    private var nextDueDatePreview: String {
        guard isRecurring && recurrenceType != "None" else {
            return "No recurrence set"
        }
        
        let calendar = Calendar.current
        var nextDate = dueDate
        
        switch recurrenceType {
        case "Daily":
            nextDate = calendar.date(byAdding: .day, value: 1, to: dueDate) ?? dueDate
        case "Weekly":
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: dueDate) ?? dueDate
        case "Monthly":
            nextDate = calendar.date(byAdding: .month, value: 1, to: dueDate) ?? dueDate
        case "Yearly":
            nextDate = calendar.date(byAdding: .year, value: 1, to: dueDate) ?? dueDate
        default:
            return "No recurrence set"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Next due: \(formatter.string(from: nextDate))"
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
                        
                        // Bill Information Section
                        FormSection(
                            title: "BILL INFORMATION",
                            icon: "doc.text.fill",
                            iconColor: .blue
                        ) {
                            VStack(spacing: 20) {
                                // Bill Title
                                FormField(
                                    icon: "doc.text",
                                    iconColor: .blue,
                                    label: "Bill Title",
                                    placeholder: "Enter bill title"
                                ) {
                                    TextField("Enter bill title", text: $title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .accentColor(.blue)
                                }
                                
                                // Amount
                                FormField(
                                    icon: "dollarsign.circle",
                                    iconColor: .green,
                                    label: "Amount",
                                    placeholder: "0.00"
                                ) {
                                    HStack(spacing: 8) {
                                        Text("$")
                                            .foregroundColor(.gray.opacity(0.7))
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        TextField("0.00", text: $amount)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .accentColor(.green)
                                            #if os(iOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                    }
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
                                
                                // Due Date
                                FormField(
                                    icon: "calendar",
                                    iconColor: .purple,
                                    label: "Due Date",
                                    placeholder: "Select date"
                                ) {
                                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .accentColor(.purple)
                                        .colorScheme(.dark)
                                }
                                
                                // Recurring Toggle
                                FormToggleField(
                                    icon: "repeat",
                                    iconColor: .indigo,
                                    label: "Repeat Bill",
                                    subtitle: "Set up recurring payments",
                                    isOn: $isRecurring,
                                    toggleColor: .green
                                )
                                
                                // Recurrence Options (if enabled)
                                if isRecurring {
                                    VStack(spacing: 20) {
                                        // Recurrence Type
                                        // Recurrence Type
                                        FormField(
                                            icon: "clock.arrow.circlepath",
                                            iconColor: .orange,
                                            label: "Repeat Frequency",
                                            placeholder: "Select frequency"
                                        ) {
                                            Picker("Repeat Frequency", selection: $recurrenceType) {
                                                ForEach(recurrenceOptions, id: \.self) { option in
                                                    Text(option)
                                                        .foregroundColor(.white)
                                                        .tag(option)
                                                }
                                            }
                                            .pickerStyle(MenuPickerStyle())
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .accentColor(.orange)
                                        }
                                        
                                        // End Date
                                        FormField(
                                            icon: "calendar.badge.clock",
                                            iconColor: .red,
                                            label: "End Date",
                                            placeholder: "Set end date"
                                        ) {
                                            VStack(spacing: 12) {
                                                HStack {
                                                    Text("No end date")
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    Toggle("", isOn: $hasNoEndDate)
                                                        .toggleStyle(SwitchToggleStyle(tint: .green))
                                                        .labelsHidden()
                                                        .scaleEffect(0.9)
                                                }
                                                
                                                if !hasNoEndDate {
                                                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                                        .datePickerStyle(CompactDatePickerStyle())
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.white)
                                                        .accentColor(.red)
                                                        .colorScheme(.dark)
                                                }
                                            }
                                        }
                                        
                                        // Next Due Preview
                                        FormField(
                                            icon: "info.circle",
                                            iconColor: .blue,
                                            label: "Next Due",
                                            placeholder: ""
                                        ) {
                                            Text(nextDueDatePreview)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                                        removal: .scale(scale: 0.95).combined(with: .opacity)
                                    ))
                                    .animation(.easeInOut(duration: 0.3), value: isRecurring)
                                }
                            }
                        }
                        
                        // Payment Status Section
                        FormSection(
                            title: "PAYMENT STATUS",
                            icon: "checkmark.circle.fill",
                            iconColor: .green
                        ) {
                            VStack(spacing: 20) {
                                FormToggleField(
                                    icon: "checkmark.circle",
                                    iconColor: .green,
                                    label: "Mark as Paid",
                                    subtitle: "Mark this bill as already paid",
                                    isOn: $isPaid,
                                    toggleColor: .green
                                )
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
                                title: isEditing ? "Save Changes" : "Add Bill",
                                icon: isEditing ? "checkmark" : "plus",
                                isEnabled: isFormValid,
                                action: saveBill
                            )
                            .accessibilityLabel(isEditing ? "Save changes" : "Add bill")
                            
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
        .navigationTitle(isEditing ? "Edit Bill" : "Add Bill")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func saveBill() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let amountValue = Double(trimmedAmount), amountValue > 0 else { return }
        
        // Handle recurrence data
        let finalRecurrenceType = isRecurring && recurrenceType != "None" ? recurrenceType : nil
        let finalEndDate = isRecurring && !hasNoEndDate ? endDate : nil
        
        if let existingBill = bill {
            // Update existing bill
            existingBill.title = trimmedTitle
            existingBill.amount = amountValue
            existingBill.dueDate = dueDate
            existingBill.category = category
            existingBill.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            existingBill.isPaid = isPaid
            existingBill.isRecurring = isRecurring
            existingBill.recurrenceType = finalRecurrenceType
            existingBill.endDate = finalEndDate
            existingBill.updatedAt = Date()
        } else {
            // Create new bill
            let newBill = BillItem(
                title: trimmedTitle,
                amount: amountValue,
                dueDate: dueDate,
                isPaid: isPaid,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                isRecurring: isRecurring,
                recurrenceType: finalRecurrenceType,
                endDate: finalEndDate
            )
            modelContext.insert(newBill)
        }
        
        dismiss()
    }
}

#Preview {
    BillFormView()
        .modelContainer(for: BillItem.self, inMemory: true)
} 
