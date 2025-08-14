//
//  BillsListView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData

struct BillsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BillItem.dueDate) private var bills: [BillItem]
    @EnvironmentObject var tabStateManager: TabStateManager
    @State private var selectedFilter: BillFilter = .all
    @State private var showingAddBill = false
    @State private var showingFilterSheet = false
    @State private var navigationPath = NavigationPath()
    
    // CloudKit integration
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    // Search overlay state
    @StateObject private var searchManager = SearchOverlayManager()
    
    enum BillFilter: String, CaseIterable {
        case all = "All"
        case unpaid = "Unpaid"
        case paid = "Paid"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
    }
    
    private var searchFiltered: [BillItem] {
        if searchManager.searchText.isEmpty {
            return bills
        } else {
            return bills.filter { bill in
                bill.title.localizedCaseInsensitiveContains(searchManager.searchText) ||
                bill.category.localizedCaseInsensitiveContains(searchManager.searchText) ||
                bill.notes.localizedCaseInsensitiveContains(searchManager.searchText)
            }
        }
    }
    
    private var filteredBills: [BillItem] {
        switch selectedFilter {
        case .all:
            return searchFiltered
        case .unpaid:
            return searchFiltered.filter { !$0.isPaid }
        case .paid:
            return searchFiltered.filter { $0.isPaid }
        case .overdue:
            return searchFiltered.filter { $0.isOverdue }
        case .dueSoon:
            return searchFiltered.filter { !$0.isPaid && $0.daysUntilDue > 0 && $0.daysUntilDue <= 7 }
        }
    }
    
    // Group bills by month for better organization
    private var groupedBills: [(String, [BillItem])] {
        let grouped = Dictionary(grouping: filteredBills) { bill in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: bill.dueDate)
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
            // Only show add button when Bills tab is active
            if tabStateManager.currentTab == 1 {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddBill = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0, green: 0.8, blue: 0.4))
                    }
                    .accessibilityLabel("Add new bill")
                }
            }
        }
        .sheet(isPresented: $showingAddBill) {
            NavigationStack {
                BillFormView()
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
            if newValue != 1 {
                searchManager.reset()
            }
        }
        .onChange(of: tabStateManager.shouldResetNavigation) { oldValue, newValue in
            if newValue && tabStateManager.currentTab == 1 {
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
                billsListView
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
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
            }
            
            VStack(spacing: 8) {
                Text("Bills")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Manage your bills and payments")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var filterButtonsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(BillFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedFilter = filter
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
                
                TextField("Search bills...", text: $searchManager.searchText)
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
    
    private var billsListView: some View {
        Group {
            if filteredBills.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(groupedBills, id: \.0) { month, monthBills in
                        VStack(alignment: .leading, spacing: 12) {
                            // Month header
                            Text(month)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                            
                            // Bills for this month
                            LazyVStack(spacing: 12) {
                                ForEach(monthBills, id: \.id) { bill in
                                    NavigationLink(destination: BillDetailView(bill: bill)) {
                                        BillRowView(bill: bill)
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
    
    private func deleteBills(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredBills[index])
            }
        }
    }
}

// MARK: - Bill Row View
struct BillRowView: View {
    let bill: BillItem
    @State private var isHovered = false
    @State private var isFocused = false
    
    private var statusText: String {
        if bill.isPaid {
            return "Paid"
        } else if bill.isOverdue {
            return "Overdue"
        } else if bill.daysUntilDue <= 3 && bill.daysUntilDue > 0 {
            return "\(bill.daysUntilDue) days left"
        } else {
            return "Due"
        }
    }
    
    private var statusColor: Color {
        if bill.isPaid {
            return .green
        } else if bill.isOverdue {
            return .red
        } else if bill.daysUntilDue <= 3 && bill.daysUntilDue > 0 {
            return .orange
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Bill Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0, green: 1, blue: 0.4).opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
            }
            
            // Bill Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(bill.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", bill.amount))")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
                
                HStack {
                    Text(bill.category)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(bill.dueDate, style: .date)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(red: 0, green: 1, blue: 0.4) : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No bills found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Add your first bill to get started")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - CloudKit Integration
extension BillsListView {
    /// Sync bills with CloudKit
    private func syncWithCloudKit() {
        // Only sync if CloudKit is available
        guard cloudKitManager.isCloudKitAvailable else {
            print("⚠️ CloudKit not available for bills sync")
            return
        }
        
        // Add safety check to prevent crashes with SwiftData
        guard !bills.isEmpty else {
            print("ℹ️ No bills to sync")
            return
        }
        
        // Validate bills before syncing
        let validBills = bills.filter { bill in
            // Check if the bill has valid data
            return bill.title.count > 0 && bill.amount > 0
        }
        
        // Sync local bills to CloudKit
        cloudKitManager.syncAllDataToCloudKit(bills: validBills, savings: []) { success, error in
            if success {
                print("✅ Bills synced to CloudKit successfully")
            } else if let error = error {
                print("❌ Failed to sync bills to CloudKit: \(error.localizedDescription)")
            }
        }
        
        // Fetch and merge bills from CloudKit (macOS only) - DISABLED TO PREVENT LOOP
        #if os(macOS)
        // Temporarily disabled to prevent infinite sync loop
        // cloudKitManager.fetchAllDataFromCloudKit { fetchedBills, fetchedSavings, error in
        //     if let error = error {
        //         print("❌ Failed to fetch bills from CloudKit: \(error.localizedDescription)")
        //     } else if let fetchedBills = fetchedBills {
        //         print("✅ Fetched \(fetchedBills.count) bills from CloudKit")
        //         // TODO: Implement merge logic for fetched bills
        //     }
        // }
        #endif
    }
}

#Preview {
    BillsListView()
        .modelContainer(for: BillItem.self, inMemory: true)
} 