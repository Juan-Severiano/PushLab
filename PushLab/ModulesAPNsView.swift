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
    @State private var showFilePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Saved tokens
                SavedTokensList(tokenType: .apns) { token in
                    viewModel.deviceToken = token
                }
                
                // Device token
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Device Token")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        SaveTokenView(
                            token: $viewModel.deviceToken,
                            tokenType: .apns
                        )
                    }
                    
                    TextField("", text: $viewModel.deviceToken)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }
                
                // APNs configuration
                VStack(alignment: .leading, spacing: 8) {
                    Text("APNs Configuration")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("Bundle ID", text: $viewModel.bundleId)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 12) {
                        TextField("Team ID", text: $viewModel.teamId)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Key ID", text: $viewModel.keyId)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text(viewModel.p8Key.isEmpty ? "No .p8 key loaded" : ".p8 key loaded")
                            .font(.system(size: 11))
                            .foregroundStyle(
                                viewModel.p8Key.isEmpty ? .secondary : .primary
                            )
                        
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
                }
                
                // Environment
                HStack {
                    Toggle("Sandbox", isOn: $viewModel.isSandbox)
                    
                    Spacer()
                    
                    Picker("Push Type", selection: $viewModel.pushType) {
                        Text("Alert").tag("alert")
                        Text("Background").tag("background")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                Divider()
                
                // Notification content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification Content")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Subtitle", text: $viewModel.subtitle)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Body", text: $viewModel.body)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sound")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            TextField("default", text: $viewModel.sound)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Badge")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            TextField("0", text: $viewModel.badge)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Response panel
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
                
                Divider()
                
                // Actions
                HStack {
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
                                .frame(width: 100)
                        } else {
                            Text("Send Push")
                                .frame(width: 100)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(viewModel.isLoading || viewModel.deviceToken.isEmpty)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showCURLModal) {
            CURLModal(
                curlCommand: viewModel.generateCURL(),
                isPresented: $showCURLModal
            )
        }
    }
}

#Preview {
    APNsView()
        .frame(width: 500, height: 700)
}
