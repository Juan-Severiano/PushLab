//
//  TokenFileService.swift
//  PushLab
//
//  Created by Francisco Juan on 05/04/26.
//

import Foundation

/// Service for extracting push tokens from simulator app data files
final class TokenFileService {
    static let shared = TokenFileService()
    
    private init() {}
    
    // MARK: - Known Token Storage Locations
    
    /// Keys commonly used to store push tokens in UserDefaults/plists
    private let knownTokenKeys = [
        // APNs
        "deviceToken",
        "apnsToken",
        "APNsToken",
        "pushToken",
        "devicePushToken",
        "apns_token",
        "push_token",
        
        // FCM
        "fcmToken",
        "FCMToken",
        "fcm_token",
        "registrationToken",
        "GCMToken",
        "gcm_token",
        
        // Expo
        "expoToken",
        "ExpoPushToken",
        "expo_push_token",
        
        // Generic
        "notificationToken",
        "notification_token"
    ]
    
    // MARK: - Public Methods
    
    /// Extracts tokens from an app's data container
    /// - Parameters:
    ///   - deviceId: Simulator UDID
    ///   - bundleId: App bundle ID
    /// - Returns: Array of captured tokens found
    func extractTokens(deviceId: String, bundleId: String) async throws -> [CapturedToken] {
        var tokens: [CapturedToken] = []
        
        // Get app container path
        let containerPath = try await getAppContainer(deviceId: deviceId, bundleId: bundleId)
        
        // Search in common locations
        let searchPaths = [
            "\(containerPath)/Library/Preferences",
            "\(containerPath)/Library/Application Support",
            "\(containerPath)/Library/Application Support/Google",
            "\(containerPath)/Documents"
        ]
        
        for searchPath in searchPaths {
            let foundTokens = searchForTokens(in: searchPath, bundleId: bundleId)
            tokens.append(contentsOf: foundTokens)
        }
        
        // Remove duplicates
        var seen = Set<String>()
        tokens = tokens.filter { token in
            if seen.contains(token.value) {
                return false
            }
            seen.insert(token.value)
            return true
        }
        
        return tokens
    }
    
    /// Lists all apps that might have push tokens stored
    func listAppsWithPotentialTokens(deviceId: String) async throws -> [InstalledApp] {
        let allApps = try await SimulatorService.shared.listApps(deviceId: deviceId)
        
        var appsWithTokens: [InstalledApp] = []
        
        for app in allApps {
            do {
                let containerPath = try await getAppContainer(deviceId: deviceId, bundleId: app.bundleId)
                if hasTokenFiles(at: containerPath) {
                    appsWithTokens.append(app)
                }
            } catch {
                // App might not have data container, skip it
                continue
            }
        }
        
        return appsWithTokens
    }
    
    // MARK: - Private Methods
    
    private func getAppContainer(deviceId: String, bundleId: String) async throws -> String {
        return try await SimulatorService.shared.getAppContainer(deviceId: deviceId, bundleId: bundleId)
    }
    
    /// Checks if an app has files that might contain tokens
    private func hasTokenFiles(at containerPath: String) -> Bool {
        let fm = FileManager.default
        
        let checkPaths = [
            "\(containerPath)/Library/Preferences",
            "\(containerPath)/Library/Application Support/Google/FirebaseMessaging",
            "\(containerPath)/Library/Application Support/Google/FirebaseInstanceID"
        ]
        
        for path in checkPaths {
            if fm.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    /// Searches for tokens in a directory
    private func searchForTokens(in directory: String, bundleId: String) -> [CapturedToken] {
        var tokens: [CapturedToken] = []
        let fm = FileManager.default
        
        guard fm.fileExists(atPath: directory) else { return [] }
        
        // Find all plist files
        if let enumerator = fm.enumerator(atPath: directory) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".plist") {
                    let fullPath = "\(directory)/\(file)"
                    let foundTokens = extractTokensFromPlist(at: fullPath, bundleId: bundleId)
                    tokens.append(contentsOf: foundTokens)
                }
            }
        }
        
        return tokens
    }
    
    /// Extracts tokens from a plist file
    private func extractTokensFromPlist(at path: String, bundleId: String) -> [CapturedToken] {
        var tokens: [CapturedToken] = []
        
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return []
        }
        
        // Search recursively in the plist
        searchDictionary(plist, bundleId: bundleId, tokens: &tokens)
        
        return tokens
    }
    
    /// Recursively searches a dictionary for token values
    private func searchDictionary(_ dict: [String: Any], bundleId: String, tokens: inout [CapturedToken]) {
        for (key, value) in dict {
            // Check if key matches known token keys
            let isTokenKey = knownTokenKeys.contains { key.localizedCaseInsensitiveContains($0) }
            
            if let stringValue = value as? String {
                if isTokenKey {
                    // Determine token type based on key and value
                    let tokenType = determineTokenType(key: key, value: stringValue)
                    if let type = tokenType {
                        let token = CapturedToken(type: type, value: stringValue, source: bundleId)
                        tokens.append(token)
                    }
                } else if looksLikeToken(stringValue) {
                    // Found a string that looks like a token
                    let tokenType = guessTokenType(stringValue)
                    let token = CapturedToken(type: tokenType, value: stringValue, source: bundleId)
                    tokens.append(token)
                }
            } else if let nestedDict = value as? [String: Any] {
                searchDictionary(nestedDict, bundleId: bundleId, tokens: &tokens)
            } else if let array = value as? [Any] {
                for item in array {
                    if let nestedDict = item as? [String: Any] {
                        searchDictionary(nestedDict, bundleId: bundleId, tokens: &tokens)
                    }
                }
            }
        }
    }
    
    /// Determines token type based on key name and value
    private func determineTokenType(key: String, value: String) -> CapturedToken.TokenType? {
        let keyLower = key.lowercased()
        
        // Validate it looks like a token
        guard value.count >= 32 else { return nil }
        
        if keyLower.contains("fcm") || keyLower.contains("gcm") || keyLower.contains("registration") {
            return .fcm
        }
        
        if keyLower.contains("apns") || keyLower.contains("device") || keyLower.contains("push") {
            // APNs tokens are 64 hex characters
            if value.count == 64 && value.allSatisfy({ $0.isHexDigit }) {
                return .apns
            }
        }
        
        // Default based on value format
        return guessTokenType(value)
    }
    
    /// Checks if a string looks like a push token
    private func looksLikeToken(_ value: String) -> Bool {
        // APNs: 64 hex characters
        if value.count == 64 && value.allSatisfy({ $0.isHexDigit }) {
            return true
        }
        
        // FCM: 100+ characters, alphanumeric with : and -
        if value.count >= 100 && value.allSatisfy({ $0.isLetter || $0.isNumber || $0 == ":" || $0 == "-" || $0 == "_" }) {
            return true
        }
        
        // Expo: starts with ExponentPushToken
        if value.hasPrefix("ExponentPushToken") {
            return true
        }
        
        return false
    }
    
    /// Guesses token type based on value format
    private func guessTokenType(_ value: String) -> CapturedToken.TokenType {
        // APNs tokens are exactly 64 hex characters
        if value.count == 64 && value.allSatisfy({ $0.isHexDigit }) {
            return .apns
        }
        
        // Everything else is likely FCM
        return .fcm
    }
}

// MARK: - Character Extension

private extension Character {
    var isHexDigit: Bool {
        "0123456789abcdefABCDEF".contains(self)
    }
}
