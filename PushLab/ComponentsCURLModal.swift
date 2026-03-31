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
        VStack(spacing: 16) {
            HStack {
                Text("cURL Command")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                Text(curlCommand)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 400)
            
            HStack {
                Spacer()
                
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(curlCommand, forType: .string)
                }
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 600)
    }
}
