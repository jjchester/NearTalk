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
