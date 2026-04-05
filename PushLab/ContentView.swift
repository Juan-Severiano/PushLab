//
//  ContentView.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "paperplane.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                
                Text("PushLab")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Tab selector
            HStack(spacing: 0) {
                TabButton(
                    title: "Expo",
                    icon: "1.circle.fill",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                .keyboardShortcut("1", modifiers: .command)
                
                TabButton(
                    title: "Live Activity",
                    icon: "2.circle.fill",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                .keyboardShortcut("2", modifiers: .command)
                
                TabButton(
                    title: "APNs",
                    icon: "3.circle.fill",
                    isSelected: selectedTab == 2,
                    action: { selectedTab = 2 }
                )
                .keyboardShortcut("3", modifiers: .command)
                
                TabButton(
                    title: "FCM",
                    icon: "4.circle.fill",
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )
                .keyboardShortcut("4", modifiers: .command)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            TabView(selection: $selectedTab) {
                ExpoView()
                    .tag(0)
                
                LiveActivityView()
                    .tag(1)
                
                APNsView()
                    .tag(2)
                
                FCMView()
                    .tag(3)
            }
            .tabViewStyle(.automatic)
        }
        .frame(minWidth: 500, minHeight: 700)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedToken.self, inMemory: true)
}
