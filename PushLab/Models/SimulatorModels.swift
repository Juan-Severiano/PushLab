//
//  SimulatorModels.swift
//  PushLab
//
//  Created by Francisco Juan on 05/04/26.
//

import Foundation

/// Represents an iOS Simulator device
struct SimulatorDevice: Identifiable, Hashable {
    let id: String  // UDID
    let name: String
    let state: DeviceState
    let runtime: String
    
    enum DeviceState: String {
        case booted = "Booted"
        case shutdown = "Shutdown"
        case unknown = "Unknown"
        
        init(from string: String) {
            switch string.lowercased() {
            case "booted":
                self = .booted
            case "shutdown":
                self = .shutdown
            default:
                self = .unknown
            }
        }
    }
    
    var isBooted: Bool {
        state == .booted
    }
    
    var displayName: String {
        "\(name) (\(runtime))"
    }
}

/// Represents an app installed in a simulator
struct InstalledApp: Identifiable, Hashable {
    let id: String  // Bundle ID
    let bundleId: String
    let name: String
    let path: String?
    
    init(bundleId: String, name: String, path: String? = nil) {
        self.id = bundleId
        self.bundleId = bundleId
        self.name = name
        self.path = path
    }
}

/// Represents a captured push token
struct CapturedToken: Identifiable {
    let id: UUID
    let timestamp: Date
    let type: TokenType
    let value: String
    let source: String  // App name or bundle ID
    
    enum TokenType: String {
        case apns = "APNs"
        case fcm = "FCM"
        
        var icon: String {
            switch self {
            case .apns:
                return "apple.logo"
            case .fcm:
                return "flame"
            }
        }
    }
    
    init(type: TokenType, value: String, source: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.value = value
        self.source = source
    }
    
    var truncatedValue: String {
        if value.count > 20 {
            return String(value.prefix(10)) + "..." + String(value.suffix(10))
        }
        return value
    }
}

// MARK: - JSON Parsing Models for xcrun simctl

/// Root structure for `xcrun simctl list devices --json`
struct SimctlDeviceList: Codable {
    let devices: [String: [SimctlDevice]]
}

/// Device entry from simctl JSON
struct SimctlDevice: Codable {
    let udid: String
    let name: String
    let state: String
    let isAvailable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case udid
        case name
        case state
        case isAvailable
    }
}
