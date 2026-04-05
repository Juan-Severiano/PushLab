//
//  ResponsePanel.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI

struct ResponsePanel: View {
    let status: String
    let json: String
    let onCopy: () -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(status, systemImage: status.contains("✅") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(status.contains("✅") ? .green : .orange)
                
                Spacer()
                
                Button(action: onCopy) {
                    Label("Copy Response", systemImage: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                ScrollView {
                    Text(json)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}
