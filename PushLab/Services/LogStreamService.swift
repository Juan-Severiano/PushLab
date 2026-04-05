//
//  LogStreamService.swift
//  PushLab
//
//  Created by Francisco Juan on 05/04/26.
//

import Foundation

/// Service for monitoring simulator logs in real-time to capture push tokens
@Observable
final class LogStreamService {
    static let shared = LogStreamService()
    
    private var process: Process?
    private var outputPipe: Pipe?
    private var isRunning = false
    
    /// Callback when a token is captured
    var onTokenCaptured: ((CapturedToken) -> Void)?
    
    /// Callback for log lines (for debugging)
    var onLogLine: ((String) -> Void)?
    
    private init() {}
    
    // MARK: - Token Patterns
    
    /// Regex patterns for detecting push tokens
    private enum TokenPattern {
        /// APNs device token: 64 hexadecimal characters
        static let apns = try! NSRegularExpression(
            pattern: "(?:device[\\s_-]?token|APNs[\\s_-]?token|token)[:\\s=]+[\"']?([a-fA-F0-9]{64})[\"']?",
            options: [.caseInsensitive]
        )
        
        /// APNs token as raw hex without label
        static let apnsRaw = try! NSRegularExpression(
            pattern: "<([a-fA-F0-9]{8} [a-fA-F0-9]{8} [a-fA-F0-9]{8} [a-fA-F0-9]{8} [a-fA-F0-9]{8} [a-fA-F0-9]{8} [a-fA-F0-9]{8} [a-fA-F0-9]{8})>",
            options: []
        )
        
        /// FCM registration token: typically starts with specific patterns
        static let fcm = try! NSRegularExpression(
            pattern: "(?:FCM[\\s_-]?token|registration[\\s_-]?token|fcmToken)[:\\s=]+[\"']?([a-zA-Z0-9:_-]{100,})[\"']?",
            options: [.caseInsensitive]
        )
        
        /// Generic long token pattern (fallback)
        static let genericToken = try! NSRegularExpression(
            pattern: "(?:push[\\s_-]?token|notification[\\s_-]?token)[:\\s=]+[\"']?([a-zA-Z0-9:_-]{32,})[\"']?",
            options: [.caseInsensitive]
        )
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring logs for a specific simulator and app
    /// - Parameters:
    ///   - deviceId: Simulator UDID
    ///   - bundleId: App bundle ID (optional, monitors all if nil)
    ///   - monitorAPNs: Whether to look for APNs tokens
    ///   - monitorFCM: Whether to look for FCM tokens
    func startMonitoring(
        deviceId: String,
        bundleId: String? = nil,
        monitorAPNs: Bool = true,
        monitorFCM: Bool = true
    ) {
        guard !isRunning else { return }
        
        stopMonitoring()
        
        // Build the log stream command
        var predicates: [String] = []
        
        if let bundleId = bundleId {
            predicates.append("processImagePath CONTAINS '\(bundleId)'")
        }
        
        // Add token-related predicates
        var tokenPredicates: [String] = []
        if monitorAPNs {
            tokenPredicates.append("eventMessage CONTAINS[c] 'token'")
            tokenPredicates.append("eventMessage CONTAINS[c] 'APNs'")
            tokenPredicates.append("eventMessage CONTAINS[c] 'device token'")
        }
        if monitorFCM {
            tokenPredicates.append("eventMessage CONTAINS[c] 'FCM'")
            tokenPredicates.append("eventMessage CONTAINS[c] 'registration'")
        }
        
        if !tokenPredicates.isEmpty {
            let tokenPredicate = "(\(tokenPredicates.joined(separator: " OR ")))"
            if !predicates.isEmpty {
                predicates.append(tokenPredicate)
            } else {
                predicates = [tokenPredicate]
            }
        }
        
        let predicateArg = predicates.isEmpty ? "" : " --predicate '\(predicates.joined(separator: " AND "))'"
        let command = "xcrun simctl spawn \(deviceId) log stream --level=debug\(predicateArg)"
        
        process = Process()
        outputPipe = Pipe()
        
        process?.executableURL = URL(fileURLWithPath: "/bin/bash")
        process?.arguments = ["-c", command]
        process?.standardOutput = outputPipe
        process?.standardError = outputPipe
        
        // Handle output asynchronously
        outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let output = String(data: data, encoding: .utf8) else { return }
            
            self?.processLogOutput(
                output,
                source: bundleId ?? "Unknown",
                monitorAPNs: monitorAPNs,
                monitorFCM: monitorFCM
            )
        }
        
        do {
            try process?.run()
            isRunning = true
        } catch {
            print("Failed to start log monitoring: \(error)")
            stopMonitoring()
        }
    }
    
    /// Stops the current log monitoring session
    func stopMonitoring() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        
        if process?.isRunning == true {
            process?.terminate()
        }
        
        process = nil
        outputPipe = nil
        isRunning = false
    }
    
    /// Checks if monitoring is currently active
    var isMonitoring: Bool {
        isRunning && process?.isRunning == true
    }
    
    // MARK: - Private Methods
    
    /// Processes log output and extracts tokens
    private func processLogOutput(
        _ output: String,
        source: String,
        monitorAPNs: Bool,
        monitorFCM: Bool
    ) {
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            guard !line.isEmpty else { continue }
            
            // Notify about the log line
            DispatchQueue.main.async { [weak self] in
                self?.onLogLine?(line)
            }
            
            // Try to extract tokens
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            
            if monitorAPNs {
                // Try APNs pattern
                if let match = TokenPattern.apns.firstMatch(in: line, options: [], range: range),
                   let tokenRange = Range(match.range(at: 1), in: line) {
                    let token = String(line[tokenRange])
                    captureToken(type: .apns, value: token, source: source)
                }
                
                // Try raw APNs pattern (with spaces)
                if let match = TokenPattern.apnsRaw.firstMatch(in: line, options: [], range: range),
                   let tokenRange = Range(match.range(at: 1), in: line) {
                    let rawToken = String(line[tokenRange])
                    let token = rawToken.replacingOccurrences(of: " ", with: "")
                    captureToken(type: .apns, value: token, source: source)
                }
            }
            
            if monitorFCM {
                // Try FCM pattern
                if let match = TokenPattern.fcm.firstMatch(in: line, options: [], range: range),
                   let tokenRange = Range(match.range(at: 1), in: line) {
                    let token = String(line[tokenRange])
                    captureToken(type: .fcm, value: token, source: source)
                }
            }
            
            // Try generic token pattern
            if let match = TokenPattern.genericToken.firstMatch(in: line, options: [], range: range),
               let tokenRange = Range(match.range(at: 1), in: line) {
                let token = String(line[tokenRange])
                // Determine type based on token characteristics
                let type: CapturedToken.TokenType = token.count == 64 && token.allSatisfy({ $0.isHexDigit }) ? .apns : .fcm
                if (type == .apns && monitorAPNs) || (type == .fcm && monitorFCM) {
                    captureToken(type: type, value: token, source: source)
                }
            }
        }
    }
    
    /// Creates and emits a captured token
    private func captureToken(type: CapturedToken.TokenType, value: String, source: String) {
        let token = CapturedToken(type: type, value: value, source: source)
        
        DispatchQueue.main.async { [weak self] in
            self?.onTokenCaptured?(token)
        }
    }
}

// MARK: - Character Extension

private extension Character {
    var isHexDigit: Bool {
        "0123456789abcdefABCDEF".contains(self)
    }
}
