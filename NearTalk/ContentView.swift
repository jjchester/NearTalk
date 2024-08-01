//
//  ContentView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-06.
//

import SwiftUI
import MultipeerConnectivity


struct ContentView: View {
    
    @ObservedObject var sessionManager = SessionManager.shared
    @State var text: String = ""
    let defaults = UserDefaults.standard
    
    init() {
        let username = defaults.string(forKey: Constants.SESSION_USERNAME)
        let uuid = defaults.string(forKey: Constants.SESSION_UUID)
        if let username = username, let uuid = uuid {
            SessionManager.shared.setup(username: username, uuid: uuid)
        }
    }
        
    var body: some View {
        VStack {
            if sessionManager.isSetup {
                TabsView()
            } else {
                SigninView()
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut, value: sessionManager.isSetup)
    }
}

#Preview {
    ContentView()
}
