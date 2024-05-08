//
//  AvailableUsersView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-07.
//

import SwiftUI

struct AvailableUsersView: View {
    @ObservedObject var session = ChatSession.shared
    var body: some View {
        VStack(alignment: .leading) {
            Text("Nearby Users")
                .font(.largeTitle)
                .padding()
            List(session.connectedPeers, id: \.self) { peer in
                NavigationLink(peer.displayName) {
                    ConversationView(conversationPeer: peer)
                }
            }
            .listStyle(.grouped)
            List(session.availablePeers, id: \.self) { peer in
                Button {
                    print(peer.displayName)
                    session.serviceBrowser.invitePeer(peer, to: session.session, withContext: nil, timeout: 30)
                } label: {
                    Text("\(peer.displayName)")
                }
            }
        }
    }
}

#Preview {
    AvailableUsersView()
}
