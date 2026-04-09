//
//  PushService.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation
import CryptoKit
import CryptoKit

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
        // Header
        let header: [String: Any] = ["alg": "ES256", "kid": keyId]
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let headerB64 = headerData.base64URLEncodedString()

        // Claims
        let claims: [String: Any] = ["iss": teamId, "iat": Int(Date().timeIntervalSince1970)]
        let claimsData = try JSONSerialization.data(withJSONObject: claims)
        let claimsB64 = claimsData.base64URLEncodedString()

        let signingInput = "\(headerB64).\(claimsB64)"

        // Sign with ES256 using CryptoKit P256 — p8Key is the PEM from Apple (.p8 file)
        let privateKey = try P256.Signing.PrivateKey(pemRepresentation: p8Key)
        let signature = try privateKey.signature(for: Data(signingInput.utf8))
        // APNs requires raw r||s format (64 bytes), not DER
        let signatureB64 = signature.rawRepresentation.base64URLEncodedString()

        return "\(signingInput).\(signatureB64)"
    }
    
    // MARK: - FCM
    func sendFCMNotification(
        payload: FCMPayload,
        projectId: String,
        serviceAccountEmail: String,
        privateKey: String
    ) async throws -> (statusCode: Int, rawJSON: String) {
        // Generate OAuth2 access token from service account credentials
        let accessToken = try await getGoogleAccessToken(
            serviceAccountEmail: serviceAccountEmail,
            privateKey: privateKey
        )
        
        guard let url = URL(string: "https://fcm.googleapis.com/v1/projects/\(projectId)/messages:send") else {
            throw PushServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
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
    
    /// Generates a Google OAuth2 access token using service account credentials
    private func getGoogleAccessToken(serviceAccountEmail: String, privateKey: String) async throws -> String {
        let now = Int(Date().timeIntervalSince1970)
        let exp = now + 3600 // Token valid for 1 hour
        
        // JWT Header
        let header: [String: Any] = ["alg": "RS256", "typ": "JWT"]
        
        // JWT Claims
        let claims: [String: Any] = [
            "iss": serviceAccountEmail,
            "scope": "https://www.googleapis.com/auth/firebase.messaging",
            "aud": "https://oauth2.googleapis.com/token",
            "iat": now,
            "exp": exp
        ]
        
        // Encode header and claims
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let claimsData = try JSONSerialization.data(withJSONObject: claims)
        
        let headerBase64 = headerData.base64URLEncodedString()
        let claimsBase64 = claimsData.base64URLEncodedString()
        
        let signatureInput = "\(headerBase64).\(claimsBase64)"
        
        // Sign with RS256
        let signature = try signWithRS256(data: signatureInput.data(using: .utf8)!, privateKey: privateKey)
        let signatureBase64 = signature.base64URLEncodedString()
        
        let jwt = "\(signatureInput).\(signatureBase64)"
        
        // Exchange JWT for access token
        guard let tokenURL = URL(string: "https://oauth2.googleapis.com/token") else {
            throw PushServiceError.invalidURL
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PushServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorJSON = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PushServiceError.httpError(httpResponse.statusCode, "OAuth token error: \(errorJSON)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw PushServiceError.invalidResponse
        }
        
        return accessToken
    }
    
    /// Signs data using RS256 (RSA with SHA-256)
    private func signWithRS256(data: Data, privateKey: String) throws -> Data {
        // Clean the private key - remove PEM headers and whitespace
        let cleanKey = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        guard let keyData = Data(base64Encoded: cleanKey) else {
            throw PushServiceError.encodingError
        }
        
        // Firebase keys are in PKCS#8 format, we need to extract the RSA key
        let rsaKeyData = try extractRSAKeyFromPKCS8(keyData)
        
        // Create SecKey from the private key data
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]
        
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(rsaKeyData as CFData, keyAttributes as CFDictionary, &error) else {
            if let err = error?.takeRetainedValue() {
                throw PushServiceError.httpError(0, "Failed to create private key: \(err)")
            }
            throw PushServiceError.encodingError
        }
        
        // Sign the data
        guard SecKeyIsAlgorithmSupported(secKey, .sign, .rsaSignatureMessagePKCS1v15SHA256) else {
            throw PushServiceError.httpError(0, "RS256 signing not supported")
        }
        
        guard let signedData = SecKeyCreateSignature(secKey, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &error) else {
            if let err = error?.takeRetainedValue() {
                throw PushServiceError.httpError(0, "Failed to sign: \(err)")
            }
            throw PushServiceError.encodingError
        }
        
        return signedData as Data
    }
    
    /// Extracts RSA private key from PKCS#8 DER format
    /// PKCS#8 structure: SEQUENCE { version, algorithmIdentifier, privateKey (OCTET STRING containing PKCS#1 RSA key) }
    private func extractRSAKeyFromPKCS8(_ pkcs8Data: Data) throws -> Data {
        // PKCS#8 header for RSA keys (this is the ASN.1 structure before the actual key)
        // 30 82 xx xx - SEQUENCE
        // 02 01 00    - INTEGER 0 (version)
        // 30 0d       - SEQUENCE (algorithm identifier)
        //   06 09 2a 86 48 86 f7 0d 01 01 01 - OID for RSA
        //   05 00     - NULL
        // 04 82 xx xx - OCTET STRING containing the RSA private key
        
        let bytes = [UInt8](pkcs8Data)
        
        // Find the OCTET STRING tag (0x04) that contains the RSA key
        // The RSA key starts after the PKCS#8 header
        var index = 0
        
        // Skip outer SEQUENCE tag and length
        guard bytes.count > 4, bytes[0] == 0x30 else {
            throw PushServiceError.httpError(0, "Invalid PKCS#8 format: missing outer SEQUENCE")
        }
        index = skipASN1TagAndLength(bytes: bytes, from: 0)
        
        // Skip version INTEGER (should be 0)
        guard index < bytes.count, bytes[index] == 0x02 else {
            throw PushServiceError.httpError(0, "Invalid PKCS#8 format: missing version")
        }
        index = skipASN1TagAndLength(bytes: bytes, from: index)
        index += 1 // skip the version value (0)
        
        // Skip algorithm identifier SEQUENCE
        guard index < bytes.count, bytes[index] == 0x30 else {
            throw PushServiceError.httpError(0, "Invalid PKCS#8 format: missing algorithm identifier")
        }
        let algIdLength = getASN1Length(bytes: bytes, from: index + 1)
        index = skipASN1TagAndLength(bytes: bytes, from: index)
        index += algIdLength.length
        
        // Now we should be at the OCTET STRING containing the RSA private key
        guard index < bytes.count, bytes[index] == 0x04 else {
            throw PushServiceError.httpError(0, "Invalid PKCS#8 format: missing private key OCTET STRING")
        }
        
        let keyStart = skipASN1TagAndLength(bytes: bytes, from: index)
        let keyData = Data(bytes[keyStart...])
        
        return keyData
    }
    
    /// Skips ASN.1 tag and length bytes, returns the index of the content
    private func skipASN1TagAndLength(bytes: [UInt8], from index: Int) -> Int {
        let i = index + 1 // skip tag
        
        guard i < bytes.count else { return i }
        
        let lengthByte = bytes[i]
        if lengthByte & 0x80 == 0 {
            // Short form: length is in this byte
            return i + 1
        } else {
            // Long form: lower 7 bits tell how many bytes follow for length
            let numLengthBytes = Int(lengthByte & 0x7F)
            return i + 1 + numLengthBytes
        }
    }
    
    /// Gets the length value from ASN.1 length encoding
    private func getASN1Length(bytes: [UInt8], from index: Int) -> (length: Int, bytesUsed: Int) {
        guard index < bytes.count else { return (0, 0) }
        
        let lengthByte = bytes[index]
        if lengthByte & 0x80 == 0 {
            // Short form
            return (Int(lengthByte), 1)
        } else {
            // Long form
            let numLengthBytes = Int(lengthByte & 0x7F)
            var length = 0
            for i in 0..<numLengthBytes {
                guard index + 1 + i < bytes.count else { return (0, 0) }
                length = (length << 8) | Int(bytes[index + 1 + i])
            }
            return (length, 1 + numLengthBytes)
        }
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

// MARK: - Base64 URL Encoding Extension
extension Data {
    /// Encodes data to base64 URL-safe string (no padding)
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
