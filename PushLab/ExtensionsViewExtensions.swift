//
//  View+Extensions.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import SwiftUI

extension View {
    /// Aplica um padding condicional
    func padding(_ edges: Edge.Set, _ length: CGFloat, if condition: Bool) -> some View {
        modifier(ConditionalPaddingModifier(edges: edges, length: length, condition: condition))
    }
    
    /// Helper para copiar texto para clipboard
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct ConditionalPaddingModifier: ViewModifier {
    let edges: Edge.Set
    let length: CGFloat
    let condition: Bool
    
    func body(content: Content) -> some View {
        if condition {
            content.padding(edges, length)
        } else {
            content
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let pushLabAccent = Color.blue
    static let pushLabBackground = Color(nsColor: .windowBackgroundColor)
    static let pushLabSecondaryBackground = Color(nsColor: .controlBackgroundColor)
}

// MARK: - String Extensions
extension String {
    var isValidExpoToken: Bool {
        hasPrefix("ExponentPushToken[") && hasSuffix("]")
    }
    
    var isValidAPNsToken: Bool {
        // APNs tokens são tipicamente 64 caracteres hex
        let hexPattern = "^[0-9a-fA-F]{64}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", hexPattern)
        return predicate.evaluate(with: self.replacingOccurrences(of: " ", with: ""))
    }
    
    var prettyJSON: String? {
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            return nil
        }
        return String(data: prettyData, encoding: .utf8)
    }
}
