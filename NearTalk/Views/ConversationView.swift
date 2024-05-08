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
    
    public init(conversationPeer: MCPeerID) {
        self.conversationPeer = conversationPeer
    }
    
    private var maxHeight : CGFloat = 300
    
    var body: some View {
        VStack {
            ForEach(session.conversations[conversationPeer] ?? [], id: \.self) { message in
                Text(message.content)
            }
            ComposerView(messageText: $text, sendMessageHandler: {
                ChatSession.shared.sendMessage(message: text, receivingPeer: [conversationPeer])
            })
        }
    }
}

#Preview {
    ConversationView( conversationPeer: MCPeerID(displayName: "phone"))
}
