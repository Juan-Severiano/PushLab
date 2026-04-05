//
//  SettingsView.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
                
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .help("Automatically start PushLab when you log in")
            } header: {
                Text("General")
            }
            
            Section {
                Picker("Default environment", selection: $settings.defaultEnvironment) {
                    Text("Sandbox").tag("sandbox")
                    Text("Production").tag("production")
                }
                .help("Default APNs environment for new pushes")
            } header: {
                Text("Push Notifications")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About PushLab")
                        .font(.headline)
                    
                    Text("Version 1.0.0 (MVP)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Native macOS app for testing push notifications")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button("Reset All Settings") {
                        settings.reset()
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingsView()
}
