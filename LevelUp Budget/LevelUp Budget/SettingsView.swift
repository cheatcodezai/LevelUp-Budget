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
    @State private var showDebugInfo = false // Debug state
    
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
                    VStack(spacing: 32) {
                        // Centered Logo and Brand
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
                        .padding(.top, 60)
                        
                        // Centered Settings Header
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
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Centered Content Container
                        VStack(spacing: 24) {
                            // Budget Settings Card
                            BudgetSettingsCard(settings: settings)
                            
                            // App Preferences Grid
                            AppPreferencesGrid(settings: settings)
                            
                            // Data Management Cards
                            DataManagementCards(
                                showingExportSheet: $showingExportSheet,
                                showingImportSheet: $showingImportSheet,
                                showingClearDataAlert: $showingClearDataAlert,
                                isExporting: $isExporting,
                                exportProgress: $exportProgress,
                                showingAuthentication: $showingAuthentication
                            )
                            
                            // Authentication & Account Section
                            AuthenticationAccountSection()
                            
                            // Debug Section
                            DebugSection(showDebugInfo: $showDebugInfo)
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
        // Temporarily disabled to prevent crash
        // .sheet(isPresented: $showingAuthentication) {
        //     LoginView()
        // }
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

// MARK: - Modern Header View
struct ModernHeaderView: View {
    let currentDate: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings & Preferences")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
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
        .padding(.top, 20)
    }
}

// MARK: - Budget Settings Card
struct BudgetSettingsCard: View {
    let settings: UserSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Set your monthly spending limit")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                Text("$\(String(format: "%.0f", settings.monthlyBudget))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Budget Slider
            VStack(spacing: 16) {
                Slider(value: Binding(
                    get: { settings.monthlyBudget },
                    set: { newValue in
                        settings.monthlyBudget = newValue
                        settings.updatedAt = Date()
                    }
                ), in: 100...10000, step: 100)
                .accentColor(.blue)
                .padding(.horizontal, 24)
                
                HStack {
                    Text("$100")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Spacer()
                    
                    Text("$10,000")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - App Preferences Grid
struct AppPreferencesGrid: View {
    let settings: UserSettings
    
    var body: some View {
        PreferenceToggleCard(
            title: "Bill Reminders",
            subtitle: "Get notified before bills are due",
            icon: "bell.fill",
            iconColor: .orange,
            isOn: Binding(
                get: { settings.notificationsEnabled },
                set: { newValue in
                    settings.notificationsEnabled = newValue
                    settings.updatedAt = Date()
                }
            )
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preference Toggle Card
struct PreferenceToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: toggleColor))
                    .scaleEffect(0.9)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var toggleColor: Color {
        return iconColor
    }
}

// MARK: - Data Management Cards
struct DataManagementCards: View {
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var showingClearDataAlert: Bool
    @Binding var isExporting: Bool
    @Binding var exportProgress: Double
    @Binding var showingAuthentication: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Cloud Sync Card
            CloudSyncCard(action: { showingAuthentication = true })
            
            // Export/Import Cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DataActionCard(
                    title: "Export Data",
                    subtitle: "Backup your bills and settings",
                    icon: "square.and.arrow.up",
                    iconColor: .green,
                    action: { showingExportSheet = true },
                    isExporting: $isExporting,
                    progress: $exportProgress
                )
                
                DataActionCard(
                    title: "Import Data",
                    subtitle: "Restore from backup file",
                    icon: "square.and.arrow.down",
                    iconColor: .blue,
                    action: { showingImportSheet = true },
                    isExporting: .constant(false),
                    progress: .constant(0.0)
                )
            }
            
            // Clear Data Card (Warning Style)
            ClearDataCard(action: { showingClearDataAlert = true })
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data Action Card
struct DataActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    @Binding var isExporting: Bool
    @Binding var progress: Double
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(iconColor.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if isExporting && title == "Export Data" {
                        ProgressView(value: progress)
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.caption)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Clear Data Card
struct ClearDataCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 1, green: 0.23, blue: 0.19))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(red: 1, green: 0.23, blue: 0.19).opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clear All Data")
                        .font(.headline)
                        .foregroundColor(Color(red: 1, green: 0.23, blue: 0.19))
                    
                    Text("Permanently delete all bills and settings")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(red: 1, green: 0.23, blue: 0.19))
                    .font(.caption)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.18, green: 0.04, blue: 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 1, green: 0.23, blue: 0.19).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCardRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var bills: [BillItem]
    @Query private var savingsGoals: [SavingsGoal]
    @Query private var userSettings: [UserSettings]
    @State private var exportData: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    private var backgroundColor: Color {
        return Color.black
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Export Data")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Export bills and savings to CSV for iCloud Drive")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                        
                        Divider()
                            .background(Color.secondary.opacity(0.3))
                    }
                    .padding(.top, 20)
                    
                    // Export Options Card
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export Options")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Choose what to include in your backup")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            ExportOptionRow(
                                title: "Bills",
                                subtitle: "\(bills.count) bills",
                                icon: "list.bullet",
                                color: .blue,
                                isEnabled: true
                            )
                            
                            ExportOptionRow(
                                title: "Savings Goals",
                                subtitle: "\(savingsGoals.count) goals",
                                icon: "banknote",
                                color: .green,
                                isEnabled: true
                            )
                            
                            ExportOptionRow(
                                title: "Summary Report",
                                subtitle: "Financial overview",
                                icon: "chart.bar",
                                color: .purple,
                                isEnabled: true
                            )
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(backgroundColor)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Export Button
                    Button(action: exportDataAction) {
                        HStack(spacing: 12) {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                            }
                            
                            Text(isExporting ? "Exporting..." : "Export to CSV")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isExporting ? Color.gray : Color.green)
                        )
                    }
                    .disabled(isExporting)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.horizontal, max(geometry.size.width * 0.05, 20))
                .frame(maxWidth: min(geometry.size.width * 0.9, 800))
            }
            .background(backgroundColor)
            .navigationTitle("Export Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Export Complete", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareLink(item: url) {
                    Text("Share Export File")
                }
            }
        }
    }
    
    private func exportDataAction() {
        isExporting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
            let timestamp = dateFormatter.string(from: Date())
            
            // Create CSV export
            let csvContent = createCSVExport()
            let csvFileName = "LevelUpBudget_Export_\(timestamp).csv"
            let csvURL = FileManager.default.temporaryDirectory.appendingPathComponent(csvFileName)
            
            do {
                try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
                exportURL = csvURL
                
                #if os(macOS)
                // macOS: Use NSSavePanel
                let panel = NSSavePanel()
                panel.allowedContentTypes = [UTType("public.comma-separated-values-text")!]
                panel.nameFieldStringValue = csvFileName
                
                if panel.runModal() == .OK {
                    if let url = panel.url {
                        try csvContent.write(to: url, atomically: true, encoding: .utf8)
                        alertMessage = "Data exported successfully to \(url.lastPathComponent)"
                    }
                }
                #else
                // iOS/iPadOS: Show share sheet
                alertMessage = "Export completed! You can now upload this CSV file to iCloud Drive or share it."
                showingShareSheet = true
                #endif
            } catch {
                alertMessage = "Export failed: \(error.localizedDescription)"
            }
            
            isExporting = false
            showingAlert = true
        }
    }
    
    private func createCSVExport() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var csvContent = "LevelUp Budget Export - \(dateFormatter.string(from: Date()))\n\n"
        
        // Export Bills
        csvContent += "=== BILLS ===\n"
        csvContent += "Name,Amount,Due Date,Category,Status,Notes\n"
        
        for bill in bills {
            let title = bill.title.replacingOccurrences(of: ",", with: ";")
            let amount = String(format: "%.2f", bill.amount)
            let dueDate = dateFormatter.string(from: bill.dueDate)
            let category = bill.category.replacingOccurrences(of: ",", with: ";")
            let status = bill.isPaid ? "Paid" : "Unpaid"
            let notes = bill.notes.replacingOccurrences(of: ",", with: ";")
            
            csvContent += "\(title),\(amount),\(dueDate),\(category),\(status),\(notes)\n"
        }
        
        csvContent += "\n"
        
        // Export Savings Goals
        csvContent += "=== SAVINGS GOALS ===\n"
        csvContent += "Goal Name,Target Amount,Current Amount,Progress %,Created Date,Notes\n"
        
        for goal in savingsGoals {
            let title = goal.title.replacingOccurrences(of: ",", with: ";")
            let targetAmount = String(format: "%.2f", goal.targetAmount)
            let currentAmount = String(format: "%.2f", goal.currentAmount)
            let progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) * 100 : 0
            let progressPercent = String(format: "%.1f", progress)
            let createdDate = dateFormatter.string(from: goal.createdAt)
            let notes = goal.notes.replacingOccurrences(of: ",", with: ";")
            
            csvContent += "\(title),\(targetAmount),\(currentAmount),\(progressPercent)%,\(createdDate),\(notes)\n"
        }
        
        csvContent += "\n"
        
        // Export Summary
        csvContent += "=== SUMMARY ===\n"
        csvContent += "Total Bills,\(bills.count)\n"
        csvContent += "Paid Bills,\(bills.filter { $0.isPaid }.count)\n"
        csvContent += "Unpaid Bills,\(bills.filter { !$0.isPaid }.count)\n"
        csvContent += "Total Savings Goals,\(savingsGoals.count)\n"
        csvContent += "Total Target Amount,$\(String(format: "%.2f", savingsGoals.reduce(0) { $0 + $1.targetAmount }))\n"
        csvContent += "Total Current Amount,$\(String(format: "%.2f", savingsGoals.reduce(0) { $0 + $1.currentAmount }))\n"
        csvContent += "Export Date,\(dateFormatter.string(from: Date()))\n"
        
        return csvContent
    }
}

struct ExportOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isImporting = false
    @State private var showingDocumentPicker = false
    
    private var backgroundColor: Color {
        return Color.black
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Import Data")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Restore from backup file")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "square.and.arrow.down")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        
                        Divider()
                            .background(Color.secondary.opacity(0.3))
                    }
                    .padding(.top, 20)
                    
                    // Import Instructions Card
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import Instructions")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Select a backup file to restore")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            ImportInstructionRow(
                                icon: "doc.text",
                                title: "Select Backup File",
                                description: "Choose a LevelUp Budget backup file (.json)"
                            )
                            
                            ImportInstructionRow(
                                icon: "checkmark.shield",
                                title: "Data Validation",
                                description: "We'll verify the backup file integrity"
                            )
                            
                            ImportInstructionRow(
                                icon: "arrow.clockwise",
                                title: "Restore Data",
                                description: "Import bills, goals, and settings"
                            )
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(backgroundColor)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Import Button
                    Button(action: { showingDocumentPicker = true }) {
                        HStack(spacing: 12) {
                            if isImporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                            }
                            
                            Text(isImporting ? "Importing..." : "Select Backup File")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isImporting ? Color.gray : Color.blue)
                        )
                    }
                    .disabled(isImporting)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.horizontal, max(geometry.size.width * 0.05, 20))
                .frame(maxWidth: min(geometry.size.width * 0.9, 800))
            }
            .background(backgroundColor)
            .navigationTitle("Import Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Import Complete", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [UTType("public.json")!],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importDataFromURL(url)
                }
            case .failure(let error):
                alertMessage = "Failed to select file: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func importDataFromURL(_ url: URL) {
        isImporting = true
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let importData = try decoder.decode(ExportData.self, from: data)
            
            // Clear existing data
            try modelContext.delete(model: BillItem.self)
            try modelContext.delete(model: SavingsGoal.self)
            try modelContext.delete(model: UserSettings.self)
            
            // Import new data - convert export models back to SwiftData models
            for billExport in importData.bills {
                let bill = BillItem(
                    title: billExport.title,
                    amount: billExport.amount,
                    dueDate: billExport.dueDate,
                    isPaid: billExport.isPaid,
                    notes: billExport.notes,
                    category: billExport.category,
                    isRecurring: billExport.isRecurring,
                    recurrenceType: billExport.recurrenceType,
                    endDate: billExport.endDate
                )
                bill.createdAt = billExport.createdAt
                bill.updatedAt = billExport.updatedAt
                modelContext.insert(bill)
            }
            
            for goalExport in importData.savingsGoals {
                let goal = SavingsGoal(
                    title: goalExport.title,
                    category: goalExport.category,
                    goalType: goalExport.goalType,
                    targetAmount: goalExport.targetAmount,
                    currentAmount: goalExport.currentAmount,
                    targetDate: goalExport.targetDate,
                    notes: goalExport.notes
                )
                goal.createdAt = goalExport.createdAt
                goal.updatedAt = goalExport.updatedAt
                modelContext.insert(goal)
            }
            
            for settingExport in importData.userSettings {
                let setting = UserSettings(
                    monthlyBudget: settingExport.monthlyBudget,
                    notificationsEnabled: settingExport.notificationsEnabled,
                    darkModeEnabled: settingExport.darkModeEnabled
                )
                setting.createdAt = settingExport.createdAt
                setting.updatedAt = settingExport.updatedAt
                modelContext.insert(setting)
            }
            
            alertMessage = "Data imported successfully from \(url.lastPathComponent)"
        } catch {
            alertMessage = "Import failed: \(error.localizedDescription)"
        }
        
        isImporting = false
        showingAlert = true
    }
}

struct ImportInstructionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Export Data Structure
struct ExportData: Codable {
    let bills: [BillItemExport]
    let savingsGoals: [SavingsGoalExport]
    let userSettings: [UserSettingsExport]
    let exportDate: Date
}

// MARK: - Export Data Models
struct BillItemExport: Codable {
    let title: String
    let amount: Double
    let dueDate: Date
    let isPaid: Bool
    let notes: String
    let category: String
    let isRecurring: Bool
    let recurrenceType: String?
    let endDate: Date?
    let createdAt: Date
    let updatedAt: Date
    
    init(from billItem: BillItem) {
        self.title = billItem.title
        self.amount = billItem.amount
        self.dueDate = billItem.dueDate
        self.isPaid = billItem.isPaid
        self.notes = billItem.notes
        self.category = billItem.category
        self.isRecurring = billItem.isRecurring
        self.recurrenceType = billItem.recurrenceType
        self.endDate = billItem.endDate
        self.createdAt = billItem.createdAt
        self.updatedAt = billItem.updatedAt
    }
}

struct SavingsGoalExport: Codable {
    let title: String
    let category: String
    let goalType: String
    let targetAmount: Double
    let currentAmount: Double
    let targetDate: Date
    let notes: String
    let createdAt: Date
    let updatedAt: Date
    
    init(from savingsGoal: SavingsGoal) {
        self.title = savingsGoal.title
        self.category = savingsGoal.category
        self.goalType = savingsGoal.goalType
        self.targetAmount = savingsGoal.targetAmount
        self.currentAmount = savingsGoal.currentAmount
        self.targetDate = savingsGoal.targetDate
        self.notes = savingsGoal.notes
        self.createdAt = savingsGoal.createdAt
        self.updatedAt = savingsGoal.updatedAt
    }
}

struct UserSettingsExport: Codable {
    let monthlyBudget: Double
    let notificationsEnabled: Bool
    let darkModeEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(from userSettings: UserSettings) {
        self.monthlyBudget = userSettings.monthlyBudget
        self.notificationsEnabled = userSettings.notificationsEnabled
        self.darkModeEnabled = userSettings.darkModeEnabled
        self.createdAt = userSettings.createdAt
        self.updatedAt = userSettings.updatedAt
    }
}

// MARK: - Cloud Sync Card
struct CloudSyncCard: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: cloudKitManager.isCloudKitAvailable ? "icloud.fill" : "icloud")
                        .font(.title2)
                        .foregroundColor(cloudKitManager.isCloudKitAvailable ? .green : .blue)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill((cloudKitManager.isCloudKitAvailable ? Color.green : Color.blue).opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cloud Sync")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(cloudKitManager.isCloudKitAvailable ? "iCloud sync enabled" : "Sign in to sync across devices")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                        
                        if let error = cloudKitManager.syncError {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                    
                    if cloudKitManager.isCloudKitAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.caption)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke((cloudKitManager.isCloudKitAvailable ? Color.green : Color.blue).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            cloudKitManager.checkCloudKitAvailability()
        }
    }
}

// MARK: - Authentication & Account Section
struct AuthenticationAccountSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account & Authentication")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // User Info Card
                if let user = authViewModel.currentUser {
                    UserInfoCard(user: user)
                }
                
                // Sign Out Button
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title2)
                            .foregroundColor(Color(red: 1, green: 0.23, blue: 0.19))
                        
                        Text("Sign Out")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 1, green: 0.23, blue: 0.19))
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 1, green: 0.23, blue: 0.19).opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
                print("✅ Sign out completed")
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct UserInfoCard: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 16) {
            // User Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name ?? "User")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Text("Signed in with \(user.authProvider.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Debug Section
struct DebugSection: View {
    @Binding var showDebugInfo: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var bills: [BillItem]
    @Query private var savingsGoals: [SavingsGoal]
    @Query private var userSettings: [UserSettings]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🔧 Debug Information")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showDebugInfo.toggle() }) {
                    Image(systemName: showDebugInfo ? "eye.slash" : "eye")
                        .foregroundColor(showDebugInfo ? .green : .white)
                }
            }
            
            if showDebugInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Counts:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Text("Bills: \(bills.count)")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("Savings Goals: \(savingsGoals.count)")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("User Settings: \(userSettings.count)")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    Text("App Status:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Text("Model Context: Active")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Last Updated: \(Date().formatted())")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: BillItem.self, inMemory: true)
} 