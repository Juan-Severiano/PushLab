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
            
            TabView {
                ExpoView()
                    .tabItem {
                        Label("Expo", systemImage: "1.circle.fill")
                    }
                
                LiveActivityView()
                    .tabItem {
                        Label("Live Activity", systemImage: "2.circle.fill")
                    }
                
                APNsView()
                    .tabItem {
                        Label("APNs", systemImage: "3.circle.fill")
                    }
                
                FCMView()
                    .tabItem {
                        Label("FCM", systemImage: "4.circle.fill")
                    }
            }
        }
        .frame(minWidth: 500, minHeight: 700)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedToken.self, inMemory: true)
}
