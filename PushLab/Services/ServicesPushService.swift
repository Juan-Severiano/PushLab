//
//  PushService.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation

enum PushServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int, String?)
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message ?? "Unknown error")"
        case .encodingError:
            return "Failed to encode payload"
        }
    }
}

class PushService {
    static let shared = PushService()
    
    private init() {}
    
    // MARK: - Expo
    func sendExpoNotification(payload: ExpoNotificationPayload, accessToken: String? = nil) async throws -> (response: ExpoResponse, rawJSON: String) {
        guard let url = URL(string: "https://exp.host/--/api/v2/push/send") else {
            throw PushServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        guard let httpBody = try? encoder.encode(payload) else {
            throw PushServiceError.encodingError
        }
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PushServiceError.invalidResponse
        }
        
        let rawJSON = String(data: data, encoding: .utf8) ?? "{}"
        
        guard httpResponse.statusCode == 200 else {
            throw PushServiceError.httpError(httpResponse.statusCode, rawJSON)
        }
        
        let decoder = JSONDecoder()
        let expoResponse = try decoder.decode(ExpoResponse.self, from: data)
        
        return (expoResponse, rawJSON)
    }
    
    // MARK: - APNs
    func sendAPNsNotification(
        deviceToken: String,
        payload: APNsPayload,
        bundleId: String,
        teamId: String,
        keyId: String,
        p8Key: String,
        isSandbox: Bool = true,
        pushType: String = "alert"
    ) async throws -> (statusCode: Int, rawJSON: String) {
        let host = isSandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com"
        guard let url = URL(string: "https://\(host)/3/device/\(deviceToken)") else {
            throw PushServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(pushType, forHTTPHeaderField: "apns-push-type")
        request.setValue(bundleId, forHTTPHeaderField: "apns-topic")
        
        // Generate JWT token
        let jwtToken = try generateAPNsJWT(teamId: teamId, keyId: keyId, p8Key: p8Key)
        request.setValue("bearer \(jwtToken)", forHTTPHeaderField: "authorization")
        
        let encoder = JSONEncoder()
        guard let httpBody = try? encoder.encode(payload) else {
            throw PushServiceError.encodingError
        }
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PushServiceError.invalidResponse
        }
        
        let rawJSON = String(data: data, encoding: .utf8) ?? "{}"
        
        return (httpResponse.statusCode, rawJSON)
    }
    
    private func generateAPNsJWT(teamId: String, keyId: String, p8Key: String) throws -> String {
        // Simplified JWT generation - in production, use CryptoKit for ES256 signing
        // This is a placeholder that shows the structure
        let header = ["alg": "ES256", "kid": keyId]
        _ = ["iss": teamId, "iat": Int(Date().timeIntervalSince1970)] as [String : Any]
        
        // Note: Real implementation requires ES256 signing with CryptoKit
        // For now, returning a placeholder
        return "PLACEHOLDER_JWT_TOKEN"
    }
    
    // MARK: - FCM
    func sendFCMNotification(payload: FCMPayload, serverKey: String) async throws -> (statusCode: Int, rawJSON: String) {
        guard let url = URL(string: "https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send") else {
            throw PushServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(serverKey)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        guard let httpBody = try? encoder.encode(payload) else {
            throw PushServiceError.encodingError
        }
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PushServiceError.invalidResponse
        }
        
        let rawJSON = String(data: data, encoding: .utf8) ?? "{}"
        
        return (httpResponse.statusCode, rawJSON)
    }
    
    // MARK: - Live Activity
    func sendLiveActivityUpdate(
        activityToken: String,
        payload: LiveActivityPayload,
        bundleId: String,
        teamId: String,
        keyId: String,
        p8Key: String,
        isSandbox: Bool = true
    ) async throws -> (statusCode: Int, rawJSON: String) {
        let host = isSandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com"
        guard let url = URL(string: "https://\(host)/3/device/\(activityToken)") else {
            throw PushServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("liveactivity", forHTTPHeaderField: "apns-push-type")
        request.setValue("\(bundleId).push-type.liveactivity", forHTTPHeaderField: "apns-topic")
        
        let jwtToken = try generateAPNsJWT(teamId: teamId, keyId: keyId, p8Key: p8Key)
        request.setValue("bearer \(jwtToken)", forHTTPHeaderField: "authorization")
        
        let encoder = JSONEncoder()
        guard let httpBody = try? encoder.encode(payload) else {
            throw PushServiceError.encodingError
        }
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PushServiceError.invalidResponse
        }
        
        let rawJSON = String(data: data, encoding: .utf8) ?? "{}"
        
        return (httpResponse.statusCode, rawJSON)
    }
    
    // MARK: - cURL Generation
    func generateCURL(for request: URLRequest) -> String {
        var curl = "curl -X \(request.httpMethod ?? "GET")"
        
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                curl += " \\\n  -H '\(key): \(value)'"
            }
        }
        
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            curl += " \\\n  -d '\(bodyString)'"
        }
        
        if let url = request.url {
            curl += " \\\n  '\(url.absoluteString)'"
        }
        
        return curl
    }
}
