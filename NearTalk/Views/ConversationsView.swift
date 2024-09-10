//
//  ConversationsView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-06-07.
//

import SwiftUI
import MultipeerConnectivity

struct ConversationsView: View {
    @State var connections: String = ""
    @ObservedObject var sessionManager = SessionManager.shared
    
    var sessionKeys: [PeerSession] {
        Array(sessionManager.pairedSessions.keys)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(sessionKeys, id: \.self) { session in
                    NavigationLink(destination: {
                        ConversationView(peerSession: session)
                    }, label: {
                        ConversationTile(session: session)
                    })
                }
                .onDelete(perform: { indexSet in
                    guard let index = indexSet.first else { return }
                    sessionManager.removePeerSession(sessionKeys[index])
                })
            }
            .listStyle(.inset)
            Button("Print Peers") {
                print("Paired peers: ")
                sessionManager.pairedSessions.keys.forEach { session in
                    print(session.pairedPeer?.displayName ?? "Peer has no displayname")
                }
                print("Available Peers: ")
                print(sessionManager.availablePeers)
            }
        }
    }
}

#Preview {
    
    func mockPeerSession() -> PeerSession {
        let peer = MCPeerID(displayName: String(Int.random(in: 1...1000)))
        let connectedPeer = MCPeerID(displayName: String(Int.random(in: 1...1000)))
        let session = PeerSession(peerID: peer, uuid: String(Int.random(in:1...1000)))
        session.pairedPeer = connectedPeer
        return session
    }
    
    SessionManager.shared.pairedSessions = [
        mockPeerSession():.connected,
        mockPeerSession():.connected,
        mockPeerSession():.connected,
        mockPeerSession():.connected
    ]
    return ConversationsView()
}
