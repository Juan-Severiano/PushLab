//
//  PushLabApp.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
import SwiftData

@main
struct PushLabApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedToken.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 600, height: 800)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About PushLab") {
                    // Show about window
                }
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
