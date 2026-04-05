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
        // Get plist output and convert to JSON using plutil
        let output = try await executeCommand("xcrun simctl listapps \(deviceId) | plutil -convert json -o - -")
        
        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return []
        }
        
        var apps: [InstalledApp] = []
        
        for (bundleId, appInfo) in json {
            // Skip Apple system apps
            guard !bundleId.hasPrefix("com.apple.") else { continue }
            
            // Get app name from CFBundleDisplayName or CFBundleName
            let displayName = appInfo["CFBundleDisplayName"] as? String
            let bundleName = appInfo["CFBundleName"] as? String
            let name = displayName ?? bundleName ?? bundleId
            
            // Get data container path
            let dataContainer = appInfo["DataContainer"] as? String
            let path = dataContainer?.replacingOccurrences(of: "file://", with: "")
            
            let app = InstalledApp(bundleId: bundleId, name: name, path: path)
            apps.append(app)
        }
        
        // Sort by name
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
