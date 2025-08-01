//
//  DynamicAppIcon.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI

struct DynamicAppIcon {
    enum IconStyle {
        case `default`
        case premium
        case dark
        
        var backgroundColors: [Color] {
            switch self {
            case .default:
                return [Color.blue, Color.indigo]
            case .premium:
                return [Color.purple, Color.pink]
            case .dark:
                return [Color.gray.opacity(0.1), Color.gray.opacity(0.2)]
            }
        }
        
        var primaryColor: Color {
            switch self {
            case .default:
                return Color.blue
            case .premium:
                return Color.purple
            case .dark:
                return Color.gray
            }
        }
    }
}

// MARK: - SwiftUI Icon View
struct AppIconView: View {
    let size: CGFloat
    let style: DynamicAppIcon.IconStyle
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: style.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main icon circle
            Circle()
                .fill(style.primaryColor)
                .frame(width: size * 0.6, height: size * 0.6)
                .overlay(
                    Text("$")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )
            
            // Accent elements
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size * 0.1, height: size * 0.1)
                        .offset(x: size * 0.15, y: -size * 0.15)
                }
                Spacer()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        .shadow(color: .black.opacity(0.1), radius: size * 0.05, x: 0, y: size * 0.02)
    }
}

// MARK: - Icon Generator for Different Sizes
struct IconGenerator {
    static let standardSizes: [CGFloat] = [
        20,    // Notification
        29,    // Settings
        40,    // Spotlight
        60,    // iPhone
        76,    // iPad
        83.5,  // iPad Pro
        1024   // App Store
    ]
    
    static func generateAllIcons(style: DynamicAppIcon.IconStyle = .default) -> [String: AppIconView] {
        var icons: [String: AppIconView] = [:]
        
        for size in standardSizes {
            let icon = AppIconView(size: size, style: style)
            let key = "\(Int(size))x\(Int(size))"
            icons[key] = icon
        }
        
        return icons
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AppIconView(size: 60, style: .default)
            AppIconView(size: 60, style: .premium)
            AppIconView(size: 60, style: .dark)
        }
        
        Text("LevelUp Budget Icons")
            .font(.headline)
    }
    .padding()
} 