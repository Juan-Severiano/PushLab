//
//  FCMViewModel.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation
import SwiftUI

@Observable
class FCMViewModel {
    var registrationToken: String = ""
    var serverKey: String = ""
    
    var title: String = ""
    var body: String = ""
    
    var channelId: String = ""
    var sound: String = ""
    var color: String = ""
    var priority: String = "high"
    
    var dataPairs: [KeyValuePair] = []
    
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
    
    func addDataPair() {
        dataPairs.append(KeyValuePair(key: "", value: ""))
    }
    
    func removeDataPair(at offsets: IndexSet) {
        dataPairs.remove(atOffsets: offsets)
    }
    
    func send() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard !registrationToken.isEmpty else {
            errorMessage = "Please enter FCM registration token"
            return
        }
        
        var data: [String: String]? = nil
        if !dataPairs.isEmpty {
            data = [:]
            for pair in dataPairs where !pair.key.isEmpty {
                data?[pair.key] = pair.value
            }
        }
        
        let notification = FCMPayload.Message.Notification(
            title: title.isEmpty ? nil : title,
            body: body.isEmpty ? nil : body
        )
        
        let androidNotification = FCMPayload.Message.AndroidConfig.AndroidNotification(
            channelId: channelId.isEmpty ? nil : channelId,
            sound: sound.isEmpty ? nil : sound,
            color: color.isEmpty ? nil : color
        )
        
        let androidConfig = FCMPayload.Message.AndroidConfig(
            priority: priority,
            notification: androidNotification
        )
        
        let message = FCMPayload.Message(
            token: registrationToken,
            notification: notification,
            data: data,
            android: androidConfig
        )
        
        let payload = FCMPayload(message: message)
        
        do {
            let result = try await PushService.shared.sendFCMNotification(
                payload: payload,
                serverKey: serverKey
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
    
    func generateCURL() -> String {
        var request = URLRequest(url: URL(string: "https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(serverKey)", forHTTPHeaderField: "Authorization")
        
        var data: [String: String]? = nil
        if !dataPairs.isEmpty {
            data = [:]
            for pair in dataPairs where !pair.key.isEmpty {
                data?[pair.key] = pair.value
            }
        }
        
        let notification = FCMPayload.Message.Notification(
            title: title.isEmpty ? nil : title,
            body: body.isEmpty ? nil : body
        )
        
        let androidNotification = FCMPayload.Message.AndroidConfig.AndroidNotification(
            channelId: channelId.isEmpty ? nil : channelId,
            sound: sound.isEmpty ? nil : sound,
            color: color.isEmpty ? nil : color
        )
        
        let androidConfig = FCMPayload.Message.AndroidConfig(
            priority: priority,
            notification: androidNotification
        )
        
        let message = FCMPayload.Message(
            token: registrationToken,
            notification: notification,
            data: data,
            android: androidConfig
        )
        
        let payload = FCMPayload(message: message)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try? encoder.encode(payload)
        
        return PushService.shared.generateCURL(for: request)
    }
}
