//
//  FCMView.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct FCMView: View {
    @State private var viewModel = FCMViewModel()
    @State private var showCURLModal = false
    @State private var showTokenExtractor = false
    
    var body: some View {
        ModuleScrollContainer {
            SavedTokensList(tokenType: .fcm) { token in
                viewModel.registrationToken = token
            }
            
            FormSectionCard(
                title: "FCM Registration Token",
                description: "Use the device registration token that should receive this message.",
                systemImage: "flame",
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
                            token: $viewModel.registrationToken,
                            tokenType: .fcm
                        )
                    }
                }
            ) {
                TextEditor(text: $viewModel.registrationToken)
                    .tokenEditorSurface(minHeight: 68)
            }
            
            FormSectionCard(
                title: "Firebase Credentials",
                description: "Load a service account JSON file to authorize FCM API requests.",
                systemImage: "key"
            ) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        if viewModel.hasCredentialsLoaded {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 12))
                                Text(viewModel.credentialsFileName)
                                    .font(.system(size: 11, design: .monospaced))
                            }
                            
                            Text("Project: \(viewModel.projectId)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No credentials loaded")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.hasCredentialsLoaded {
                        Button(action: viewModel.clearCredentials) {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .help("Clear credentials")
                    }
                    
                    Button("Load Service Account") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [UTType.json]
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.message = "Select Firebase service account JSON file"
                        
                        if panel.runModal() == .OK, let url = panel.url {
                            viewModel.loadServiceAccount(from: url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(10)
                .panelSurface(fill: Color(nsColor: .textBackgroundColor))
            }
            
            FormSectionCard(
                title: "Notification Content",
                description: "Set the visible title and body included in the notification payload.",
                systemImage: "bell.badge"
            ) {
                TextField("Title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Body", text: $viewModel.body)
                    .textFieldStyle(.roundedBorder)
            }
            
            FormSectionCard(
                title: "Android Settings",
                description: "Tune Android-specific delivery behavior and appearance.",
                systemImage: "gearshape.2"
            ) {
                priorityField
                
                AdaptiveFields {
                    HStack(spacing: 12) {
                        TextField("Channel ID", text: $viewModel.channelId)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Sound", text: $viewModel.sound)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Color (#RRGGBB)", text: $viewModel.color)
                            .textFieldStyle(.roundedBorder)
                    }
                } compact: {
                    VStack(spacing: 12) {
                        TextField("Channel ID", text: $viewModel.channelId)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Sound", text: $viewModel.sound)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Color (#RRGGBB)", text: $viewModel.color)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            FormSectionCard(
                title: "Custom Data",
                description: "Add extra key-value data to the FCM message.",
                systemImage: "curlybraces",
                actions: {
                    Button(action: viewModel.addDataPair) {
                        Label("Add Field", systemImage: "plus.circle.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            ) {
                if viewModel.dataPairs.isEmpty {
                    FieldHint(text: "No custom fields added yet.")
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.dataPairs) { pair in
                            dataRow(for: pair)
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
                        Text("Send Push")
                            .frame(width: 110)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(viewModel.isLoading || viewModel.registrationToken.isEmpty)
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
                viewModel.registrationToken = token
            }
        }
    }
    
    private var priorityField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Priority")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            Picker("", selection: $viewModel.priority) {
                Text("High").tag("high")
                Text("Normal").tag("normal")
            }
            .pickerStyle(.segmented)
        }
    }
    
    private func dataRow(for pair: FCMViewModel.KeyValuePair) -> some View {
        let keyBinding = Binding(
            get: { pair.key },
            set: { newValue in
                if let index = viewModel.dataPairs.firstIndex(where: { $0.id == pair.id }) {
                    viewModel.dataPairs[index].key = newValue
                }
            }
        )
        let valueBinding = Binding(
            get: { pair.value },
            set: { newValue in
                if let index = viewModel.dataPairs.firstIndex(where: { $0.id == pair.id }) {
                    viewModel.dataPairs[index].value = newValue
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
                
                removeDataButton(for: pair.id)
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
                    
                    removeDataButton(for: pair.id)
                }
            }
            .padding(10)
            .panelSurface(fill: Color(nsColor: .textBackgroundColor))
        }
    }
    
    private func removeDataButton(for id: UUID) -> some View {
        Button(action: {
            if let index = viewModel.dataPairs.firstIndex(where: { $0.id == id }) {
                viewModel.dataPairs.remove(at: index)
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
    FCMView()
        .frame(width: 500, height: 700)
}
