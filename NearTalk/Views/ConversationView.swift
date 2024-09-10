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
    private var placeholderText = "Message"
    @ObservedObject private var peerSession: PeerSession
    
    public init(peerSession: PeerSession) {
        self.peerSession = peerSession
    }
    
    private var maxHeight : CGFloat = 300
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(peerSession.messages.keys), id: \.self) { uuid in
                    Text("")
                    HStack {
                        if let message = peerSession.messages[uuid] {
                            let isSender = message.senderUuid == peerSession.uuid
                            if isSender {
                                Spacer()
                            }
                            MessageBubble(message: message, selfUuid: peerSession.uuid)
                                .alignmentGuide(.leading) { _ in
                                    if isSender{
                                        return 0 // Align to leading edge
                                    } else {
                                        return -1000 // Align to trailing edge (offscreen)
                                    }
                                }
                                .padding( isSender ? [.leading] : [.trailing], 40)
                            if !isSender {
                                Spacer()
                            }
                        }
                    }
                }
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
            peerSession.sendMessage(Message(type: .text, data: [Constants.TEXT: text], senderUuid: peerSession.uuid))
        })
    }
}
