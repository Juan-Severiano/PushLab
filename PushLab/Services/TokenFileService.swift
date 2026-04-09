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

        // FIRMessagingStore.plist: Firebase Messaging stores the FCM registration token here.
        // The structure uses composite keys like "{bundleId}|*|{firebaseAppId}" → token string.
        // We do a deep scan of all string values rather than relying on key names.
        let messagingStorePath = "\(containerPath)/Library/Application Support/Google/FirebaseMessaging/FIRMessagingStore.plist"
        if fm.fileExists(atPath: messagingStorePath),
           let data = fm.contents(atPath: messagingStorePath),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            extractFCMTokensFromDict(plist, into: &tokens, source: bundleId)
        }

        // App's UserDefaults plist: Firebase Messaging caches the token here under
        // keys like "com.google.firebase.messaging|registration-token-values|{senderId}"
        let bundlePlistPath = "\(containerPath)/Library/Preferences/\(bundleId).plist"
        if fm.fileExists(atPath: bundlePlistPath),
           let data = fm.contents(atPath: bundlePlistPath),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            extractFirebaseTokensFromUserDefaults(plist, into: &tokens, source: bundleId)
        }

        // NOTE: FirebaseInstallations.plist is intentionally NOT searched here —
        // it contains Firebase Installation auth tokens (bearer tokens for Firebase API),
        // not FCM registration tokens.

        return tokens
    }

    /// Deep-scans a Firebase Messaging plist dict for FCM token strings.
    /// Firebase uses composite keys (e.g. "com.example|*|1:123:ios:abc") so we check values, not keys.
    private func extractFCMTokensFromDict(_ dict: [String: Any], into tokens: inout [CapturedToken], source: String) {
        for (_, value) in dict {
            if let stringValue = value as? String, looksLikeFCMToken(stringValue) {
                tokens.append(CapturedToken(type: .fcm, value: stringValue, source: source))
            } else if let nestedDict = value as? [String: Any] {
                extractFCMTokensFromDict(nestedDict, into: &tokens, source: source)
            }
        }
    }

    /// Scans UserDefaults plist for Firebase Messaging token cache entries.
    /// Firebase stores them under keys prefixed with "com.google.firebase.messaging".
    private func extractFirebaseTokensFromUserDefaults(_ dict: [String: Any], into tokens: inout [CapturedToken], source: String) {
        for (key, value) in dict {
            guard key.lowercased().contains("com.google.firebase.messaging") ||
                  key.lowercased().contains("firinstanceid") else { continue }

            // Value may be the token string directly, or a nested dict with a "token" key
            if let stringValue = value as? String, looksLikeFCMToken(stringValue) {
                tokens.append(CapturedToken(type: .fcm, value: stringValue, source: source))
            } else if let nestedDict = value as? [String: Any] {
                if let tokenString = nestedDict["token"] as? String, looksLikeFCMToken(tokenString) {
                    tokens.append(CapturedToken(type: .fcm, value: tokenString, source: source))
                }
            }
        }
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
    
    /// Recursively searches a dictionary for token values using known key names.
    /// FCM tokens are NOT detected here — they come from extractFirebaseTokens which
    /// knows the correct Firebase storage structure. This avoids false positives.
    private func searchDictionary(_ dict: [String: Any], bundleId: String, tokens: inout [CapturedToken]) {
        for (key, value) in dict {
            let isTokenKey = knownTokenKeys.contains { key.localizedCaseInsensitiveContains($0) }

            if let stringValue = value as? String {
                if isTokenKey {
                    let tokenType = determineTokenType(key: key, value: stringValue)
                    if let type = tokenType {
                        tokens.append(CapturedToken(type: type, value: stringValue, source: bundleId))
                    }
                } else if looksLikeToken(stringValue) {
                    // Only catch APNs (64 hex) and Expo tokens as catch-all
                    // FCM catch-all removed to avoid false positives with Firebase internals
                    let type = guessTokenType(stringValue)
                    if type == .apns {
                        tokens.append(CapturedToken(type: type, value: stringValue, source: bundleId))
                    }
                }
            } else if let dataValue = value as? Data {
                if let stringValue = String(data: dataValue, encoding: .utf8), !stringValue.isEmpty, isTokenKey {
                    if let type = determineTokenType(key: key, value: stringValue) {
                        tokens.append(CapturedToken(type: type, value: stringValue, source: bundleId))
                    }
                } else if isTokenKey && dataValue.count == 32 {
                    // APNs device token stored as raw 32 bytes
                    let hexToken = dataValue.map { String(format: "%02x", $0) }.joined()
                    tokens.append(CapturedToken(type: .apns, value: hexToken, source: bundleId))
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
    
    /// Checks if a string looks like a push token (APNs or Expo)
    private func looksLikeToken(_ value: String) -> Bool {
        // APNs: exactly 64 hex characters
        if value.count == 64 && value.allSatisfy({ $0.isHexDigit }) {
            return true
        }

        // Expo: starts with ExponentPushToken
        if value.hasPrefix("ExponentPushToken") {
            return true
        }

        return false
    }

    /// Checks if a string looks like a real FCM registration token.
    /// FCM tokens are 140–200+ chars, alphanumeric with limited special chars.
    /// This is stricter than `looksLikeToken` to avoid false positives with
    /// Firebase internal auth tokens / installation tokens.
    private func looksLikeFCMToken(_ value: String) -> Bool {
        // FCM tokens are at least 140 characters
        guard value.count >= 140 else { return false }

        // Only alphanumeric, colon, hyphen, underscore — no dots (rules out JWTs)
        guard value.allSatisfy({ $0.isLetter || $0.isNumber || $0 == ":" || $0 == "-" || $0 == "_" }) else {
            return false
        }

        // Must contain at least one colon or start with a known FCM pattern
        // Old format: "APA91b..." or contains ":" separator
        // New format: long random alphanumeric string
        return true
    }

    /// Guesses token type based on value format
    private func guessTokenType(_ value: String) -> CapturedToken.TokenType {
        // APNs tokens are exactly 64 hex characters
        if value.count == 64 && value.allSatisfy({ $0.isHexDigit }) {
            return .apns
        }
        return .fcm
    }
}

// MARK: - Character Extension

private extension Character {
    var isHexDigit: Bool {
        "0123456789abcdefABCDEF".contains(self)
    }
}
