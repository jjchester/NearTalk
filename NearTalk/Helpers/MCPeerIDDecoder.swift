//
//  MCPeerIDDecoder.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-09.
//

import Foundation
import MultipeerConnectivity

struct MCPeerIDDecoder {
    func peerIDFromData(data: Data) throws -> MCPeerID {
        do {
            let peerID = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)
            return peerID!
        } catch {
            throw DecodeError("Failed to decode MCPeerID from provided data")
        }
    }
}
