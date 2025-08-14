//
//  TermsOfServiceView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Terms of Service")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Last updated: August 5, 2025")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 20)
                        
                        // Terms content
                        VStack(alignment: .leading, spacing: 20) {
                            TermsSection(
                                title: "1. Acceptance of Terms",
                                content: "By downloading, installing, or using the LevelUp Budget app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app."
                            )
                            
                            TermsSection(
                                title: "2. Description of Service",
                                content: "LevelUp Budget is a personal finance management application that helps users track bills, manage savings goals, and monitor their financial progress. The app provides tools for budgeting, bill reminders, and financial planning."
                            )
                            
                            TermsSection(
                                title: "3. User Responsibilities",
                                content: "You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You agree to provide accurate and complete information when using the app."
                            )
                            
                            TermsSection(
                                title: "4. Data and Privacy",
                                content: "Your financial data is stored locally on your device and may be synced to iCloud if you have iCloud enabled. We do not have access to your personal financial information. Please review our Privacy Policy for more details."
                            )
                            
                            TermsSection(
                                title: "5. Prohibited Uses",
                                content: "You may not use the app for any unlawful purpose or in any way that could damage, disable, overburden, or impair the app. You may not attempt to gain unauthorized access to any systems or networks."
                            )
                            
                            TermsSection(
                                title: "6. Disclaimer of Warranties",
                                content: "The app is provided 'as is' without warranties of any kind. We do not guarantee that the app will be error-free or uninterrupted, or that defects will be corrected."
                            )
                            
                            TermsSection(
                                title: "7. Limitation of Liability",
                                content: "In no event shall we be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of the app."
                            )
                            
                            TermsSection(
                                title: "8. Changes to Terms",
                                content: "We reserve the right to modify these terms at any time. We will notify users of any material changes by updating the 'Last updated' date above."
                            )
                            
                            TermsSection(
                                title: "9. Contact Information",
                                content: "If you have any questions about these Terms of Service, please contact us through the app's feedback section."
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
            }
            #elseif os(macOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                }
            }
            .overlay(
                // Fallback dismiss button for macOS in case toolbar doesn't work
                VStack {
                    HStack {
                        Spacer()
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            )
            #endif
        }
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    TermsOfServiceView()
}
