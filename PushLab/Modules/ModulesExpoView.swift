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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Saved tokens
                SavedTokensList(tokenType: .expo) { token in
                    if viewModel.tokens.isEmpty {
                        viewModel.tokens = token
                    } else {
                        viewModel.tokens += "\n\(token)"
                    }
                }
                
                // Token input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Push Tokens")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        SaveTokenView(
                            token: $viewModel.tokens,
                            tokenType: .expo
                        )
                    }
                    
                    TextEditor(text: $viewModel.tokens)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    Text("One ExponentPushToken per line")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                // Access token (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access Token (Optional)")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("", text: $viewModel.accessToken)
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
                    
                    HStack(spacing: 12) {
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
                
                Divider()
                
                // Custom data
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Custom Data")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Button(action: viewModel.addCustomDataPair) {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !viewModel.customDataPairs.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.customDataPairs) { pair in
                                HStack(spacing: 8) {
                                    TextField("Key", text: Binding(
                                        get: { pair.key },
                                        set: { newValue in
                                            if let index = viewModel.customDataPairs.firstIndex(where: { $0.id == pair.id }) {
                                                viewModel.customDataPairs[index].key = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    
                                    TextField("Value", text: Binding(
                                        get: { pair.value },
                                        set: { newValue in
                                            if let index = viewModel.customDataPairs.firstIndex(where: { $0.id == pair.id }) {
                                                viewModel.customDataPairs[index].value = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    
                                    Button(action: {
                                        if let index = viewModel.customDataPairs.firstIndex(where: { $0.id == pair.id }) {
                                            viewModel.customDataPairs.remove(at: index)
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
                    .disabled(viewModel.isLoading || viewModel.tokens.isEmpty)
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
    ExpoView()
        .frame(width: 500, height: 700)
}
