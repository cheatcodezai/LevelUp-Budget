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
                
                // Cleanup duplicates button
                ToolbarItem(placement: .secondaryAction) {
                    Button(action: {
                        Task {
                            await cloudKitManager.cleanupDuplicates(
                                bills: [], // Empty array since we're only cleaning savings
                                savings: savingsGoals,
                                modelContext: modelContext
                            )
                        }
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .accessibilityLabel("Clean up duplicate savings goals")
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
            
            // Only sync if CloudKit is available - with delay to prevent crashes
            if cloudKitManager.isCloudKitAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    syncWithCloudKit()
                }
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
            .frame(maxWidth: 600, alignment: .center)
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
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0, green: 1, blue: 0.4), lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
            }
            .shadow(color: Color(red: 0, green: 1, blue: 0.4).opacity(0.3), radius: 12)
            
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
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredGoals.enumerated()), id: \.element.id) { index, goal in
                        NavigationLink(destination: SavingsGoalDetailView(goal: goal)) {
                            SavingsGoalCardView(goal: goal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Add separator between items (except for the last one)
                        if index < filteredGoals.count - 1 {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.leading, 72) // Align with content, not icon
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct SavingsFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color(red: 0, green: 1, blue: 0.4) : .white.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color(red: 0, green: 1, blue: 0.4).opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct SavingsGoalCardView: View {
    let goal: SavingsGoal
    @State private var isHovered = false
    
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
                    .frame(width: 40, height: 40)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
            }
            
            // Goal Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", goal.currentAmount))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
                
                HStack {
                    Text(goal.category)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Spacer()
                    
                    Text("of $\(String(format: "%.2f", goal.targetAmount))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                // Progress Bar with proper spacing
                VStack(spacing: 6) {
                    HStack {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Spacer()
                    }
                    
                    // Indented progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 6)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(red: 0, green: 1, blue: 0.4))
                                .frame(width: geometry.size.width * progressPercentage, height: 6)
                                .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 4) // Slight indentation
                }
                .padding(.top, 8)
            }
            
            // Pill-style Status Indicator
            VStack(spacing: 6) {
                Text(statusText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E equivalent
                .overlay(
                    // Faint top divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1)
                        .offset(y: -0.5),
                    alignment: .top
                )
                .overlay(
                    // Soft green border on hover
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHovered ? Color(red: 0, green: 1, blue: 0.5).opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: isHovered ? Color(red: 0, green: 1, blue: 0.5).opacity(0.3) : Color.black.opacity(0.1), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

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
        
        // Fetch and merge savings goals from CloudKit (macOS only) - DISABLED TO PREVENT LOOP
        #if os(macOS)
        // Temporarily disabled to prevent infinite sync loop
        // cloudKitManager.fetchAllDataFromCloudKit { fetchedBills, fetchedSavings, error in
        //     if let error = error {
        //         print("❌ Failed to fetch data from CloudKit: \(error.localizedDescription)")
        //     } else {
        //         // Merge fetched data with local data
        //         cloudKitManager.mergeCloudKitData(
        //             fetchedBills: fetchedBills,
        //             fetchedSavings: fetchedSavings,
        //             localBills: [],
        //             localSavings: savingsGoals,
        //             modelContext: modelContext
        //         ) { success, error in
        //             if success {
        //                 print("✅ CloudKit data merged successfully")
        //             } else if let error = error {
        //                 print("❌ Failed to merge CloudKit data: \(error.localizedDescription)")
        //             }
        //         }
        //     }
        // }
        #endif
    }
}

#Preview {
    SavingsView()
        .modelContainer(for: SavingsGoal.self, inMemory: true)
} 