//
//  ConversationView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-07.
//

import SwiftUI
import MultipeerConnectivity

struct ConversationView: View {
    @State private var textEditorHeight : CGFloat = 100
    @State private var text = ""
    @StateObject var session = ChatSession.shared
    private var placeholderText = "Message"
    private var conversationPeer: MCPeerID
    private var decoder = MCPeerIDDecoder()
    private var selfPeerId: MCPeerID {
        return session.peerID
    }
    private var conversation: [ConversationMessage] {
        return session.conversations[conversationPeer]?.sorted(by: { a, b in
            a.message.timestamp < b.message.timestamp
        }) ?? []
    }
    public init(conversationPeer: MCPeerID) {
        self.conversationPeer = conversationPeer
    }
    
    private var maxHeight : CGFloat = 300
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(conversation, id: \.self) { message in
                    let messagePeerId = try? decoder.peerIDFromData(data: message.message.peerIDData)
                    HStack {
                        if messagePeerId == selfPeerId {
                            Spacer()
                        }
                        MessageBubble(message: message)
                            .alignmentGuide(.leading) { _ in
                                if messagePeerId == selfPeerId {
                                    return 0 // Align to leading edge
                                } else {
                                    return -1000 // Align to trailing edge (offscreen)
                                }
                            }
                            .padding( messagePeerId == selfPeerId ? [.leading] : [.trailing], 40)
                        if messagePeerId != selfPeerId {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal) // Add horizontal padding to the entire stack
        }
        Spacer()
        ComposerView(messageText: $text, sendMessageHandler: {
            ChatSession.shared.sendMessage(message: text, receivingPeer: conversationPeer)
        })
    }
}

#Preview {
    ConversationView( conversationPeer: MCPeerID(displayName: "phone"))
}
