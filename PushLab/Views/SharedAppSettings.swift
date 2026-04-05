//
//  AppSettings.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
internal import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // App preferences
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    @Published var showMenuBarIcon: Bool {
        didSet { UserDefaults.standard.set(showMenuBarIcon, forKey: "showMenuBarIcon") }
    }
    @Published var defaultEnvironment: String {
        didSet { UserDefaults.standard.set(defaultEnvironment, forKey: "defaultEnvironment") }
    }

    // Last used values (for convenience)
    @Published var lastExpoAccessToken: String {
        didSet { UserDefaults.standard.set(lastExpoAccessToken, forKey: "lastExpoAccessToken") }
    }
    @Published var lastAPNsBundleId: String {
        didSet { UserDefaults.standard.set(lastAPNsBundleId, forKey: "lastAPNsBundleId") }
    }
    @Published var lastAPNsTeamId: String {
        didSet { UserDefaults.standard.set(lastAPNsTeamId, forKey: "lastAPNsTeamId") }
    }
    @Published var lastAPNsKeyId: String {
        didSet { UserDefaults.standard.set(lastAPNsKeyId, forKey: "lastAPNsKeyId") }
    }
    @Published var lastFCMProjectId: String {
        didSet { UserDefaults.standard.set(lastFCMProjectId, forKey: "lastFCMProjectId") }
    }

    private init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.showMenuBarIcon = UserDefaults.standard.bool(forKey: "showMenuBarIcon") == true || UserDefaults.standard.object(forKey: "showMenuBarIcon") == nil
        self.defaultEnvironment = UserDefaults.standard.string(forKey: "defaultEnvironment") ?? "sandbox"
        self.lastExpoAccessToken = UserDefaults.standard.string(forKey: "lastExpoAccessToken") ?? ""
        self.lastAPNsBundleId = UserDefaults.standard.string(forKey: "lastAPNsBundleId") ?? ""
        self.lastAPNsTeamId = UserDefaults.standard.string(forKey: "lastAPNsTeamId") ?? ""
        self.lastAPNsKeyId = UserDefaults.standard.string(forKey: "lastAPNsKeyId") ?? ""
        self.lastFCMProjectId = UserDefaults.standard.string(forKey: "lastFCMProjectId") ?? ""
    }

    func reset() {
        launchAtLogin = false
        showMenuBarIcon = true
        defaultEnvironment = "sandbox"
        lastExpoAccessToken = ""
        lastAPNsBundleId = ""
        lastAPNsTeamId = ""
        lastAPNsKeyId = ""
        lastFCMProjectId = ""
    }
}
