//
//  MessageBubble.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-08.
//

import SwiftUI
import MultipeerConnectivity

struct MessageBubble: View {
    let message: ConversationMessage
    @StateObject var session: ChatSession = ChatSession.shared
    var peerID: MCPeerID?
    var bubbleColor: Color {
        return self.peerID == session.peerID ? .blue : .gray.opacity(0.2)
    }
    var textColor: Color {
        return self.peerID == session.peerID ? .white : .black
    }
    
    init(message: ConversationMessage) {
        self.message = message
        do {
            try self.peerID = MCPeerIDDecoder().peerIDFromData(data: message.message.peerIDData)
        } catch {
            self.peerID = MCPeerID(displayName: "Test")
        }
    }
    
    var body: some View {
        VStack {
            Text(message.message.content)
                .fixedSize(horizontal: false, vertical: true)
                .padding(8) // Add padding around the text
                .background(bubbleColor) // Background color for the text bubble
                .foregroundColor(textColor) // Text color
                .clipShape(RoundedRectangle(cornerRadius: 16)) // Rounded corners
                .textSelection(.enabled)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.message.content
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
        }
    }
}
