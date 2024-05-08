//
//  ContentView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-06.
//

import SwiftUI
import MultipeerConnectivity


struct ContentView: View {
    
    @ObservedObject var session = ChatSession.shared
    @State var text: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if session.isSetup {
                    VStack {
                        AvailableUsersView()
                    }
                } else {
                    SigninView()
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.easeInOut, value: session.isSetup)
        .alert("Received an invite from \(session.recvdInviteFrom?.displayName ?? "ERR")!", isPresented: $session.recvdInvite) {
            Button("Accept invite") {
                if (session.invitationHandler != nil) {
                    session.invitationHandler!(true, session.session)
                }
            }
            Button("Reject invite") {
                if (session.invitationHandler != nil) {
                    session.invitationHandler!(false, nil)
                }
            }
            .addBorder(.blue, cornerRadius: 10)
        }
    }
}

#Preview {
    ContentView()
}
