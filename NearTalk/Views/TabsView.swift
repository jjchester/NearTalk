//
//  Tabs.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-06-07.
//

import SwiftUI

struct TabsView: View {
    @State var selection = 1
    @ObservedObject var sessionManager = SessionManager.shared
    
    var body: some View {
        NavigationView {
            TabView(selection: $selection) {
                ConversationsView()
                    .tabItem {
                        Label("Messages", systemImage: "message")
                    }
                    .tag(1)
                AvailableUsersView()
                    .navigationTitle("Available Users")
                    .tabItem {
                        Label("Find Users", systemImage: "person.badge.plus")
                    }
                    .tag(2)
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Received an invite from \(sessionManager.recvdInviteFrom?.displayName ?? "ERR")!", isPresented: $sessionManager.recvdInvite) {
            Button("Accept invite") {
                sessionManager.acceptInvite()
            }
            Button("Reject invite") {
                sessionManager.declineInvite()
            }
            .addBorder(.blue, cornerRadius: 10)
        }
    }
    private var title: String {
        switch selection {
        case 1:
            return "Messages"
        case 2:
            return "Find Users"
        case 3:
            return "Settings"
        default:
            return ""
        }
    }
}

#Preview {
    TabsView()
}
