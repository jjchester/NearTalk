//
//  SigninView.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-07.
//

import SwiftUI

struct SigninView: View {
    @State var username: String = ""
    var buttonColor: Color {
        return username.count == 0 ? .gray.opacity(0.5) : .green
    }
    
    var body: some View {
        Text("Enter a username")
            .font(.title3)
        
        HStack {
            TextField(text: $username) {
                Text("John Doe")
            }
            .frame(maxWidth: 200)
            .padding()
            .addBorder(.black, cornerRadius: 12)
            Button {
                withAnimation {
                    SessionManager.shared.setup(username: username, uuid: nil)
                }
            } label: {
                Image(systemName: "arrow.right.circle")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(buttonColor)
            }
            .disabled(username.count == 0)
        }
        .padding([.top, .bottom])    }
}

#Preview {
    SigninView()
}
