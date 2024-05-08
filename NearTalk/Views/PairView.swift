//
//  PairView.swift
//  RPS
//
//  Created by Joe Diragi on 7/29/22.
//

import SwiftUI
import os

struct PairView: View {
    @StateObject var rpsSession: ChatSession
    var logger = Logger()
        
    var body: some View {
        if (!rpsSession.paired) {
            HStack {
                List(rpsSession.availablePeers, id: \.self) { peer in
                    Button {
                        print(peer.displayName)
                        rpsSession.serviceBrowser.invitePeer(peer, to: rpsSession.session, withContext: nil, timeout: 30)
                    } label: {
                        Text("\(peer.displayName)")
                    }
                }
                .alert("Received an invite from \(rpsSession.recvdInviteFrom?.displayName ?? "ERR")!", isPresented: $rpsSession.recvdInvite) {
                    Button("Accept invite") {
                        if (rpsSession.invitationHandler != nil) {
                            rpsSession.invitationHandler!(true, rpsSession.session)
                        }
                    }
                    Button("Reject invite") {
                        if (rpsSession.invitationHandler != nil) {
                            rpsSession.invitationHandler!(false, nil)
                        }
                    }
                    .addBorder(.blue, cornerRadius: 10)
                }
            }
        } else {
            Text("Paired")
            Button("Disconnect") {
                rpsSession.paired = false
            }
                .foregroundStyle(.red)
        }
    }
}
