//
//  ConversationTile.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-08-01.
//

import SwiftUI
import MultipeerConnectivity

struct ConversationTile: View {
    
    @State var session: PeerSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(session.pairedPeer?.displayName ?? "Name Unavailable")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Preview text
                Text("asdasdasdasdasdasdasdasdasdasdasdasdasdasd asdasdasdasdasdasdasdasdasdasdasdasdasd")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let pairedPeer = MCPeerID(displayName: "Joe Shmo")
    let session = PeerSession(peerID: MCPeerID(displayName: "Test"), uuid: "asd-asd-asd-asd")
    session.pairedPeer = pairedPeer
    return ConversationTile(session: session)
}
