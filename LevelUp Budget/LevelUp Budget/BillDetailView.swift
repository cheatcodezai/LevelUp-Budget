//
//  BillDetailView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

struct BillDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    let bill: BillItem
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 24) {
                        headerCard
                        detailsCard
                        actionsCard
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Bill Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white)
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white)
                }
            }
            #endif
        }
        .sheet(isPresented: $showingEditSheet) {
            BillFormView(bill: bill)
        }
        .alert("Delete Bill", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteBill()
            }
        } message: {
            Text("Are you sure you want to delete this bill? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(bill.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(bill.category)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(bill.formattedAmount)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(bill.isPaid ? "Paid" : "Unpaid")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(bill.isPaid ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
                .background(Color.gray)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(bill.dueDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(bill.isOverdue ? "Overdue" : "On Time")
                        .font(.subheadline)
                        .foregroundColor(bill.isOverdue ? .red : .green)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Details Card
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                detailRow(title: "Amount", value: bill.formattedAmount)
                detailRow(title: "Category", value: bill.category)
                detailRow(title: "Due Date", value: bill.dueDate, style: .short)
                detailRow(title: "Recurring", value: bill.isRecurring ? "Yes" : "No")
                
                if bill.isRecurring {
                    detailRow(title: "Recurrence", value: bill.recurrenceType ?? "None")
                    if let endDate = bill.endDate {
                        detailRow(title: "End Date", value: endDate, style: .short)
                    }
                }
                
                if !bill.notes.isEmpty {
                    detailRow(title: "Notes", value: bill.notes)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(spacing: 16) {
            Text("Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Bill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    togglePaymentStatus()
                }) {
                    HStack {
                        Image(systemName: bill.isPaid ? "xmark.circle" : "checkmark.circle")
                        Text(bill.isPaid ? "Mark as Unpaid" : "Mark as Paid")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(bill.isPaid ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Bill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
    
    private func detailRow(title: String, value: Date, style: DateFormatter.Style) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value, style: .date)
                .foregroundColor(.white)
        }
    }
    
    private func togglePaymentStatus() {
        bill.isPaid.toggle()
        try? modelContext.save()
    }
    
    private func deleteBill() {
        modelContext.delete(bill)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationView {
        BillDetailView(bill: BillItem(
            title: "Rent",
            amount: 1200.0,
            dueDate: Date().addingTimeInterval(86400 * 5),
            isPaid: false,
            notes: "Monthly rent payment",
            category: "Housing"
        ))
    }
    .modelContainer(for: BillItem.self, inMemory: true)
}