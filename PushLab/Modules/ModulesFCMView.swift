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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Saved tokens
                SavedTokensList(tokenType: .fcm) { token in
                    viewModel.registrationToken = token
                }
                
                // Registration token
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("FCM Registration Token")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Button {
                            showTokenExtractor = true
                        } label: {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        .buttonStyle(.plain)
                        .help("Extract token from simulator")
                        
                        SaveTokenView(
                            token: $viewModel.registrationToken,
                            tokenType: .fcm
                        )
                    }
                    
                    TextEditor(text: $viewModel.registrationToken)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(height: 60)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Firebase Service Account
                VStack(alignment: .leading, spacing: 8) {
                    Text("Firebase Credentials")
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack {
                        if viewModel.hasCredentialsLoaded {
                            VStack(alignment: .leading, spacing: 4) {
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
                            }
                            
                            Spacer()
                            
                            Button(action: viewModel.clearCredentials) {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Clear credentials")
                        } else {
                            Text("No credentials loaded")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
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
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Server key (legacy) or OAuth Token
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server Key / OAuth Token (Optional)")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("Enter manually if not using service account", text: $viewModel.serverKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }
                
                Divider()
                
                // Notification content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification Content")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Body", text: $viewModel.body)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Android specific
                VStack(alignment: .leading, spacing: 12) {
                    Text("Android Settings")
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack(spacing: 12) {
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
                    
                    HStack(spacing: 12) {
                        TextField("Channel ID", text: $viewModel.channelId)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Sound", text: $viewModel.sound)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Color (#RRGGBB)", text: $viewModel.color)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                Divider()
                
                // Custom data
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Custom Data")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Button(action: viewModel.addDataPair) {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !viewModel.dataPairs.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.dataPairs) { pair in
                                HStack(spacing: 8) {
                                    TextField("Key", text: Binding(
                                        get: { pair.key },
                                        set: { newValue in
                                            if let index = viewModel.dataPairs.firstIndex(where: { $0.id == pair.id }) {
                                                viewModel.dataPairs[index].key = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    
                                    TextField("Value", text: Binding(
                                        get: { pair.value },
                                        set: { newValue in
                                            if let index = viewModel.dataPairs.firstIndex(where: { $0.id == pair.id }) {
                                                viewModel.dataPairs[index].value = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    
                                    Button(action: {
                                        if let index = viewModel.dataPairs.firstIndex(where: { $0.id == pair.id }) {
                                            viewModel.dataPairs.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
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
                    .disabled(viewModel.isLoading || viewModel.registrationToken.isEmpty)
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
        .sheet(isPresented: $showTokenExtractor) {
            TokenExtractorSheet { token in
                viewModel.registrationToken = token
            }
        }
    }
}

#Preview {
    FCMView()
        .frame(width: 500, height: 700)
}
