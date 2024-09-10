//
//  MessageBubble.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-08.
//

import SwiftUI
import MultipeerConnectivity

struct MessageBubble: View {
    let message: Message
    let selfUuid: String
    
    var bubbleColor: Color {
        return self.selfUuid == message.senderUuid ? .blue : .gray.opacity(0.2)
    }
    var textColor: Color {
        return self.selfUuid == message.senderUuid ? .white : .black
    }
    
    init(message: Message, selfUuid: String) {
        self.message = message
        self.selfUuid = selfUuid
    }
    
    var body: some View {
        VStack {
            Text(message.data[Constants.TEXT]!)
                .fixedSize(horizontal: false, vertical: true)
                .padding(8) // Add padding around the text
                .background(bubbleColor) // Background color for the text bubble
                .foregroundColor(textColor) // Text color
                .clipShape(RoundedRectangle(cornerRadius: 16)) // Rounded corners
                .textSelection(.enabled)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.data[Constants.TEXT]!
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
        }
    }
}
