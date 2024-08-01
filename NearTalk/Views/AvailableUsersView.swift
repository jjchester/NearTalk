//
//  AvailableUsersView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-07.
//

import SwiftUI
import MultipeerConnectivity

struct AvailableUsersView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    
    private var availablePeers: [String:MCPeerID] {
        return sessionManager.availablePeers.filter {
            !sessionManager.uuidIsPaired($0.key)
        }
    }
    
    var body: some View {
        VStack {
            Text("Searching for nearby users")
                .font(.caption)
                .padding(.top)
            ProgressView()
                .padding(.bottom)
                .progressViewStyle(.circular)
                .tint(.green)
            List(Array(availablePeers.keys), id: \.self) { peerUUID in
                if let peerID = availablePeers[peerUUID] {
                    UserCard(
                        username: peerID.displayName,
                        uuid: peerUUID,
                        action: {
                            sessionManager.sendInvite(peerID)
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
