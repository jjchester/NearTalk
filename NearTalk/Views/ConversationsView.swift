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
    
    var body: some View {
        VStack {
            List(sessionManager.activeSessions, id: \.self) { session in
                Text(session.pairedPeer.displayName)
                    .border(.black)
            }
        }
    }
}

#Preview {
    ConversationsView()
}
