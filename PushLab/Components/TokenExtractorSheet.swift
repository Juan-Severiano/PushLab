//
//  TokenExtractorSheet.swift
//  PushLab
//
//  Created by Francisco Juan on 05/04/26.
//

import SwiftUI

/// Sheet for extracting push tokens from iOS simulators
struct TokenExtractorSheet: View {
    @State private var viewModel = TokenExtractorViewModel()
    
    /// Callback when a token is selected
    let onTokenSelected: (String) -> Void
    
    /// Dismiss action
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Simulator Selection
                    simulatorSection
                    
                    // App Selection
                    if viewModel.selectedSimulator != nil {
                        appSection
                    }
                    
                    // Monitoring Controls
                    if viewModel.selectedSimulator?.isBooted == true {
                        monitoringSection
                    }
                    
                    // Captured Tokens
                    if !viewModel.capturedTokens.isEmpty {
                        tokensSection
                    }
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        errorView(error)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 500, height: 600)
        .task {
            await viewModel.loadSimulators()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Token Extractor")
                    .font(.headline)
                Text("Extract push tokens from iOS Simulator")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Simulator Section
    
    private var simulatorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Step 1: Select Simulator", systemImage: "iphone")
                .font(.subheadline.weight(.semibold))
            
            HStack {
                if viewModel.isLoadingSimulators {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading simulators...")
                        .foregroundStyle(.secondary)
                } else if viewModel.bootedSimulators.isEmpty {
                    Label("No booted simulators found", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else {
                    Picker("Simulator", selection: $viewModel.selectedSimulator) {
                        Text("Select a simulator").tag(nil as SimulatorDevice?)
                        ForEach(viewModel.bootedSimulators) { device in
                            Text(device.displayName).tag(device as SimulatorDevice?)
                        }
                    }
                    .labelsHidden()
                }
                
                Spacer()
                
                Button {
                    Task { await viewModel.loadSimulators() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoadingSimulators)
                .help("Refresh simulators")
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - App Section
    
    private var appSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Step 2: Select App (Optional)", systemImage: "app")
                .font(.subheadline.weight(.semibold))
            
            Text("Filter logs by a specific app, or monitor all apps")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if viewModel.isLoadingApps {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading apps...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.apps.isEmpty {
                Text("No third-party apps installed")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                Picker("App", selection: $viewModel.selectedApp) {
                    Text("All apps").tag(nil as InstalledApp?)
                    ForEach(viewModel.apps) { app in
                        Text("\(app.name) (\(app.bundleId))")
                            .tag(app as InstalledApp?)
                    }
                }
                .labelsHidden()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Monitoring Section
    
    private var monitoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Step 3: Monitor Logs", systemImage: "waveform")
                .font(.subheadline.weight(.semibold))
            
            // Token type toggles
            HStack(spacing: 16) {
                Toggle("APNs", isOn: $viewModel.monitorAPNs)
                Toggle("FCM", isOn: $viewModel.monitorFCM)
            }
            .disabled(viewModel.isMonitoring)
            
            HStack {
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isMonitoring ? Color.red : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isMonitoring ? "Monitoring..." : "Idle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Control buttons
                if viewModel.isMonitoring {
                    Button("Stop") {
                        viewModel.stopMonitoring()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button("Start Monitoring") {
                        viewModel.startMonitoring()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canStartMonitoring || (!viewModel.monitorAPNs && !viewModel.monitorFCM))
                }
            }
            
            // Instructions
            if viewModel.isMonitoring {
                Text("💡 Now open your app in the simulator and trigger a push token registration")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Tokens Section
    
    private var tokensSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Captured Tokens (\(viewModel.capturedTokens.count))", systemImage: "key.fill")
                    .font(.subheadline.weight(.semibold))
                
                Spacer()
                
                Button("Clear") {
                    viewModel.clearTokens()
                }
                .font(.caption)
            }
            
            ForEach(viewModel.capturedTokens) { token in
                TokenCaptureRow(token: token) {
                    onTokenSelected(token.value)
                    dismiss()
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Text("Tokens are captured from simulator logs")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
        }
        .padding()
    }
}

// MARK: - Token Capture Row

struct TokenCaptureRow: View {
    let token: CapturedToken
    let onUse: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: token.type.icon)
                .foregroundStyle(token.type == .apns ? .blue : .orange)
                .frame(width: 20)
            
            // Token info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(token.type.rawValue)
                        .font(.caption.weight(.semibold))
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(token.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(token.truncatedValue)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Actions
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(token.value, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.plain)
            .help("Copy token")
            
            Button("Use") {
                onUse()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(8)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Preview

#Preview {
    TokenExtractorSheet { token in
        print("Selected: \(token)")
    }
}
