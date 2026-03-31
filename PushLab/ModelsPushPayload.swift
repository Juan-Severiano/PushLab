//
//  PushPayload.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation

// MARK: - Expo
struct ExpoNotificationPayload: Codable {
    var to: [String]
    var title: String?
    var body: String?
    var data: [String: String]?
    var priority: String?
    var sound: String?
    var badge: Int?
    var channelId: String?
    var ttl: Int?
}

struct ExpoResponse: Codable {
    var data: [ExpoTicket]?
}

struct ExpoTicket: Codable {
    var status: String
    var id: String?
    var message: String?
    var details: [String: String]?
}

// MARK: - APNs
struct APNsPayload: Codable {
    var aps: APSContent
    var customData: [String: String]?
    
    struct APSContent: Codable {
        var alert: Alert?
        var badge: Int?
        var sound: String?
        var contentAvailable: Int?
        
        struct Alert: Codable {
            var title: String?
            var subtitle: String?
            var body: String?
        }
        
        enum CodingKeys: String, CodingKey {
            case alert, badge, sound
            case contentAvailable = "content-available"
        }
    }
}

// MARK: - FCM
struct FCMPayload: Codable {
    var message: Message
    
    struct Message: Codable {
        var token: String
        var notification: Notification?
        var data: [String: String]?
        var android: AndroidConfig?
        
        struct Notification: Codable {
            var title: String?
            var body: String?
        }
        
        struct AndroidConfig: Codable {
            var priority: String?
            var notification: AndroidNotification?
            
            struct AndroidNotification: Codable {
                var channelId: String?
                var sound: String?
                var color: String?
                
                enum CodingKeys: String, CodingKey {
                    case channelId = "channel_id"
                    case sound, color
                }
            }
        }
    }
}

// MARK: - Live Activity
struct LiveActivityPayload: Codable {
    var aps: APSContent
    
    struct APSContent: Codable {
        var timestamp: Int
        var event: String
        var contentState: [String: String]?
        var alert: Alert?
        
        struct Alert: Codable {
            var title: String?
            var body: String?
        }
        
        enum CodingKeys: String, CodingKey {
            case timestamp, event
            case contentState = "content-state"
            case alert
        }
    }
}
