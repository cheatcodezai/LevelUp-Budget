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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                mainContentView
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddBill = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0, green: 0.8, blue: 0.4))
                }
                .accessibilityLabel("Add new bill")
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
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredBills.enumerated()), id: \.element.id) { index, bill in
                        NavigationLink(destination: BillDetailView(bill: bill)) {
                            BillCardView(bill: bill)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Add separator between items (except for the last one)
                        if index < filteredBills.count - 1 {
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
    
    private func deleteBills(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredBills[index])
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

struct BillCardView: View {
    let bill: BillItem
    @State private var isHovered = false
    
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
                    .frame(width: 40, height: 40)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
            }
            
            // Bill Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(bill.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", bill.amount))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
                
                HStack {
                    Text(bill.category)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Spacer()
                    
                    Text(bill.dueDate, style: .date)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                }
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

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No bills found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray.opacity(0.8))
            
            Text("Add your first bill to get started")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
        
        // Sync local bills to CloudKit
        cloudKitManager.syncAllDataToCloudKit(bills: bills, savings: []) { success, error in
            if success {
                print("✅ Bills synced to CloudKit successfully")
            } else if let error = error {
                print("❌ Failed to sync bills to CloudKit: \(error.localizedDescription)")
            }
        }
        
        // Fetch bills from CloudKit (for future implementation)
        cloudKitManager.fetchBillsFromCloudKit { fetchedBills, error in
            if let error = error {
                print("❌ Failed to fetch bills from CloudKit: \(error.localizedDescription)")
            } else if let fetchedBills = fetchedBills {
                print("✅ Fetched \(fetchedBills.count) bills from CloudKit")
                // TODO: Implement merge logic for fetched bills
            }
        }
    }
}

#Preview {
    BillsListView()
        .modelContainer(for: BillItem.self, inMemory: true)
} 