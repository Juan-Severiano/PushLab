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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Saved tokens
                SavedTokensList(tokenType: .liveActivity) { token in
                    viewModel.activityToken = token
                }
                
                // Activity token
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Live Activity Token")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        SaveTokenView(
                            token: $viewModel.activityToken,
                            tokenType: .liveActivity
                        )
                    }
                    
                    TextField("", text: $viewModel.activityToken)
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
                
                // Environment & Event Type
                HStack {
                    Toggle("Sandbox", isOn: $viewModel.isSandbox)
                    
                    Spacer()
                    
                    Picker("Event", selection: $viewModel.eventType) {
                        Text("Update").tag("update")
                        Text("End").tag("end")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                Divider()
                
                // Alert content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Alert (Optional)")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Body", text: $viewModel.body)
                        .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                // Content State
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Content State")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Button(action: viewModel.addContentStatePair) {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !viewModel.contentStatePairs.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.contentStatePairs) { pair in
                                HStack(spacing: 8) {
                                    TextField("Key", text: Binding(
                                        get: { pair.key },
                                        set: { newValue in
                                            if let index = viewModel.contentStatePairs.firstIndex(where: { $0.id == pair.id }) {
                                                viewModel.contentStatePairs[index].key = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    
                                    TextField("Value", text: Binding(
                                        get: { pair.value },
                                        set: { newValue in
                                            if let index = viewModel.contentStatePairs.firstIndex(where: { $0.id == pair.id }) {
                                                viewModel.contentStatePairs[index].value = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    
                                    Button(action: {
                                        if let index = viewModel.contentStatePairs.firstIndex(where: { $0.id == pair.id }) {
                                            viewModel.contentStatePairs.remove(at: index)
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
                            Text("Send Update")
                                .frame(width: 100)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(viewModel.isLoading || viewModel.activityToken.isEmpty)
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
    LiveActivityView()
        .frame(width: 500, height: 700)
}
