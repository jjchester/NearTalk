//
//  ConversationsView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-06-07.
//

import SwiftUI

struct ConversationsView: View {
    @State var connections: String = ""
    @ObservedObject var sessionManager = SessionManager.shared
    var sessionKeys: [PeerSession] {
        return Array(sessionManager.pairedSessions.keys)//.sorted(by: {$0.pairedPeerUUID! < $1.pairedPeerUUID!})
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(sessionKeys, id: \.self) { session in
                    VStack(alignment: .leading) {
                        Text(session.pairedPeer?.displayName ?? "")
                            .font(.title)
                        Text(String(Array(repeating: "a", count: 200)))
                            .lineLimit(2)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                }
                .onDelete(perform: { indexSet in
                    guard let index = indexSet.first else { return }
                    sessionManager.removePeerSession(sessionKeys[index])
                })
            }
            .listStyle(.inset)
        }
    }
}

#Preview {
    ConversationsView()
}
