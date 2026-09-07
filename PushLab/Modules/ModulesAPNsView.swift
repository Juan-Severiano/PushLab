//
//  APNsView.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct APNsView: View {
    @State private var viewModel = APNsViewModel()
    @State private var showCURLModal = false
    @State private var showTokenExtractor = false
    
    var body: some View {
        ModuleScrollContainer {
            SavedTokensList(tokenType: .apns) { token in
                viewModel.deviceToken = token
            }
            
            FormSectionCard(
                title: "Device Token",
                description: "Paste a device token or import one captured from the simulator.",
                systemImage: "iphone.gen3",
                actions: {
                    HStack(spacing: 8) {
                        Button {
                            showTokenExtractor = true
                        } label: {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .help("Extract token from simulator")
                        
                        SaveTokenView(
                            token: $viewModel.deviceToken,
                            tokenType: .apns
                        )
                    }
                }
            ) {
                TextField("Paste device token", text: $viewModel.deviceToken)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
            
            FormSectionCard(
                title: "APNs Configuration",
                description: "Provide the topic and authentication details used to sign the request.",
                systemImage: "apple.logo"
            ) {
                TextField("Bundle ID", text: $viewModel.bundleId)
                    .textFieldStyle(.roundedBorder)
                
                AdaptiveFields {
                    HStack(spacing: 12) {
                        TextField("Team ID", text: $viewModel.teamId)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Key ID", text: $viewModel.keyId)
                            .textFieldStyle(.roundedBorder)
                    }
                } compact: {
                    VStack(spacing: 12) {
                        TextField("Team ID", text: $viewModel.teamId)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Key ID", text: $viewModel.keyId)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        if viewModel.hasKeyLoaded {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 12))
                                Text(viewModel.p8FileName)
                                    .font(.system(size: 11, design: .monospaced))
                            }
                            
                            Text("Key loaded successfully")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No .p8 key loaded")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.hasKeyLoaded {
                        Button(action: viewModel.clearP8Key) {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .help("Clear key")
                    }
                    
                    Button("Load .p8 Key") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.item]
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.message = "Select APNs authentication key (.p8 file)"
                        
                        if panel.runModal() == .OK, let url = panel.url {
                            viewModel.loadP8Key(from: url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(10)
                .panelSurface(fill: Color(nsColor: .textBackgroundColor))
            }
            
            FormSectionCard(
                title: "Delivery Settings",
                description: "Choose the APNs environment and push type before sending.",
                systemImage: "switch.2"
            ) {
                AdaptiveFields {
                    HStack(alignment: .center, spacing: 12) {
                        Toggle("Sandbox", isOn: $viewModel.isSandbox)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Push Type")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            Picker("Push Type", selection: $viewModel.pushType) {
                                Text("Alert").tag("alert")
                                Text("Background").tag("background")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                        }
                    }
                } compact: {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Sandbox", isOn: $viewModel.isSandbox)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Push Type")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            Picker("Push Type", selection: $viewModel.pushType) {
                                Text("Alert").tag("alert")
                                Text("Background").tag("background")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
            }
            
            FormSectionCard(
                title: "Notification Content",
                description: "Compose the alert shown to the user.",
                systemImage: "bell.badge"
            ) {
                TextField("Title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Subtitle", text: $viewModel.subtitle)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Body", text: $viewModel.body)
                    .textFieldStyle(.roundedBorder)
                
                AdaptiveFields {
                    HStack(alignment: .top, spacing: 12) {
                        soundField
                        badgeField
                    }
                } compact: {
                    VStack(alignment: .leading, spacing: 12) {
                        soundField
                        badgeField
                    }
                }
            }
            
            if let error = viewModel.errorMessage {
                InlineMessageCard(text: error, tone: .error)
            }
            
            if viewModel.showResponse {
                ResponsePanel(
                    status: viewModel.responseStatus,
                    json: viewModel.responseJSON,
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(viewModel.responseJSON, forType: .string)
                    }
                )
            }
            
            HStack(spacing: 12) {
                Button(action: { showCURLModal = true }) {
                    Label("Generate cURL", systemImage: "terminal")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.send()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 110)
                    } else {
                        Text("Send Push")
                            .frame(width: 110)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(viewModel.isLoading || viewModel.deviceToken.isEmpty)
            }
            .padding(14)
            .panelSurface(fill: Color(nsColor: .controlBackgroundColor))
        }
        .sheet(isPresented: $showCURLModal) {
            CURLModal(
                curlCommand: viewModel.generateCURL(),
                isPresented: $showCURLModal
            )
        }
        .sheet(isPresented: $showTokenExtractor) {
            TokenExtractorSheet { token in
                viewModel.deviceToken = token
            }
        }
    }
    
    private var soundField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sound")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            TextField("default", text: $viewModel.sound)
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var badgeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Badge")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            TextField("0", text: $viewModel.badge)
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    APNsView()
        .frame(width: 500, height: 700)
}
