//
//  LiveActivityView.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct LiveActivityView: View {
    @State private var viewModel = LiveActivityViewModel()
    @State private var showCURLModal = false
    @State private var showTokenExtractor = false
    
    var body: some View {
        ModuleScrollContainer {
            SavedTokensList(tokenType: .liveActivity) { token in
                viewModel.activityToken = token
            }
            
            FormSectionCard(
                title: "Live Activity Token",
                description: "Use the activity token for the session you want to update or end.",
                systemImage: "waveform.badge.magnifyingglass",
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
                            token: $viewModel.activityToken,
                            tokenType: .liveActivity
                        )
                    }
                }
            ) {
                TextField("Paste Live Activity token", text: $viewModel.activityToken)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
            
            FormSectionCard(
                title: "APNs Configuration",
                description: "These credentials are used to send Live Activity events through APNs.",
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
                    Text(viewModel.p8Key.isEmpty ? "No .p8 key loaded" : ".p8 key loaded")
                        .font(.system(size: 11))
                        .foregroundStyle(viewModel.p8Key.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                    
                    Button("Load .p8 Key") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.item]
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        
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
                description: "Choose the environment and event type that should be sent.",
                systemImage: "switch.2"
            ) {
                AdaptiveFields {
                    HStack(alignment: .center, spacing: 12) {
                        Toggle("Sandbox", isOn: $viewModel.isSandbox)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Event")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            Picker("Event", selection: $viewModel.eventType) {
                                Text("Update").tag("update")
                                Text("End").tag("end")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                        }
                    }
                } compact: {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Sandbox", isOn: $viewModel.isSandbox)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Event")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            Picker("Event", selection: $viewModel.eventType) {
                                Text("Update").tag("update")
                                Text("End").tag("end")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
            }
            
            FormSectionCard(
                title: "Alert",
                description: "Optional. Include an alert alongside the Live Activity update.",
                systemImage: "bell.badge"
            ) {
                TextField("Title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Body", text: $viewModel.body)
                    .textFieldStyle(.roundedBorder)
            }
            
            FormSectionCard(
                title: "Content State",
                description: "Add the key-value state that your widget expects.",
                systemImage: "shippingbox",
                actions: {
                    Button(action: viewModel.addContentStatePair) {
                        Label("Add Field", systemImage: "plus.circle.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            ) {
                if viewModel.contentStatePairs.isEmpty {
                    FieldHint(text: "No content state fields added yet.")
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.contentStatePairs) { pair in
                            contentStateRow(for: pair)
                        }
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
                        Text("Send Update")
                            .frame(width: 110)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(viewModel.isLoading || viewModel.activityToken.isEmpty)
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
                viewModel.activityToken = token
            }
        }
    }
    
    private func contentStateRow(for pair: LiveActivityViewModel.KeyValuePair) -> some View {
        let keyBinding = Binding(
            get: { pair.key },
            set: { newValue in
                if let index = viewModel.contentStatePairs.firstIndex(where: { $0.id == pair.id }) {
                    viewModel.contentStatePairs[index].key = newValue
                }
            }
        )
        let valueBinding = Binding(
            get: { pair.value },
            set: { newValue in
                if let index = viewModel.contentStatePairs.firstIndex(where: { $0.id == pair.id }) {
                    viewModel.contentStatePairs[index].value = newValue
                }
            }
        )
        
        return AdaptiveFields {
            HStack(spacing: 8) {
                TextField("Key", text: keyBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                
                TextField("Value", text: valueBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                
                removeContentStateButton(for: pair.id)
            }
            .padding(10)
            .panelSurface(fill: Color(nsColor: .textBackgroundColor))
        } compact: {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Key", text: keyBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                
                HStack(spacing: 8) {
                    TextField("Value", text: valueBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    
                    removeContentStateButton(for: pair.id)
                }
            }
            .padding(10)
            .panelSurface(fill: Color(nsColor: .textBackgroundColor))
        }
    }
    
    private func removeContentStateButton(for id: UUID) -> some View {
        Button(action: {
            if let index = viewModel.contentStatePairs.firstIndex(where: { $0.id == id }) {
                viewModel.contentStatePairs.remove(at: index)
            }
        }) {
            Image(systemName: "trash")
                .font(.system(size: 11))
                .foregroundStyle(.red)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .help("Remove field")
    }
}

#Preview {
    LiveActivityView()
        .frame(width: 500, height: 700)
}
