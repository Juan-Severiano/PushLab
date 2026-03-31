//
//  LiveActivityViewModel.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation
import SwiftUI

@Observable
class LiveActivityViewModel {
    var activityToken: String = ""
    var bundleId: String = ""
    var teamId: String = ""
    var keyId: String = ""
    var p8Key: String = ""
    
    var eventType: String = "update"
    var title: String = ""
    var body: String = ""
    
    var contentStatePairs: [KeyValuePair] = []
    
    var isSandbox: Bool = true
    
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
    
    func addContentStatePair() {
        contentStatePairs.append(KeyValuePair(key: "", value: ""))
    }
    
    func removeContentStatePair(at offsets: IndexSet) {
        contentStatePairs.remove(atOffsets: offsets)
    }
    
    func send() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard !activityToken.isEmpty else {
            errorMessage = "Please enter activity token"
            return
        }
        
        var contentState: [String: String]? = nil
        if !contentStatePairs.isEmpty {
            contentState = [:]
            for pair in contentStatePairs where !pair.key.isEmpty {
                contentState?[pair.key] = pair.value
            }
        }
        
        let alert = LiveActivityPayload.APSContent.Alert(
            title: title.isEmpty ? nil : title,
            body: body.isEmpty ? nil : body
        )
        
        let aps = LiveActivityPayload.APSContent(
            timestamp: Int(Date().timeIntervalSince1970),
            event: eventType,
            contentState: contentState,
            alert: alert
        )
        
        let payload = LiveActivityPayload(aps: aps)
        
        do {
            let result = try await PushService.shared.sendLiveActivityUpdate(
                activityToken: activityToken,
                payload: payload,
                bundleId: bundleId,
                teamId: teamId,
                keyId: keyId,
                p8Key: p8Key,
                isSandbox: isSandbox
            )
            
            responseJSON = result.rawJSON
            
            if result.statusCode == 200 {
                responseStatus = "✅ Live Activity \(eventType) sent (HTTP \(result.statusCode))"
            } else {
                responseStatus = "⚠️ HTTP \(result.statusCode)"
            }
            
            showResponse = true
        } catch {
            errorMessage = error.localizedDescription
            responseJSON = ""
            responseStatus = "❌ Error"
        }
    }
    
    func loadP8Key(from url: URL) {
        do {
            let key = try String(contentsOf: url, encoding: .utf8)
            p8Key = key
        } catch {
            errorMessage = "Failed to load .p8 file: \(error.localizedDescription)"
        }
    }
    
    func generateCURL() -> String {
        let host = isSandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com"
        var request = URLRequest(url: URL(string: "https://\(host)/3/device/\(activityToken)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("liveactivity", forHTTPHeaderField: "apns-push-type")
        request.setValue("\(bundleId).push-type.liveactivity", forHTTPHeaderField: "apns-topic")
        request.setValue("bearer [JWT_TOKEN]", forHTTPHeaderField: "authorization")
        
        var contentState: [String: String]? = nil
        if !contentStatePairs.isEmpty {
            contentState = [:]
            for pair in contentStatePairs where !pair.key.isEmpty {
                contentState?[pair.key] = pair.value
            }
        }
        
        let alert = LiveActivityPayload.APSContent.Alert(
            title: title.isEmpty ? nil : title,
            body: body.isEmpty ? nil : body
        )
        
        let aps = LiveActivityPayload.APSContent(
            timestamp: Int(Date().timeIntervalSince1970),
            event: eventType,
            contentState: contentState,
            alert: alert
        )
        
        let payload = LiveActivityPayload(aps: aps)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try? encoder.encode(payload)
        
        return PushService.shared.generateCURL(for: request)
    }
}
