//
//  ContentView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

class TabStateManager: ObservableObject {
    @Published var currentTab: Int = 0
    @Published var previousTab: Int = 0
    @Published var shouldResetNavigation: Bool = false
    
    func switchTab(to tab: Int) {
        guard tab != currentTab else { return }
        previousTab = currentTab
        currentTab = tab
        shouldResetNavigation = true
    }
    
    func resetNavigationFlag() {
        shouldResetNavigation = false
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BillItem.dueDate) private var bills: [BillItem]
    @StateObject private var tabStateManager = TabStateManager()
    
    private var navigationTitle: String {
        switch tabStateManager.currentTab {
        case 0: return "Dashboard"
        case 1: return "Bills"
        case 2: return "Savings"
        case 3: return "Settings"
        default: return "LevelUp Budget"
        }
    }
    
    var body: some View {
        NavigationStack {
            #if os(iOS)
            // iOS/iPadOS layout - standard TabView with bottom tab bar
            TabView(selection: $tabStateManager.currentTab) {
                MainDashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                BillsListView()
                    .tabItem {
                        Label("Bills", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                SavingsView()
                    .tabItem {
                        Label("Savings", systemImage: "banknote.fill")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            .accentColor(Color(red: 0, green: 1, blue: 0.4))
            .environmentObject(tabStateManager)
            .onChange(of: tabStateManager.currentTab) { oldValue, newValue in
                tabStateManager.switchTab(to: newValue)
            }
            .onAppear {
                // Configure tab bar appearance immediately for iOS/iPadOS
                #if os(iOS)
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.black
                
                // All states use white text/icons for consistency
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.white
                ]
                
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.white
                ]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
                #endif
                
                // Ensure initial tab state is correct
                DispatchQueue.main.async {
                    tabStateManager.currentTab = 0
                }
            }
            #else
            // macOS layout - standard TabView
            TabView(selection: $tabStateManager.currentTab) {
                MainDashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                BillsListView()
                    .tabItem {
                        Label("Bills", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                SavingsView()
                    .tabItem {
                        Label("Savings", systemImage: "banknote.fill")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            .accentColor(Color(red: 0, green: 1, blue: 0.4))
            .environmentObject(tabStateManager)
            .onChange(of: tabStateManager.currentTab) { oldValue, newValue in
                tabStateManager.switchTab(to: newValue)
            }
            #endif
        }
    }
}



struct MainDashboardView: View {
    @Query(sort: \BillItem.dueDate) private var bills: [BillItem]
    @Query private var userSettings: [UserSettings]
    @State private var currentQuoteIndex = 0
    
    private var settings: UserSettings {
        if let existingSettings = userSettings.first {
            return existingSettings
        } else {
            return UserSettings() // Return default settings if none exist
        }
    }
    
    private let motivationalQuotes = [
        "Level up your finances, one bill at a time! 💪",
        "Budgeting is like a video game - every dollar saved is XP gained! 🎮",
        "Your future self will thank your present self for this budget! 🚀",
        "Money talks, but budgets scream success! 📢",
        "Saving money is the ultimate power move! ⚡",
        "Budgeting: because ramen noodles aren't a retirement plan! 🍜",
        "Every penny saved is a step toward financial freedom! 🦅",
        "Your bank account is your best friend - treat it well! 💚",
        "Budgeting: the art of telling your money where to go! 🎯",
        "Financial goals are just dreams with deadlines! ⏰",
        "Smart money management is the real flex! 💎",
        "Building wealth one budget at a time! 🏗️"
    ]
    
    var totalBills: Double {
        bills.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var paidBills: Double {
        bills.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var budgetProgress: Double {
        guard settings.monthlyIncome > 0 else { return 0 }
        return min(totalBills / settings.monthlyIncome, 1.0)
    }
    
    var isOverBudget: Bool {
        totalBills > settings.monthlyIncome
    }
    
    var upcomingBills: [BillItem] {
        bills.filter { bill in
            !bill.isPaid && bill.dueDate >= Date()
        }.sorted { $0.dueDate < $1.dueDate }
    }
    
    var overdueBills: [BillItem] {
        bills.filter { $0.isOverdue }
    }
    
    var body: some View {
        ZStack {
            // Dark background (#000000)
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Centered Logo and Brand
                    VStack(spacing: 20) {
                        // Custom Logo: Green rounded square with arrow
                        ZStack {
                            // Green rounded square outline
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0, green: 1, blue: 0.4), lineWidth: 2)
                                .frame(width: 70, height: 70)
                            
                            // Upward-right arrow inside square
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                        }
                        .shadow(color: Color(red: 0, green: 1, blue: 0.4).opacity(0.3), radius: 15)
                        
                        // Brand Text with enhanced styling
                        VStack(spacing: 6) {
                            HStack(spacing: 0) {
                                Text("LEVEL")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                                
                                Text("UP")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                            }
                            
                            Text("BUDGET")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }
                        
                        Text(motivationalQuotes[currentQuoteIndex])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .frame(maxWidth: 600)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Budget Progress Card
                    BudgetProgressCard(
                        totalBills: totalBills,
                        paidBills: paidBills,
                        monthlyIncome: settings.monthlyIncome,
                        progress: budgetProgress,
                        isOverBudget: isOverBudget
                    )
                    .frame(maxWidth: 800)
                    
                    // Bills Summary Section
                    BillsSummarySection(bills: bills)
                        .frame(maxWidth: 800)
                    
                    // Upcoming Bills Section
                    if !upcomingBills.isEmpty {
                        UpcomingBillsSection(bills: upcomingBills)
                            .frame(maxWidth: 800)
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 24)
            }
            .safeAreaInset(edge: .bottom) {
                // Add padding to prevent tab bar overlap
                Color.clear.frame(height: 80)
            }
        }
        .navigationTitle("")
        .toolbar {
            // Removed duplicate plus button - individual views have their own functional plus buttons
        }
        .onAppear {
            // Rotate quote every hour
            let hour = Calendar.current.component(.hour, from: Date())
            currentQuoteIndex = hour % motivationalQuotes.count
        }
    }
}

struct BudgetProgressCard: View {
    let totalBills: Double
    let paidBills: Double
    let monthlyIncome: Double
    let progress: Double
    let isOverBudget: Bool
    
    private var remainingAmount: Double {
        return monthlyIncome - totalBills
    }
    
    private var percentageSpent: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (totalBills / monthlyIncome) * 100
    }
    
    private var remainingColor: Color {
        let remainingPercentage = 100 - percentageSpent
        if remainingPercentage > 50 {
            return .green
        } else if remainingPercentage > 25 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        #if os(macOS)
        // macOS: Use the new health bar style
        HealthBarBudgetCard(
            totalBills: totalBills,
            monthlyIncome: monthlyIncome,
            isOverBudget: isOverBudget
        )
        #else
        // iOS: Keep the existing implementation
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("$\(String(format: "%.2f", totalBills)) of $\(String(format: "%.2f", monthlyIncome))")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isOverBudget ? Color(red: 1, green: 0.23, blue: 0.19) : .white)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: isOverBudget ? Color(red: 1, green: 0.23, blue: 0.19) : Color(red: 0, green: 1, blue: 0.4)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("💰 Remaining Balance")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", remainingAmount)) left to spend")
                        .font(.subheadline.bold())
                        .foregroundColor(remainingColor)
                }
                
                Text("You've used \(String(format: "%.1f", percentageSpent))% of your $\(String(format: "%.2f", monthlyIncome)) income")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
        #endif
    }
}

// MARK: - Health Bar Budget Card (macOS)
struct HealthBarBudgetCard: View {
    let totalBills: Double
    let monthlyIncome: Double
    let isOverBudget: Bool
    
    private var remainingAmount: Double {
        return max(0, monthlyIncome - totalBills)
    }
    
    private var percentageUsed: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (totalBills / monthlyIncome) * 100
    }
    
    private var percentageRemaining: Double {
        return max(0, 100 - percentageUsed)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Income")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("$\(String(format: "%.2f", totalBills)) of $\(String(format: "%.2f", monthlyIncome))")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                Text("You've used \(Int(percentageUsed))% of your income")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isOverBudget ? Color(red: 1, green: 0.23, blue: 0.19) : .white)
                    .multilineTextAlignment(.trailing)
            }
            
            // Health Bar: Green (remaining) on left, Red (spent) on right
            BudgetProgressBar(
                spent: totalBills,
                total: monthlyIncome
            )
            .frame(height: 20)
            
            // Remaining balance section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("💰 Remaining Balance")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", remainingAmount)) left to spend")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(red: 0, green: 0.9, blue: 0.5))
                }
                
                Text("$\(String(format: "%.2f", remainingAmount)) available for additional expenses")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Budget Progress Bar Component
struct BudgetProgressBar: View {
    let spent: Double
    let total: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar with subtle gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                
                HStack(spacing: 0) {
                    // Green bar: Remaining portion (left-aligned)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0, green: 0.8, blue: 0.4),
                                    Color(red: 0, green: 0.9, blue: 0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(0, geometry.size.width * CGFloat((total - spent) / total)), height: 20)
                        .shadow(color: Color(red: 0, green: 0.8, blue: 0.4).opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // Red bar: Spent portion (grows from right-to-left)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1, green: 0.3, blue: 0.2),
                                    Color(red: 1, green: 0.2, blue: 0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(0, geometry.size.width * CGFloat(spent / total)), height: 20)
                        .shadow(color: Color(red: 1, green: 0.3, blue: 0.2).opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: 20)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.4), value: spent)
        }
        .frame(height: 20)
    }
}

struct BillsSummarySection: View {
    let bills: [BillItem]
    @State private var selectedFilter: BillFilter? = nil
    
    enum BillFilter: String, CaseIterable {
        case total = "Total Bills"
        case paid = "Paid This Month"
        case overdue = "Overdue"
        case upcoming = "Upcoming"
    }
    
    var totalBills: Double {
        bills.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var paidBills: Double {
        bills.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var overdueCount: Int {
        bills.filter { $0.isOverdue }.count
    }
    
    var upcomingCount: Int {
        bills.filter { !$0.isPaid && $0.daysUntilDue >= 0 && $0.daysUntilDue <= 30 }.count
    }
    
    var filteredBills: [BillItem] {
        guard let filter = selectedFilter else { return [] }
        
        switch filter {
        case .total:
            return bills.filter { !$0.isPaid }
        case .paid:
            return bills.filter { $0.isPaid }
        case .overdue:
            return bills.filter { $0.isOverdue }
        case .upcoming:
            return bills.filter { !$0.isPaid && $0.daysUntilDue >= 0 && $0.daysUntilDue <= 30 }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bills Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Bills",
                    value: String(format: "%.2f", totalBills),
                    icon: "dollarsign.circle.fill",
                    color: Color.green.opacity(0.75),
                    isSelected: selectedFilter == .total
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = selectedFilter == .total ? nil : .total
                    }
                }
                
                StatCard(
                    title: "Paid This Month",
                    value: String(format: "%.2f", paidBills),
                    icon: "checkmark.circle.fill",
                    color: Color.green.opacity(0.75),
                    isSelected: selectedFilter == .paid
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = selectedFilter == .paid ? nil : .paid
                    }
                }
                
                StatCard(
                    title: "Overdue",
                    value: "\(overdueCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    isSelected: selectedFilter == .overdue
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = selectedFilter == .overdue ? nil : .overdue
                    }
                }
                
                StatCard(
                    title: "Upcoming",
                    value: "\(upcomingCount)",
                    icon: "clock.fill",
                    color: .orange,
                    isSelected: selectedFilter == .upcoming
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = selectedFilter == .upcoming ? nil : .upcoming
                    }
                }
            }
            
            // Filtered Bills List
            if let selectedFilter = selectedFilter {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedFilter.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Clear") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.selectedFilter = nil
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color.green.opacity(0.75))
                    }
                    
                    if filteredBills.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.6))
                            
                            Text("No \(selectedFilter.rawValue.lowercased()) found")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredBills) { bill in
                                FilteredBillRow(bill: bill)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
    }
}

struct UpcomingBillsSection: View {
    let bills: [BillItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                
                Text("Upcoming Bills")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(bills.prefix(5)) { bill in
                    UpcomingBillRow(bill: bill)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
    }
}

struct UpcomingBillRow: View {
    let bill: BillItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(bill.statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(bill.category)
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(bill.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text(bill.formattedDueDate)
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilteredBillRow: View {
    let bill: BillItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(bill.statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bill.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(bill.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text(bill.category)
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(dueDateText)
                        .font(.caption)
                        .foregroundColor(dueDateColor)
                }
            }
            
            if bill.isPaid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var dueDateText: String {
        if bill.isPaid {
            return "Paid"
        } else if bill.isOverdue {
            return "Overdue"
        } else if bill.daysUntilDue == 0 {
            return "Due today"
        } else if bill.daysUntilDue == 1 {
            return "Due tomorrow"
        } else {
            return bill.formattedDueDate
        }
    }
    
    private var dueDateColor: Color {
        if bill.isPaid {
            return .green
        } else if bill.isOverdue {
            return .red
        } else if bill.daysUntilDue <= 3 {
            return .orange
        } else {
            return .gray.opacity(0.8)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BillItem.self, inMemory: true)
}
