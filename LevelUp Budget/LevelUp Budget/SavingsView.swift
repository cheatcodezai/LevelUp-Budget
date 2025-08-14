//
//  SavingsView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct SavingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoal.createdAt) private var savingsGoals: [SavingsGoal]
    @EnvironmentObject var tabStateManager: TabStateManager
    @State private var filterOption: SavingsFilterOption = .all
    @State private var showingAddGoal = false
    @State private var navigationPath = NavigationPath()
    
    // CloudKit integration
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    // Search overlay state
    @StateObject private var searchManager = SearchOverlayManager()
    
    enum SavingsFilterOption: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case overdue = "Overdue"
    }
    
    private var searchFiltered: [SavingsGoal] {
        if searchManager.searchText.isEmpty {
            return savingsGoals
        } else {
            return savingsGoals.filter { goal in
                goal.title.localizedCaseInsensitiveContains(searchManager.searchText) ||
                goal.notes.localizedCaseInsensitiveContains(searchManager.searchText)
            }
        }
    }
    
    private var filteredGoals: [SavingsGoal] {
        switch filterOption {
        case .all:
            return searchFiltered
        case .active:
            return searchFiltered.filter { !$0.isCompleted }
        case .completed:
            return searchFiltered.filter { $0.isCompleted }
        case .overdue:
            return searchFiltered.filter { $0.isOverdue }
        }
    }
    
    // Group savings goals by month for better organization
    private var groupedSavings: [(String, [SavingsGoal])] {
        let grouped = Dictionary(grouping: filteredGoals) { goal in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: goal.targetDate)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                mainContentView
            }
        }
        .navigationTitle("")
        .toolbar {
            // Only show add button when Savings tab is active
            if tabStateManager.currentTab == 2 {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0, green: 0.8, blue: 0.4))
                    }
                    .accessibilityLabel("Add new savings goal")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            NavigationStack {
                SavingsGoalFormView()
            }
        }
        .onAppear {
            searchManager.reset()
            
            // Safely check CloudKit availability first
            cloudKitManager.checkCloudKitAvailability()
            
            // Only sync if CloudKit is available
            if cloudKitManager.isCloudKitAvailable {
                syncWithCloudKit()
            }
        }
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            searchManager.reset()
        }
        #endif
        .onChange(of: tabStateManager.currentTab) { oldValue, newValue in
            if newValue != 2 {
                searchManager.reset()
            }
        }
        .onChange(of: tabStateManager.shouldResetNavigation) { oldValue, newValue in
            if newValue && tabStateManager.currentTab == 2 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    navigationPath = NavigationPath()
                }
                tabStateManager.resetNavigationFlag()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Computed Views
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 32) {
                logoView
                filterButtonsView
                savingsGoalsListView
            }
            .frame(maxWidth: 720, alignment: .center)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 60)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .safeAreaInset(edge: .bottom) {
            // Add padding to prevent tab bar overlap
            Color.clear.frame(height: 80)
        }
        // Removed scroll gesture since search is now persistent
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        #endif
    }
    
    private var logoView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(red: 0, green: 1, blue: 0.4).opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
            }
            
            VStack(spacing: 8) {
                Text("Savings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Track your savings goals")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var filterButtonsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(SavingsFilterOption.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.rawValue,
                        isSelected: filterOption == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            filterOption = filter
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            #if os(macOS)
            .padding(.horizontal, 40)
            #endif
            
            // Persistent search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                
                TextField("Search savings goals...", text: $searchManager.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .accentColor(Color(red: 0, green: 1, blue: 0.4))
                
                if !searchManager.searchText.isEmpty {
                    Button(action: {
                        searchManager.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var savingsGoalsListView: some View {
        Group {
            if filteredGoals.isEmpty {
                EmptySavingsView()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(groupedSavings, id: \.0) { month, monthGoals in
                        VStack(alignment: .leading, spacing: 12) {
                            // Month header
                            Text(month)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                            
                            // Savings goals for this month
                            LazyVStack(spacing: 12) {
                                ForEach(monthGoals, id: \.id) { goal in
                                    NavigationLink(destination: SavingsGoalDetailView(goal: goal)) {
                                        SavingsGoalRowView(goal: goal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Savings Goal Row View
struct SavingsGoalRowView: View {
    let goal: SavingsGoal
    @State private var isHovered = false
    @State private var isFocused = false
    
    private var progressPercentage: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(goal.currentAmount / goal.targetAmount, 1.0)
    }
    
    private var statusText: String {
        if goal.isCompleted {
            return "Complete"
        } else if goal.isOverdue {
            return "Overdue"
        } else {
            return "Active"
        }
    }
    
    private var statusColor: Color {
        if goal.isCompleted {
            return .green
        } else if goal.isOverdue {
            return .red
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Goal Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0, green: 1, blue: 0.4).opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
            }
            
            // Goal Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(String(format: "%.2f", goal.currentAmount))")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                        
                        Text("of $\(String(format: "%.2f", goal.targetAmount))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(goal.category)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(goal.targetDate, style: .date)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                ProgressView(value: progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0, green: 1, blue: 0.4)))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Status Badge
            VStack(spacing: 8) {
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isHovered || isFocused ? 
                            Color(red: 0, green: 1, blue: 0.4).opacity(0.35) : 
                            Color.clear, 
                            lineWidth: 1.5
                        )
                )
        )
        .scaleEffect(isHovered || isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered || isFocused)
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isFocused = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = false
            }
        }
    }
}



// MARK: - Empty State View
struct EmptySavingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "banknote")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No savings goals found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Add your first savings goal to get started")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - CloudKit Integration
extension SavingsView {
    /// Sync savings goals with CloudKit
    private func syncWithCloudKit() {
        // Only sync if CloudKit is available
        guard cloudKitManager.isCloudKitAvailable else {
            print("⚠️ CloudKit not available for savings sync")
            return
        }
        
        // Add safety check to prevent crashes with SwiftData
        guard !savingsGoals.isEmpty else {
            print("ℹ️ No savings goals to sync")
            return
        }
        
        // Validate savings goals before syncing
        let validSavingsGoals = savingsGoals.filter { goal in
            // Check if the goal has valid data
            return goal.title.count > 0 && goal.targetAmount > 0
        }
        
        // Sync local savings goals to CloudKit
        cloudKitManager.syncAllDataToCloudKit(bills: [], savings: validSavingsGoals) { success, error in
            if success {
                print("✅ Savings goals synced to CloudKit successfully")
            } else if let error = error {
                print("❌ Failed to sync savings goals to CloudKit: \(error.localizedDescription)")
            }
        }
        
        // Fetch savings goals from CloudKit (for future implementation)
        cloudKitManager.fetchSavingsFromCloudKit { fetchedSavings, error in
            if let error = error {
                print("❌ Failed to fetch savings goals from CloudKit: \(error.localizedDescription)")
            } else if let fetchedSavings = fetchedSavings {
                print("✅ Fetched \(fetchedSavings.count) savings goals from CloudKit")
                // TODO: Implement merge logic for fetched savings goals
            }
        }
    }
}

#Preview {
    NavigationView {
        SavingsView()
            .environmentObject(TabStateManager())
    }
    .modelContainer(for: SavingsGoal.self, inMemory: true)
} 