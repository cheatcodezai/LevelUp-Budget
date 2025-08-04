//
//  SearchOverlayView.swift
//  LevelUp Budget
//
//  Created by DubOG on 7/21/25.
//

import SwiftUI

struct SearchOverlayView: View {
    let placeholder: String
    @Binding var searchText: String
    @Binding var isVisible: Bool
    let onDismiss: () -> Void
    
    @State private var overlayOffset: CGFloat = -200
    @State private var backgroundOpacity: Double = 0
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
            // Background overlay for tap-to-dismiss
            if isVisible {
                Color.black.opacity(0.3)
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSearch()
                    }
                    .animation(.easeInOut(duration: 0.3), value: backgroundOpacity)
            }
            
            // Search bar overlay
            VStack(spacing: 0) {
                searchBarView
                Spacer()
            }
            .offset(y: overlayOffset)
            .animation(.easeInOut(duration: 0.4), value: overlayOffset)
        }
        .onAppear {
            // Ensure search is hidden by default
            if !isVisible {
                hideSearch()
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                showSearch()
            } else {
                hideSearch()
            }
        }
        // Add gesture to dismiss on scroll
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Dismiss search if user scrolls down significantly
                    if value.translation.height > 50 {
                        dismissSearch()
                    }
                }
        )
    }
    
    private var searchBarView: some View {
        VStack(spacing: 0) {
            // Search bar container
            HStack(spacing: 12) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                
                // Search text field
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .accentColor(Color(red: 0, green: 1, blue: 0.4))
                    .focused($isSearchFocused)
                    .onSubmit {
                        dismissSearch()
                    }
                
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Cancel button
                Button("Cancel") {
                    dismissSearch()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0, green: 1, blue: 0.4).opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Divider line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.top, 8)
        }
        .background(
            Color.black.opacity(0.95)
                .ignoresSafeArea(.container, edges: .top)
        )
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
    }
    
    private func showSearch() {
        overlayOffset = 0
        backgroundOpacity = 1
        isSearchFocused = true
    }
    
    private func hideSearch() {
        overlayOffset = -200
        backgroundOpacity = 0
        isSearchFocused = false
    }
    
    private func dismissSearch() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
            searchText = ""
        }
        onDismiss()
    }
}

// MARK: - Search Overlay Manager
class SearchOverlayManager: ObservableObject {
    @Published var isSearchVisible = false
    @Published var searchText = ""
    
    func showSearch() {
        isSearchVisible = true
    }
    
    func hideSearch() {
        isSearchVisible = false
        searchText = ""
    }
    
    func reset() {
        isSearchVisible = false
        searchText = ""
    }
}

// MARK: - Floating Search Button
struct FloatingSearchButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0, green: 1, blue: 0.4))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 