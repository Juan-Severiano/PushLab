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
            "\(containerPath)/Library/Application Support/Google/FirebaseMessaging",
            "\(containerPath)/Documents"
        ]
        
        for searchPath in searchPaths {
            let foundTokens = searchForTokens(in: searchPath, bundleId: bundleId)
            tokens.append(contentsOf: foundTokens)
        }
        
        // Also check Firebase-specific storage files
        let firebaseTokens = extractFirebaseTokens(containerPath: containerPath, bundleId: bundleId)
        tokens.append(contentsOf: firebaseTokens)
        
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
    
    /// Extracts FCM tokens from Firebase-specific storage locations
    private func extractFirebaseTokens(containerPath: String, bundleId: String) -> [CapturedToken] {
        var tokens: [CapturedToken] = []
        let fm = FileManager.default
        
        // Firebase stores FCM token in a checkin file or installations plist
        let firebasePaths = [
            "\(containerPath)/Library/Application Support/Google/FirebaseMessaging/FIRMessagingStore.plist",
            "\(containerPath)/Library/Preferences/\(bundleId).plist",
            "\(containerPath)/Library/Application Support/FirebaseInstallations.plist"
        ]
        
        for path in firebasePaths {
            guard fm.fileExists(atPath: path),
                  let data = fm.contents(atPath: path),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
                continue
            }
            
            // Look for FCM token keys used by Firebase SDK
            let fcmKeys = ["fcm_token", "token", "FCMToken", "default_token", "messaging_token"]
            
            for key in fcmKeys {
                if let tokenValue = findValueForKey(key, in: plist) {
                    if let stringToken = tokenValue as? String, looksLikeToken(stringToken) {
                        tokens.append(CapturedToken(type: .fcm, value: stringToken, source: bundleId))
                    } else if let dataToken = tokenValue as? Data,
                              let stringToken = String(data: dataToken, encoding: .utf8),
                              looksLikeToken(stringToken) {
                        tokens.append(CapturedToken(type: .fcm, value: stringToken, source: bundleId))
                    }
                }
            }
        }
        
        return tokens
    }
    
    /// Recursively finds a value for a key in nested dictionaries
    private func findValueForKey(_ targetKey: String, in dict: [String: Any]) -> Any? {
        for (key, value) in dict {
            if key.localizedCaseInsensitiveContains(targetKey) {
                return value
            }
            if let nestedDict = value as? [String: Any] {
                if let found = findValueForKey(targetKey, in: nestedDict) {
                    return found
                }
            }
        }
        return nil
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
            
            // Handle String values
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
            }
            // Handle Data values (Firebase often stores tokens as binary data)
            else if let dataValue = value as? Data {
                // Try to convert Data to String (UTF-8)
                if let stringValue = String(data: dataValue, encoding: .utf8), !stringValue.isEmpty {
                    if isTokenKey || looksLikeToken(stringValue) {
                        let tokenType = isTokenKey ? determineTokenType(key: key, value: stringValue) : guessTokenType(stringValue)
                        if let type = tokenType ?? (looksLikeToken(stringValue) ? guessTokenType(stringValue) : nil) {
                            let token = CapturedToken(type: type, value: stringValue, source: bundleId)
                            tokens.append(token)
                        }
                    }
                }
                // Try hex encoding for APNs device tokens (stored as raw bytes)
                else if isTokenKey && dataValue.count == 32 {
                    let hexToken = dataValue.map { String(format: "%02x", $0) }.joined()
                    let token = CapturedToken(type: .apns, value: hexToken, source: bundleId)
                    tokens.append(token)
                }
            }
            // Handle nested dictionaries
            else if let nestedDict = value as? [String: Any] {
                searchDictionary(nestedDict, bundleId: bundleId, tokens: &tokens)
            }
            // Handle arrays
            else if let array = value as? [Any] {
                for item in array {
                    if let nestedDict = item as? [String: Any] {
                        searchDictionary(nestedDict, bundleId: bundleId, tokens: &tokens)
                    } else if let stringValue = item as? String, looksLikeToken(stringValue) {
                        let tokenType = guessTokenType(stringValue)
                        let token = CapturedToken(type: tokenType, value: stringValue, source: bundleId)
                        tokens.append(token)
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
