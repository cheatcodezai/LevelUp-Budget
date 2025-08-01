//
//  FormComponents.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI

// MARK: - Form Components
struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.top, 20)
            
            content
        }
        .padding(24)
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

struct FormField<Content: View>: View {
    let icon: String
    let iconColor: Color
    let label: String
    let placeholder: String
    let content: Content
    
    init(icon: String, iconColor: Color, label: String, placeholder: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.placeholder = placeholder
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.16))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Toggle Field Component
struct FormToggleField: View {
    let icon: String
    let iconColor: Color
    let label: String
    let subtitle: String?
    @Binding var isOn: Bool
    let toggleColor: Color
    
    init(icon: String, iconColor: Color, label: String, subtitle: String? = nil, isOn: Binding<Bool>, toggleColor: Color = .green) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.subtitle = subtitle
        self._isOn = isOn
        self.toggleColor = toggleColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: toggleColor))
                .labelsHidden()
                .scaleEffect(0.9)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Action Buttons
struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let isEnabled: Bool
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, isEnabled: Bool, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? color : Color.gray.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEnabled ? color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.gray.opacity(0.8))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Form Background
struct FormBackground: View {
    var body: some View {
        Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
    }
}

// MARK: - Form Container
struct FormContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            FormBackground()
            
            ScrollView {
                VStack(spacing: 32) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.07, green: 0.07, blue: 0.07))
        }
    }
} 