//
//  ContentView.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            TabView {
                ExpoView()
                    .tabItem {
                        Label("Expo", systemImage: "paperplane")
                    }
                
                LiveActivityView()
                    .tabItem {
                        Label("Live Activity", systemImage: "waveform.badge.magnifyingglass")
                    }
                
                APNsView()
                    .tabItem {
                        Label("APNs", systemImage: "apple.logo")
                    }
                
                FCMView()
                    .tabItem {
                        Label("FCM", systemImage: "flame")
                    }
            }
            .padding(.top, 8)
        }
        .frame(minWidth: 620, minHeight: 760)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack(spacing: 14) {
            Image(systemName: "paperplane.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.blue.gradient)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("PushLab")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Organize, test, and inspect push payloads without leaving macOS.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("Native macOS")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Color(nsColor: .controlBackgroundColor),
                    in: Capsule(style: .continuous)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedToken.self, inMemory: true)
}
