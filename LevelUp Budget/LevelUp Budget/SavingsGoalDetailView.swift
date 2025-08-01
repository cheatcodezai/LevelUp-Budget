//
//  SavingsGoalDetailView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

struct SavingsGoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var contributionAmount = ""
    
    let goal: SavingsGoal
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerCard
                        detailsCard
                        contributionCard
                    }
                    .padding()
                }
            }
            .navigationTitle(goal.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                #endif
                
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
                #endif
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            SavingsGoalFormView(goal: goal)
        }
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteGoal()
            }
        } message: {
            Text("Are you sure you want to delete this savings goal?")
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(goal.notes)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(goal.currentAmount, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("of $\(goal.targetAmount, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            ProgressView(value: goal.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: goal.statusColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Details")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Target Amount")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("$\(goal.targetAmount, specifier: "%.2f")")
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Current Amount")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("$\(goal.currentAmount, specifier: "%.2f")")
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Remaining")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("$\(goal.targetAmount - goal.currentAmount, specifier: "%.2f")")
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Progress")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(goal.progress * 100))%")
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Target Date")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(goal.targetDate, style: .date)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var contributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Contribution")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                TextField("Amount", text: $contributionAmount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                
                Button("Add") {
                    addContribution()
                }
                .buttonStyle(.borderedProminent)
                .disabled(contributionAmount.isEmpty)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func addContribution() {
        guard let amount = Double(contributionAmount) else { return }
        
        goal.currentAmount += amount
        goal.updatedAt = Date()
        
        contributionAmount = ""
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving contribution: \(error)")
        }
    }
    
    private func deleteGoal() {
        modelContext.delete(goal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting goal: \(error)")
        }
    }
}

struct SavingsDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    SavingsGoalDetailView(goal: SavingsGoal(
        title: "Vacation Fund",
        category: "Travel",
        targetAmount: 5000,
        currentAmount: 2500,
        targetDate: Date().addingTimeInterval(60*60*24*30)
    ))
} 