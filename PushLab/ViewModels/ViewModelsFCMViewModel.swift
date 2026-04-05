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
    
    // Service Account / Credentials file
    var projectId: String = ""
    var serviceAccountEmail: String = ""
    var privateKey: String = ""
    var credentialsFileName: String = ""
    
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
    
    /// Loads Firebase credentials from a service account JSON file
    func loadServiceAccount(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                errorMessage = "Invalid JSON format"
                return
            }
            
            // Firebase Admin SDK service account format
            if let projId = json["project_id"] as? String {
                projectId = projId
            }
            
            if let clientEmail = json["client_email"] as? String {
                serviceAccountEmail = clientEmail
            }
            
            if let privKey = json["private_key"] as? String {
                privateKey = privKey
            }
            
            credentialsFileName = url.lastPathComponent
            errorMessage = nil
            
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }
    
    /// Clears loaded credentials
    func clearCredentials() {
        projectId = ""
        serviceAccountEmail = ""
        privateKey = ""
        credentialsFileName = ""
    }
    
    var hasCredentialsLoaded: Bool {
        !projectId.isEmpty && !privateKey.isEmpty
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
