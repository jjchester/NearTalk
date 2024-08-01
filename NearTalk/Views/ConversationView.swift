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
    @StateObject var sessionManager = SessionManager.shared
    private var placeholderText = "Message"
    private var peerSession: PeerSession

    private var conversation: [Message] {
        return []
//        return sessionManager.conversations["test"]?.sorted(by: { a, b in
//            a.message.timestamp < b.message.timestamp
//        }) ?? []
    }
    public init(peerSession: PeerSession) {
        self.peerSession = peerSession
    }
    
    private var maxHeight : CGFloat = 300
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
//                ForEach(conversation, id: \.self) { message in
//                    let messagePeerId = try? decoder.peerIDFromData(data: message.message.peerIDData)
//                    HStack {
//                        if messagePeerId == selfPeerId {
//                            Spacer()
//                        }
//                        MessageBubble(message: message)
//                            .alignmentGuide(.leading) { _ in
//                                if messagePeerId == selfPeerId {
//                                    return 0 // Align to leading edge
//                                } else {
//                                    return -1000 // Align to trailing edge (offscreen)
//                                }
//                            }
//                            .padding( messagePeerId == selfPeerId ? [.leading] : [.trailing], 40)
//                        if messagePeerId != selfPeerId {
//                            Spacer()
//                        }
//                    }
//                }
            }
            .padding(.horizontal) // Add horizontal padding to the entire stack
        }
        Spacer()
            .navigationTitle(peerSession.pairedPeer?.displayName ?? "")
        ComposerView(messageText: $text, sendMessageHandler: {
            peerSession.sendMessage(Message(type: .text, data: [Constants.TEXT: text]))
        })
    }
}
