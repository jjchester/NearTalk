//
//  Message.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-08.
//

import Foundation

struct Message: Codable, Hashable {
    enum MessageType: Codable {
        case text
        case media
        case acknowledgement
    }
    
    var uniqueID: String
    let content: String
    let timestamp: Date
    let peerIDData: Data
    let type: MessageType
}

struct ConversationMessage: Codable, Hashable {
    enum Status: Codable {
        case pending
        case acknowledged
        case failed
    }
    
    let message: Message
    var status: Status
    
    mutating func setStatus(status: Status) {
        self.status = status
    }
}
