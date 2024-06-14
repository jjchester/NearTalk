import SwiftUI

struct SettingsView: View {
    let sessionManager = SessionManager.shared
    @State private var showingAlert = false

    var body: some View {
        VStack {
            Button(action: {
                showingAlert = true
            }) {
                Text("Reset Session")
                    .foregroundColor(.red)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Confirm Reset"),
                    message: Text("Are you sure you want to reset the session? This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        sessionManager.resetSessionDetails()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
