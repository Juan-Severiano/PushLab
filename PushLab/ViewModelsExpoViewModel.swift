//
//  ExpoViewModel.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation
import SwiftUI

@Observable
class ExpoViewModel {
    var tokens: String = ""
    var title: String = ""
    var body: String = ""
    var priority: String = "normal"
    var sound: String = "default"
    var badge: String = ""
    var accessToken: String = ""
    
    var customDataPairs: [KeyValuePair] = []
    
    var isLoading: Bool = false
    var responseJSON: String = ""
    var responseStatus: String = ""
    var showResponse: Bool = false
    var errorMessage: String?
    
    struct KeyValuePair: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }
    
    func addCustomDataPair() {
        customDataPairs.append(KeyValuePair(key: "", value: ""))
    }
    
    func removeCustomDataPair(at offsets: IndexSet) {
        customDataPairs.remove(atOffsets: offsets)
    }
    
    func send() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Parse tokens
        let tokenList = tokens
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !tokenList.isEmpty else {
            errorMessage = "Please enter at least one token"
            return
        }
        
        // Build custom data
        var customData: [String: String]? = nil
        if !customDataPairs.isEmpty {
            customData = [:]
            for pair in customDataPairs where !pair.key.isEmpty {
                customData?[pair.key] = pair.value
            }
        }
        
        let payload = ExpoNotificationPayload(
            to: tokenList,
            title: title.isEmpty ? nil : title,
            body: body.isEmpty ? nil : body,
            data: customData,
            priority: priority,
            sound: sound.isEmpty ? nil : sound,
            badge: Int(badge)
        )
        
        do {
            let result = try await PushService.shared.sendExpoNotification(
                payload: payload,
                accessToken: accessToken.isEmpty ? nil : accessToken
            )
            
            responseJSON = result.rawJSON
            
            if let tickets = result.response.data {
                let okCount = tickets.filter { $0.status == "ok" }.count
                let errorCount = tickets.filter { $0.status == "error" }.count
                responseStatus = "✅ \(okCount) sent, ❌ \(errorCount) failed"
            } else {
                responseStatus = "Response received"
            }
            
            showResponse = true
        } catch {
            errorMessage = error.localizedDescription
            responseJSON = ""
            responseStatus = "❌ Error"
        }
    }
    
    func generateCURL() -> String {
        let tokenList = tokens
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var customData: [String: String]? = nil
        if !customDataPairs.isEmpty {
            customData = [:]
            for pair in customDataPairs where !pair.key.isEmpty {
                customData?[pair.key] = pair.value
            }
        }
        
        let payload = ExpoNotificationPayload(
            to: tokenList,
            title: title.isEmpty ? nil : title,
            body: body.isEmpty ? nil : body,
            data: customData,
            priority: priority,
            sound: sound.isEmpty ? nil : sound,
            badge: Int(badge)
        )
        
        var request = URLRequest(url: URL(string: "https://exp.host/--/api/v2/push/send")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try? encoder.encode(payload)
        
        return PushService.shared.generateCURL(for: request)
    }
}
