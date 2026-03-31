//
//  SavedToken.swift
//  PushLab
//
//  Created by Francisco Juan on 31/03/26.
//

import Foundation
import SwiftData

@Model
final class SavedToken {
    var id: UUID
    var label: String
    var token: String
    var type: TokenType
    var createdAt: Date
    
    enum TokenType: String, Codable {
        case expo
        case apns
        case fcm
        case liveActivity
    }
    
    init(label: String, token: String, type: TokenType) {
        self.id = UUID()
        self.label = label
        self.token = token
        self.type = type
        self.createdAt = Date()
    }
}
