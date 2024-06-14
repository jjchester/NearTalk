//
//  Message.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-08.
//

import Foundation
import SwiftData

@Model
class Message: Codable, Hashable {
    enum MessageType: Codable {
        case text
        case media
        case acknowledgement
    }
    
    @Attribute(.unique) var id: String
    let content: String
    let timestamp: Date
    let peerIDData: Data
    let type: MessageType
    
    init(uniqueID: String, content: String, timestamp: Date, peerIDData: Data, type: MessageType) {
        self.id = uniqueID
        self.content = content
        self.timestamp = timestamp
        self.peerIDData = peerIDData
        self.type = type
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(peerIDData, forKey: .peerIDData)
        try container.encode(type, forKey: .type)
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            content = try container.decode(String.self, forKey: .content)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            peerIDData = try container.decode(Data.self, forKey: .peerIDData)
            type = try container.decode(MessageType.self, forKey: .type)
        } catch {
            print("Failed to decode message")
            fatalError()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case timestamp
        case peerIDData
        case type
    }
}

@Model
class ConversationMessage: Codable, Hashable {
    enum Status: String, Codable { // Specify raw values for enum cases to conform to Codable
        case pending
        case acknowledged
        case failed
    }
    
    let message: Message
    var status: Status
    
    func setStatus(status: Status) {
        self.status = status
    }
    
    init(message: Message, status: Status) {
        self.message = message
        self.status = status
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(Message.self, forKey: .message)
        status = try container.decode(Status.self, forKey: .status)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(status, forKey: .status)
    }
    
    enum CodingKeys: String, CodingKey {
        case message
        case status
    }
}
