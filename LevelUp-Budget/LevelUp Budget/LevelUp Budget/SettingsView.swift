//
//  SettingsView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @Query private var bills: [BillItem]
    @Query private var userSettings: [UserSettings]
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingClearDataAlert = false
    @State private var showingClearDataConfirmation = false
    @State private var exportProgress: Double = 0.0
    @State private var isExporting = false
    @State private var showingAuthentication = false
    @State private var showDebugInfo = false
    
    private var settings: UserSettings {
        if let existingSettings = userSettings.first {
            return existingSettings
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
    }
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            NavigationStack {
                ScrollView {
                    VStack(spacing: 40) {
                        // Brand Header
                        BrandHeaderView(currentDate: currentDate)
                        
                        // Settings Content with increased spacing
                        VStack(spacing: 32) {
                            // 1. Monthly Budget
                            SettingsCardView(
                                title: "Monthly Budget",
                                icon: "dollarsign.circle.fill",
                                iconColor: Color(red: 0, green: 1, blue: 0.4)
                            ) {
                                MonthlyBudgetSection(settings: settings)
                            }
                            
                            // 2. App Preferences
                            SettingsCardView(
                                title: "App Preferences",
                                icon: "gearshape.fill",
                                iconColor: .orange
                            ) {
                                AppPreferencesSection(settings: settings)
                            }
                            
                            // 3. Data Management (separated from Network Diagnostics)
                            SettingsCardView(
                                title: "Data Management",
                                icon: "folder.fill",
                                iconColor: .green
                            ) {
                                DataManagementSection(
                                    showingExportSheet: $showingExportSheet,
                                    showingImportSheet: $showingImportSheet,
                                    showingClearDataAlert: $showingClearDataAlert
                                )
                            }
                            
                            // 4. Network Diagnostics (separate card)
                            SettingsCardView(
                                title: "Network Diagnostics",
                                icon: "network",
                                iconColor: .purple
                            ) {
                                NetworkDiagnosticsSection()
                            }
                            
                            // 5. Account
                            SettingsCardView(
                                title: "Account",
                                icon: "person.circle.fill",
                                iconColor: .blue
                            ) {
                                AccountSection()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 50)
                    }
                    .frame(maxWidth: 650, alignment: .center)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .navigationTitle("")
                #if os(macOS)
                .frame(minWidth: 700, minHeight: 500)
                #endif
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView()
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                showingClearDataConfirmation = true
            }
        } message: {
            Text("This action cannot be undone. All bills, savings goals, and settings will be permanently deleted.")
        }
        .alert("Data Cleared", isPresented: $showingClearDataConfirmation) {
            Button("OK") { }
        } message: {
            Text("All data has been successfully cleared.")
        }
    }
}

// MARK: - Reusable Settings Card View
struct SettingsCardView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Card Content
            content
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Brand Header View
struct BrandHeaderView: View {
    let currentDate: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Custom Logo: Green rounded square with arrow
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0, green: 1, blue: 0.4), lineWidth: 2)
                    .frame(width: 60, height: 60)
                
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
            
            // Settings Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings & Preferences")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Customize your LevelUp Budget experience")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(currentDate)
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 60)
    }
}

// MARK: - Monthly Budget Section with Visual Aids
struct MonthlyBudgetSection: View {
    let settings: UserSettings
    @State private var budgetValue: Double
    @State private var incomeValue: Double
    @State private var isEditingIncome = false
    @State private var showingCustomBudgetInput = false
    @State private var customBudgetValue: String = ""
    
    init(settings: UserSettings) {
        self.settings = settings
        self._budgetValue = State(initialValue: settings.monthlyBudget)
        self._incomeValue = State(initialValue: settings.monthlyIncome)
    }
    
    private var budgetPercentage: Double {
        guard incomeValue > 0 else { return 0 }
        return (budgetValue / incomeValue) * 100
    }
    
    private var budgetFeedback: String {
        if budgetPercentage <= 30 {
            return "Excellent balance"
        } else if budgetPercentage <= 50 {
            return "Good balance"
        } else if budgetPercentage <= 70 {
            return "Moderate spending"
        } else if budgetPercentage <= 90 {
            return "High spending"
        } else {
            return "Over budget"
        }
    }
    
    private var feedbackColor: Color {
        if budgetPercentage <= 30 {
            return .green
        } else if budgetPercentage <= 50 {
            return Color(red: 0, green: 1, blue: 0.4)
        } else if budgetPercentage <= 70 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Budget Controls Section
            VStack(spacing: 0) {
                // Section header with icon
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4).opacity(0.7))
                    
                    Text("Budget Controls")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Budget Display with rounded background
                HStack {
                    Spacer()
                    
                    Text("$\(String(format: "%.0f", budgetValue))")
                        .font(.title2.bold())
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0, green: 1, blue: 0.4).opacity(0.15))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                
                // Enhanced Budget Slider with Visual Aids
                VStack(spacing: 16) {
                    #if os(macOS)
                    // Simplified macOS slider
                    VStack(spacing: 12) {
                        // Interactive Slider with hover effects
                        Slider(value: $budgetValue, in: 100...10000, step: 100)
                            .accentColor(Color(red: 0, green: 1, blue: 0.4))
                            .padding(.horizontal, 20)
                            .onChange(of: budgetValue) { newValue in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    settings.monthlyBudget = newValue
                                    settings.updatedAt = Date()
                                }
                            }
                            .onHover { hovering in
                                // Hover effect for slider thumb
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    // Visual feedback handled by system
                                }
                            }
                        
                        // Simplified tick markers for macOS
                        HStack {
                            Text("$2,500")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.6))
                            
                            Spacer()
                            
                            Text("$5,000")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.6))
                            
                            Spacer()
                            
                            Text("$7,500")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.6))
                            
                            Spacer()
                            
                            Text("$10,000")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                    }
                    #else
                    // Original iOS/iPadOS slider with visual track
                    // Interactive Slider (functional but invisible)
                    Slider(value: $budgetValue, in: 100...10000, step: 100)
                        .accentColor(Color(red: 0, green: 1, blue: 0.4))
                        .padding(.horizontal, 20)
                        .onChange(of: budgetValue) { newValue in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.monthlyBudget = newValue
                                settings.updatedAt = Date()
                            }
                        }
                    
                    // Visual track overlay (non-interactive)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                            
                            // Progress track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0, green: 1, blue: 0.4))
                                .frame(width: CGFloat((budgetValue - 100) / (10000 - 100)) * (geometry.size.width - 40), height: 8)
                            
                            // Slider thumb
                            Circle()
                                .fill(Color(red: 0, green: 1, blue: 0.4))
                                .frame(width: 20, height: 20)
                                .offset(x: CGFloat((budgetValue - 100) / (10000 - 100)) * (geometry.size.width - 40) - 10)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        .frame(height: 20)
                        .allowsHitTesting(false) // Make visual track non-interactive
                    }
                    .frame(height: 20)
                    .padding(.horizontal, 20)
                    .offset(y: -20) // Position over the actual slider
                    #endif
                    
                    // Enhanced labels with visual aids and explanations
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("$100")
                                    .font(.footnote)
                                    .foregroundColor(.gray.opacity(0.7))
                                
                                Text("Minimum")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            #if os(iOS) || os(tvOS)
                            // Budget range indicators with explanations (iOS/iPadOS only)
                            HStack(spacing: 16) {
                                VStack(spacing: 2) {
                                    Text("$2,500")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.6))
                                    Text("Low Budget")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                
                                VStack(spacing: 2) {
                                    Text("$5,000")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.6))
                                    Text("Medium Budget")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                
                                VStack(spacing: 2) {
                                    Text("$7,500")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.6))
                                    Text("High Budget")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }
                            #endif
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("$10,000")
                                    .font(.footnote)
                                    .foregroundColor(.gray.opacity(0.7))
                                
                                Text("Maximum")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        #if os(iOS) || os(tvOS)
                        // Budget explanation (iOS/iPadOS only)
                        Text("Adjust your monthly spending limit. The slider shows typical budget ranges: Low ($2,500), Medium ($5,000), and High ($7,500) for reference.")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        #endif
                    }
                }
                
                // Custom Budget Mode Button (when budget > $10,000)
                if budgetValue > 10000 {
                    Button(action: {
                        customBudgetValue = String(format: "%.0f", budgetValue)
                        showingCustomBudgetInput = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                            
                            Text("Custom Budget Mode")
                                .font(.subheadline.bold())
                                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0, green: 1, blue: 0.4).opacity(0.1))
                        )
                    }
                    .padding(.top, 8)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.vertical, 16)
                
                // Monthly Income Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Monthly Income")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            isEditingIncome = true
                        }) {
                            Text("$\(String(format: "%.0f", incomeValue))")
                                .font(.subheadline.bold())
                                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0, green: 1, blue: 0.4).opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Budget Percentage and Feedback
                    VStack(spacing: 8) {
                        HStack {
                            Text("You're budgeting \(String(format: "%.0f", budgetPercentage))% of your income")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.8))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        HStack {
                            Text(budgetFeedback)
                                .font(.caption.bold())
                                .foregroundColor(feedbackColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $isEditingIncome) {
            IncomeEditView(incomeValue: $incomeValue, settings: settings)
        }
        .alert("Custom Budget", isPresented: $showingCustomBudgetInput) {
            TextField("Enter budget amount", text: $customBudgetValue)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            
            Button("Cancel", role: .cancel) { }
            Button("Set Budget") {
                if let newValue = Double(customBudgetValue), newValue >= 100 {
                    budgetValue = newValue
                    settings.monthlyBudget = newValue
                    settings.updatedAt = Date()
                }
            }
        } message: {
            Text("Enter your custom monthly budget amount:")
        }
    }
}

// MARK: - Income Edit View
struct IncomeEditView: View {
    @Binding var incomeValue: Double
    let settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @State private var tempIncomeValue: String
    
    init(incomeValue: Binding<Double>, settings: UserSettings) {
        self._incomeValue = incomeValue
        self.settings = settings
        self._tempIncomeValue = State(initialValue: String(format: "%.0f", incomeValue.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Monthly Income")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Set your monthly income to calculate budget percentages")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                TextField("Enter monthly income", text: $tempIncomeValue)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 22))
                    .padding(.horizontal, 40)
                
                Button("Save Income") {
                    if let newValue = Double(tempIncomeValue), newValue > 0 {
                        incomeValue = newValue
                        settings.monthlyIncome = newValue
                        settings.updatedAt = Date()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(Double(tempIncomeValue) == nil || Double(tempIncomeValue) ?? 0 <= 0)
            }
            .padding()
            .navigationTitle("Edit Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - App Preferences Section
struct AppPreferencesSection: View {
    let settings: UserSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Notifications Section
            VStack(spacing: 0) {
                // Section header with icon
                HStack {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange.opacity(0.7))
                    
                    Text("Notifications")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Bill Reminders Toggle with rounded background
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bill Reminders")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Text("Get notified before bills are due")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { newValue in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.notificationsEnabled = newValue
                                settings.updatedAt = Date()
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Data Management Section (separated from Network Diagnostics)
struct DataManagementSection: View {
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var showingClearDataAlert: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Backup Tools Section
            VStack(spacing: 0) {
                // Section header with icon
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green.opacity(0.7))
                    
                    Text("Backup Tools")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Export Data with rounded background
                SettingsActionRow(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "Backup your data to a file",
                    color: .green,
                    action: { showingExportSheet = true }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                // Import Data with rounded background
                SettingsActionRow(
                    icon: "square.and.arrow.down",
                    title: "Import Data",
                    subtitle: "Restore data from a backup",
                    color: .blue,
                    action: { showingImportSheet = true }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 12)
            
            // Destructive Actions Section
            VStack(spacing: 0) {
                // Section header with icon
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red.opacity(0.7))
                    
                    Text("Destructive Actions")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Clear All Data with rounded background
                SettingsActionRow(
                    icon: "trash",
                    title: "Clear All Data",
                    subtitle: "Permanently delete all data",
                    color: .red,
                    action: { showingClearDataAlert = true }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Network Diagnostics Section (separate card)
struct NetworkDiagnosticsSection: View {
    var body: some View {
        VStack(spacing: 0) {
            // Connectivity Tests Section
            VStack(spacing: 0) {
                // Section header with icon
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.purple.opacity(0.7))
                    
                    Text("Connectivity Tests")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Network Connectivity Test with rounded background
                SettingsActionRow(
                    icon: "network",
                    title: "Network Connectivity",
                    subtitle: "Test basic internet connection",
                    color: .purple,
                    action: { runNetworkConnectivityTest() }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                // CloudKit Sync Test with rounded background
                SettingsActionRow(
                    icon: "icloud",
                    title: "CloudKit Sync",
                    subtitle: "Test iCloud synchronization",
                    color: .blue,
                    action: { runCloudKitSyncTest() }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 12)
            
            // Service Tests Section
            VStack(spacing: 0) {
                // Section header with icon
                HStack {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange.opacity(0.7))
                    
                    Text("Service Tests")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Firebase Connection Test with rounded background
                SettingsActionRow(
                    icon: "flame",
                    title: "Firebase Connection",
                    subtitle: "Test authentication services",
                    color: .orange,
                    action: { runFirebaseConnectionTest() }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                // DNS Resolution Test with rounded background
                SettingsActionRow(
                    icon: "globe",
                    title: "DNS Resolution",
                    subtitle: "Test domain name resolution",
                    color: .green,
                    action: { runDNSResolutionTest() }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func runNetworkConnectivityTest() {
        Task {
            print("🔍 Testing network connectivity...")
            // Implementation for network connectivity test
        }
    }
    
    private func runCloudKitSyncTest() {
        Task {
            print("🔍 Testing CloudKit sync...")
            // Implementation for CloudKit sync test
        }
    }
    
    private func runFirebaseConnectionTest() {
        Task {
            print("🔍 Testing Firebase connection...")
            // Implementation for Firebase connection test
        }
    }
    
    private func runDNSResolutionTest() {
        Task {
            print("🔍 Testing DNS resolution...")
            // Implementation for DNS resolution test
        }
    }
}

// MARK: - Account Section
struct AccountSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Account Information Section
            VStack(spacing: 0) {
                // Section header with icon
                HStack {
                    Image(systemName: "person.2")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("Account Information")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Grouped account items in one rounded background
                VStack(spacing: 0) {
                    // Current User Info
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current User")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            
                            Text(authViewModel.currentUser?.name ?? "Guest User")
                                .font(.footnote)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // Light divider between user info and sign out
                    Divider()
                        .background(Color.gray.opacity(0.2))
                        .padding(.horizontal, 20)
                    
                    // Sign Out Button
                    SettingsActionRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Sign Out",
                        subtitle: "Sign out of your account",
                        color: .red,
                        action: { authViewModel.signOut() }
                    )
                    .background(Color.clear)
                    .padding(.horizontal, 0)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Settings Action Row with Enhanced Styling
struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: true)
    }
}

// MARK: - Export View
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export Data")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Export functionality coming soon...")
                    .foregroundColor(.gray)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Import View
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Import Data")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Import functionality coming soon...")
                    .foregroundColor(.gray)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 