//
//  SimulatorService.swift
//  PushLab
//
//  Created by Francisco Juan on 05/04/26.
//

import Foundation

/// Service for interacting with iOS Simulators via xcrun simctl
final class SimulatorService {
    static let shared = SimulatorService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Lists all available iOS simulator devices
    func listDevices() async throws -> [SimulatorDevice] {
        let output = try await executeCommand("xcrun simctl list devices --json")
        
        guard let data = output.data(using: .utf8) else {
            throw SimulatorError.invalidOutput
        }
        
        let decoder = JSONDecoder()
        let deviceList = try decoder.decode(SimctlDeviceList.self, from: data)
        
        var devices: [SimulatorDevice] = []
        
        for (runtime, simctlDevices) in deviceList.devices {
            // Extract iOS version from runtime string
            // Format: "com.apple.CoreSimulator.SimRuntime.iOS-17-4"
            let runtimeName = extractRuntimeName(from: runtime)
            
            for device in simctlDevices {
                // Skip unavailable devices
                if device.isAvailable == false {
                    continue
                }
                
                let simulatorDevice = SimulatorDevice(
                    id: device.udid,
                    name: device.name,
                    state: SimulatorDevice.DeviceState(from: device.state),
                    runtime: runtimeName
                )
                devices.append(simulatorDevice)
            }
        }
        
        // Sort: booted first, then by name
        return devices.sorted { first, second in
            if first.isBooted != second.isBooted {
                return first.isBooted
            }
            return first.name < second.name
        }
    }
    
    /// Lists all apps installed in a simulator
    func listApps(deviceId: String) async throws -> [InstalledApp] {
        let output = try await executeCommand("xcrun simctl listapps \(deviceId)")
        
        // Parse the plist-like output
        return parseAppList(output)
    }
    
    /// Gets the data container path for an app
    func getAppContainer(deviceId: String, bundleId: String) async throws -> String {
        let output = try await executeCommand("xcrun simctl get_app_container \(deviceId) \(bundleId) data")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Private Methods
    
    /// Executes a shell command and returns the output
    private func executeCommand(_ command: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
            process.standardOutput = pipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if process.terminationStatus != 0 {
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: SimulatorError.commandFailed(errorMessage))
                    return
                }
                
                guard let output = String(data: data, encoding: .utf8) else {
                    continuation.resume(throwing: SimulatorError.invalidOutput)
                    return
                }
                
                continuation.resume(returning: output)
            } catch {
                continuation.resume(throwing: SimulatorError.executionFailed(error))
            }
        }
    }
    
    /// Extracts a human-readable runtime name from the simctl runtime identifier
    private func extractRuntimeName(from runtime: String) -> String {
        // Input: "com.apple.CoreSimulator.SimRuntime.iOS-17-4"
        // Output: "iOS 17.4"
        
        let components = runtime.components(separatedBy: ".")
        guard let last = components.last else { return runtime }
        
        // "iOS-17-4" -> "iOS 17.4"
        let parts = last.components(separatedBy: "-")
        if parts.count >= 2 {
            let os = parts[0]
            let version = parts.dropFirst().joined(separator: ".")
            return "\(os) \(version)"
        }
        
        return last
    }
    
    /// Parses the output of `xcrun simctl listapps` into InstalledApp objects
    private func parseAppList(_ output: String) -> [InstalledApp] {
        var apps: [InstalledApp] = []
        
        // The output is a plist-style dictionary
        // We'll parse it line by line looking for bundle IDs and display names
        var currentBundleId: String?
        var currentName: String?
        var currentPath: String?
        
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detect start of a new app entry (bundle ID as key)
            if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\" = {") {
                // Save previous app if exists
                if let bundleId = currentBundleId {
                    let name = currentName ?? bundleId
                    apps.append(InstalledApp(bundleId: bundleId, name: name, path: currentPath))
                }
                
                // Extract new bundle ID
                let start = trimmed.index(after: trimmed.startIndex)
                if let end = trimmed.firstIndex(of: "\"", after: start) {
                    currentBundleId = String(trimmed[start..<end])
                }
                currentName = nil
                currentPath = nil
            }
            
            // Look for CFBundleDisplayName or CFBundleName
            if trimmed.contains("CFBundleDisplayName") || trimmed.contains("CFBundleName") {
                if let value = extractPlistValue(from: trimmed) {
                    currentName = value
                }
            }
            
            // Look for Path
            if trimmed.contains("Path = ") {
                if let value = extractPlistValue(from: trimmed) {
                    currentPath = value
                }
            }
        }
        
        // Don't forget the last app
        if let bundleId = currentBundleId {
            let name = currentName ?? bundleId
            apps.append(InstalledApp(bundleId: bundleId, name: name, path: currentPath))
        }
        
        // Filter out Apple system apps and sort by name
        return apps
            .filter { !$0.bundleId.hasPrefix("com.apple.") }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Extracts the value from a plist-style line like: CFBundleName = "MyApp";
    private func extractPlistValue(from line: String) -> String? {
        guard let equalsIndex = line.firstIndex(of: "=") else { return nil }
        
        let valueStart = line.index(after: equalsIndex)
        var value = String(line[valueStart...]).trimmingCharacters(in: .whitespaces)
        
        // Remove trailing semicolon
        if value.hasSuffix(";") {
            value = String(value.dropLast())
        }
        
        // Remove quotes
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        return value.isEmpty ? nil : value
    }
}

// MARK: - Errors

enum SimulatorError: LocalizedError {
    case commandFailed(String)
    case invalidOutput
    case executionFailed(Error)
    case noBootedSimulator
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .invalidOutput:
            return "Invalid output from simctl"
        case .executionFailed(let error):
            return "Execution failed: \(error.localizedDescription)"
        case .noBootedSimulator:
            return "No booted simulator found"
        }
    }
}
