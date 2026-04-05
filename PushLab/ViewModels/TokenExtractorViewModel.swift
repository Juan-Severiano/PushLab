//
//  TokenExtractorViewModel.swift
//  PushLab
//
//  Created by Francisco Juan on 05/04/26.
//

import Foundation

/// ViewModel for the Token Extractor feature
@Observable
final class TokenExtractorViewModel {
    // MARK: - State
    
    /// Available simulators
    var simulators: [SimulatorDevice] = []
    
    /// Currently selected simulator
    var selectedSimulator: SimulatorDevice? {
        didSet {
            if selectedSimulator != oldValue {
                apps = []
                selectedApp = nil
                if selectedSimulator != nil {
                    Task { await loadApps() }
                }
            }
        }
    }
    
    /// Apps installed in the selected simulator
    var apps: [InstalledApp] = []
    
    /// Currently selected app
    var selectedApp: InstalledApp?
    
    /// Tokens that have been captured
    var capturedTokens: [CapturedToken] = []
    
    /// Whether simulators are being loaded
    var isLoadingSimulators = false
    
    /// Whether apps are being loaded
    var isLoadingApps = false
    
    /// Whether log monitoring is active
    var isMonitoring = false
    
    /// Monitor APNs tokens
    var monitorAPNs = true
    
    /// Monitor FCM tokens
    var monitorFCM = true
    
    /// Current error message
    var errorMessage: String?
    
    /// Log output for debugging
    var logOutput: [String] = []
    
    // MARK: - Services
    
    private let simulatorService = SimulatorService.shared
    private let logStreamService = LogStreamService.shared
    
    // MARK: - Computed Properties
    
    /// Simulators that are currently booted
    var bootedSimulators: [SimulatorDevice] {
        simulators.filter { $0.isBooted }
    }
    
    /// Whether we can start monitoring
    var canStartMonitoring: Bool {
        selectedSimulator?.isBooted == true && !isMonitoring
    }
    
    /// Whether we have any simulators available
    var hasBootedSimulators: Bool {
        !bootedSimulators.isEmpty
    }
    
    // MARK: - Initialization
    
    init() {
        setupLogStreamCallbacks()
    }
    
    // MARK: - Public Methods
    
    /// Loads the list of available simulators
    @MainActor
    func loadSimulators() async {
        isLoadingSimulators = true
        errorMessage = nil
        
        do {
            simulators = try await simulatorService.listDevices()
            
            // Auto-select first booted simulator
            if selectedSimulator == nil {
                selectedSimulator = bootedSimulators.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingSimulators = false
    }
    
    /// Loads apps for the selected simulator
    @MainActor
    func loadApps() async {
        guard let simulator = selectedSimulator else { return }
        
        isLoadingApps = true
        errorMessage = nil
        
        do {
            apps = try await simulatorService.listApps(deviceId: simulator.id)
        } catch {
            errorMessage = error.localizedDescription
            apps = []
        }
        
        isLoadingApps = false
    }
    
    /// Starts monitoring logs for tokens
    func startMonitoring() {
        guard let simulator = selectedSimulator, simulator.isBooted else {
            errorMessage = "Please select a booted simulator"
            return
        }
        
        capturedTokens = []
        logOutput = []
        errorMessage = nil
        
        logStreamService.startMonitoring(
            deviceId: simulator.id,
            bundleId: selectedApp?.bundleId,
            monitorAPNs: monitorAPNs,
            monitorFCM: monitorFCM
        )
        
        isMonitoring = true
    }
    
    /// Stops monitoring logs
    func stopMonitoring() {
        logStreamService.stopMonitoring()
        isMonitoring = false
    }
    
    /// Clears captured tokens
    func clearTokens() {
        capturedTokens = []
    }
    
    /// Clears log output
    func clearLogs() {
        logOutput = []
    }
    
    /// Removes a specific token from the list
    func removeToken(_ token: CapturedToken) {
        capturedTokens.removeAll { $0.id == token.id }
    }
    
    // MARK: - Private Methods
    
    private func setupLogStreamCallbacks() {
        logStreamService.onTokenCaptured = { [weak self] token in
            guard let self = self else { return }
            
            // Avoid duplicates
            if !self.capturedTokens.contains(where: { $0.value == token.value }) {
                self.capturedTokens.insert(token, at: 0)
            }
        }
        
        logStreamService.onLogLine = { [weak self] line in
            guard let self = self else { return }
            
            // Keep only last 100 lines
            if self.logOutput.count > 100 {
                self.logOutput.removeFirst()
            }
            self.logOutput.append(line)
        }
    }
}
