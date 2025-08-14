//
//  PrivacyPolicyView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
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
                            Text("Privacy Policy")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Last updated: August 5, 2025")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 20)
                        
                        // Privacy content
                        VStack(alignment: .leading, spacing: 20) {
                            PrivacySection(
                                title: "1. Information We Collect",
                                content: "LevelUp Budget collects and stores your financial data locally on your device. This includes bill information, savings goals, budget settings, and app preferences. We do not collect, store, or transmit your personal financial information to our servers."
                            )
                            
                            PrivacySection(
                                title: "2. How We Use Your Information",
                                content: "Your financial data is used solely to provide the app's core functionality: tracking bills, managing savings goals, and displaying financial insights. We do not use your data for advertising, analytics, or any other commercial purposes."
                            )
                            
                            PrivacySection(
                                title: "3. Data Storage and Security",
                                content: "All your financial data is stored locally on your device using secure, encrypted storage. If you have iCloud enabled, your data may be synced to your personal iCloud account for backup and cross-device synchronization. We have no access to your iCloud data."
                            )
                            
                            PrivacySection(
                                title: "4. Third-Party Services",
                                content: "We use Firebase for authentication services. Firebase may collect basic device information and authentication data as outlined in their privacy policy. We also use CloudKit for iCloud synchronization, which is governed by Apple's privacy policies."
                            )
                            
                            PrivacySection(
                                title: "5. Data Sharing",
                                content: "We do not share, sell, or rent your personal information to third parties. Your financial data remains private and is only accessible to you through your device and iCloud account."
                            )
                            
                            PrivacySection(
                                title: "6. Data Retention",
                                content: "Your data is retained as long as you use the app and is stored on your device. If you delete the app, your local data will be removed. iCloud data will be retained according to your iCloud settings."
                            )
                            
                            PrivacySection(
                                title: "7. Your Rights",
                                content: "You have full control over your data. You can view, edit, or delete your financial information within the app. You can also export your data or request deletion of your account at any time."
                            )
                            
                            PrivacySection(
                                title: "8. Children's Privacy",
                                content: "LevelUp Budget is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal information, please contact us."
                            )
                            
                            PrivacySection(
                                title: "9. Changes to This Policy",
                                content: "We may update this Privacy Policy from time to time. We will notify you of any material changes by updating the 'Last updated' date above. Continued use of the app after changes constitutes acceptance of the updated policy."
                            )
                            
                            PrivacySection(
                                title: "10. Contact Us",
                                content: "If you have any questions about this Privacy Policy or our data practices, please contact us through the app's feedback section."
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
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            )
            #endif
        }
    }
}

struct PrivacySection: View {
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
    PrivacyPolicyView()
}
