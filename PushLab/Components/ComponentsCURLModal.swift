//
//  CURLModal.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI

struct CURLModal: View {
    let curlCommand: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("cURL Command")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Use this request as a quick handoff to Terminal or documentation.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            
            ScrollView {
                Text(curlCommand)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .panelSurface(fill: Color(nsColor: .textBackgroundColor))
            }
            .frame(minHeight: 240, maxHeight: 420)
            
            HStack {
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(curlCommand, forType: .string)
                }
                .keyboardShortcut(.return)
                
                Spacer()
            }
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 360)
    }
}
