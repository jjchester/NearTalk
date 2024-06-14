//
//  AvailableUsersView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-07.
//

import SwiftUI

struct AvailableUsersView: View {
    @ObservedObject var session = SessionManager.shared
    var body: some View {
        VStack {
            Text("Searching for nearby users")
                .font(.caption)
                .padding(.top)
            ProgressView()
                .padding(.bottom)
                .progressViewStyle(.circular)
                .tint(.green)
            List(Array(session.availablePeers.keys), id: \.self) { peerUUID in
                if let peerID = session.availablePeers[peerUUID] {
                    UserCard(
                        username: peerID.displayName,
                        uuid: peerUUID,
                        action: {
                            session.sendInvite(peerID)
                        }
                    )
                    .transition(.moveAndFade)
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Test")
    }
}

#Preview {
    AvailableUsersView()
}
