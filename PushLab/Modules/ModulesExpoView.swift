//
//  ExpoView.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI

struct ExpoView: View {
    @State private var viewModel = ExpoViewModel()
    @State private var showCURLModal = false
    @State private var showTokenExtractor = false
    
    var body: some View {
        ModuleScrollContainer {
            SavedTokensList(tokenType: .expo) { token in
                if viewModel.tokens.isEmpty {
                    viewModel.tokens = token
                } else {
                    viewModel.tokens += "\n\(token)"
                }
            }
            
            FormSectionCard(
                title: "Push Tokens",
                description: "Add one ExponentPushToken per line or pull one from the simulator.",
                systemImage: "paperplane",
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
                            token: $viewModel.tokens,
                            tokenType: .expo
                        )
                    }
                }
            ) {
                TextEditor(text: $viewModel.tokens)
                    .tokenEditorSurface(minHeight: 84)
                
                FieldHint(text: "One ExponentPushToken per line.")
            }
            
            FormSectionCard(
                title: "Access Token",
                description: "Optional. Only needed when your Expo project uses an access token.",
                systemImage: "key.horizontal"
            ) {
                TextField("Bearer access token", text: $viewModel.accessToken)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
            
            FormSectionCard(
                title: "Notification Content",
                description: "Compose the visible content and delivery options for this push.",
                systemImage: "text.bubble"
            ) {
                TextField("Title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Body", text: $viewModel.body)
                    .textFieldStyle(.roundedBorder)
                
                AdaptiveFields {
                    HStack(alignment: .top, spacing: 12) {
                        priorityField
                        soundField
                        badgeField
                    }
                } compact: {
                    VStack(alignment: .leading, spacing: 12) {
                        priorityField
                        soundField
                        badgeField
                    }
                }
            }
            
            FormSectionCard(
                title: "Custom Data",
                description: "Attach extra key-value data to the payload.",
                systemImage: "curlybraces",
                actions: {
                    Button(action: viewModel.addCustomDataPair) {
                        Label("Add Field", systemImage: "plus.circle.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            ) {
                if viewModel.customDataPairs.isEmpty {
                    FieldHint(text: "No custom fields added yet.")
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.customDataPairs) { pair in
                            customDataRow(for: pair)
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
                .disabled(viewModel.isLoading || viewModel.tokens.isEmpty)
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
                if viewModel.tokens.isEmpty {
                    viewModel.tokens = token
                } else {
                    viewModel.tokens += "\n\(token)"
                }
            }
        }
    }
    
    private var priorityField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Priority")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            Picker("", selection: $viewModel.priority) {
                Text("Default").tag("default")
                Text("Normal").tag("normal")
                Text("High").tag("high")
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private func customDataRow(for pair: ExpoViewModel.KeyValuePair) -> some View {
        let keyBinding = Binding(
            get: { pair.key },
            set: { newValue in
                if let index = viewModel.customDataPairs.firstIndex(where: { $0.id == pair.id }) {
                    viewModel.customDataPairs[index].key = newValue
                }
            }
        )
        let valueBinding = Binding(
            get: { pair.value },
            set: { newValue in
                if let index = viewModel.customDataPairs.firstIndex(where: { $0.id == pair.id }) {
                    viewModel.customDataPairs[index].value = newValue
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
                
                removeCustomDataButton(for: pair.id)
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
                    
                    removeCustomDataButton(for: pair.id)
                }
            }
            .padding(10)
            .panelSurface(fill: Color(nsColor: .textBackgroundColor))
        }
    }
    
    private func removeCustomDataButton(for id: UUID) -> some View {
        Button(action: {
            if let index = viewModel.customDataPairs.firstIndex(where: { $0.id == id }) {
                viewModel.customDataPairs.remove(at: index)
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
    ExpoView()
        .frame(width: 500, height: 700)
}
