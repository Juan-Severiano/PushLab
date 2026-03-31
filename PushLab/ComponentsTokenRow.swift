//
//  TokenRow.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI
import SwiftData

struct TokenRow: View {
    let token: SavedToken
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(token.label)
                    .font(.system(size: 13, weight: .medium))
                
                Text(token.token)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(token.token, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Copy token")
            
            Button(action: onSelect) {
                Image(systemName: "arrow.up.forward.square")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Use this token")
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Delete")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct SaveTokenView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var token: String
    var tokenType: SavedToken.TokenType
    
    @State private var label: String = ""
    @State private var showSheet = false
    
    var body: some View {
        Button(action: { showSheet = true }) {
            Label("Save Token", systemImage: "bookmark")
                .font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .disabled(token.isEmpty)
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 16) {
                Text("Save Token")
                    .font(.system(size: 16, weight: .semibold))
                
                TextField("Label (e.g., iPhone 17 Pro)", text: $label)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Button("Cancel") {
                        showSheet = false
                        label = ""
                    }
                    .keyboardShortcut(.escape)
                    
                    Button("Save") {
                        let savedToken = SavedToken(
                            label: label,
                            token: token,
                            type: tokenType
                        )
                        modelContext.insert(savedToken)
                        showSheet = false
                        label = ""
                    }
                    .keyboardShortcut(.return)
                    .disabled(label.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
}

struct SavedTokensList: View {
    @Query private var allTokens: [SavedToken]
    @Environment(\.modelContext) private var modelContext
    
    let tokenType: SavedToken.TokenType
    let onSelect: (String) -> Void
    
    var filteredTokens: [SavedToken] {
        allTokens.filter { $0.type == tokenType }
    }
    
    var body: some View {
        if !filteredTokens.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Saved Tokens")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                VStack(spacing: 4) {
                    ForEach(filteredTokens) { token in
                        TokenRow(
                            token: token,
                            onDelete: {
                                modelContext.delete(token)
                            },
                            onSelect: {
                                onSelect(token.token)
                            }
                        )
                    }
                }
            }
        }
    }
}
