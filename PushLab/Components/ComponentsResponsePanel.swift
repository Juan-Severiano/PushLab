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
    
    private var statusColor: Color {
        if status.contains("✅") { return .green }
        if status.contains("⚠️") { return .orange }
        if status.contains("❌") { return .red }
        return .secondary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label("Response", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 13, weight: .semibold))
                
                Text(status)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        statusColor.opacity(0.14),
                        in: Capsule(style: .continuous)
                    )
                
                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                
                Button(action: { isExpanded.toggle() }) {
                    Label(
                        isExpanded ? "Collapse" : "Expand",
                        systemImage: isExpanded ? "chevron.down" : "chevron.right"
                    )
                    .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                
                Spacer(minLength: 0)
            }
            
            if isExpanded {
                ScrollView {
                    Text(json)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .panelSurface(fill: Color(nsColor: .textBackgroundColor))
                }
                .frame(minHeight: 120, maxHeight: 220)
            }
        }
        .padding(14)
        .panelSurface(fill: Color(nsColor: .controlBackgroundColor))
    }
}
