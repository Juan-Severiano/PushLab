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
                capturedTokens = []
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
    
    /// Whether tokens are being extracted
    var isExtracting = false
    
    /// Current error message
    var errorMessage: String?
    
    // MARK: - Services
    
    private let simulatorService = SimulatorService.shared
    private let tokenFileService = TokenFileService.shared
    
    // MARK: - Computed Properties
    
    /// Simulators that are currently booted
    var bootedSimulators: [SimulatorDevice] {
        simulators.filter { $0.isBooted }
    }
    
    /// Whether we can extract tokens
    var canExtract: Bool {
        selectedSimulator?.isBooted == true && selectedApp != nil && !isExtracting
    }
    
    /// Whether we have any simulators available
    var hasBootedSimulators: Bool {
        !bootedSimulators.isEmpty
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
    
    /// Extracts tokens from the selected app's data files
    @MainActor
    func extractTokens() async {
        guard let simulator = selectedSimulator,
              let app = selectedApp else {
            errorMessage = "Please select a simulator and app"
            return
        }
        
        isExtracting = true
        errorMessage = nil
        capturedTokens = []
        
        do {
            let tokens = try await tokenFileService.extractTokens(
                deviceId: simulator.id,
                bundleId: app.bundleId
            )
            
            if tokens.isEmpty {
                errorMessage = "No tokens found in app data. The app may not have registered for push notifications yet."
            } else {
                capturedTokens = tokens
            }
        } catch {
            errorMessage = "Failed to extract tokens: \(error.localizedDescription)"
        }
        
        isExtracting = false
    }
    
    /// Clears captured tokens
    func clearTokens() {
        capturedTokens = []
    }
    
    /// Removes a specific token from the list
    func removeToken(_ token: CapturedToken) {
        capturedTokens.removeAll { $0.id == token.id }
    }
}
