//
//  APNsViewModel.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation
import SwiftUI

@Observable
class APNsViewModel {
    var deviceToken: String = ""
    var bundleId: String = ""
    var teamId: String = ""
    var keyId: String = ""
    var p8Key: String = ""
    
    var title: String = ""
    var subtitle: String = ""
    var body: String = ""
    var sound: String = "default"
    var badge: String = ""
    
    var pushType: String = "alert"
    var isSandbox: Bool = true
    
    var isLoading: Bool = false
    var responseJSON: String = ""
    var responseStatus: String = ""
    var showResponse: Bool = false
    var errorMessage: String?
    
    func send() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard !deviceToken.isEmpty else {
            errorMessage = "Please enter device token"
            return
        }
        
        let alert = APNsPayload.APSContent.Alert(
            title: title.isEmpty ? nil : title,
            subtitle: subtitle.isEmpty ? nil : subtitle,
            body: body.isEmpty ? nil : body
        )
        
        let aps = APNsPayload.APSContent(
            alert: alert,
            badge: Int(badge),
            sound: sound.isEmpty ? nil : sound,
            contentAvailable: pushType == "background" ? 1 : nil
        )
        
        let payload = APNsPayload(aps: aps, customData: nil)
        
        do {
            let result = try await PushService.shared.sendAPNsNotification(
                deviceToken: deviceToken,
                payload: payload,
                bundleId: bundleId,
                teamId: teamId,
                keyId: keyId,
                p8Key: p8Key,
                isSandbox: isSandbox,
                pushType: pushType
            )
            
            responseJSON = result.rawJSON
            
            if result.statusCode == 200 {
                responseStatus = "✅ Sent successfully (HTTP \(result.statusCode))"
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
        var request = URLRequest(url: URL(string: "https://\(host)/3/device/\(deviceToken)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(pushType, forHTTPHeaderField: "apns-push-type")
        request.setValue(bundleId, forHTTPHeaderField: "apns-topic")
        request.setValue("bearer [JWT_TOKEN]", forHTTPHeaderField: "authorization")
        
        let alert = APNsPayload.APSContent.Alert(
            title: title.isEmpty ? nil : title,
            subtitle: subtitle.isEmpty ? nil : subtitle,
            body: body.isEmpty ? nil : body
        )
        
        let aps = APNsPayload.APSContent(
            alert: alert,
            badge: Int(badge),
            sound: sound.isEmpty ? nil : sound,
            contentAvailable: pushType == "background" ? 1 : nil
        )
        
        let payload = APNsPayload(aps: aps, customData: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try? encoder.encode(payload)
        
        return PushService.shared.generateCURL(for: request)
    }
}
