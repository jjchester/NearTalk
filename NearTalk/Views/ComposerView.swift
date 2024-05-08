import SwiftUI

struct ComposerView: View {
    @Binding var messageText: String
    let sendMessageHandler: () -> ()
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack {
                TextField("Message", text: $messageText,  axis: .vertical)
                    .lineLimit(1...10)
                    .padding(8)
            }
            .addBorder(.gray, width: 0.5, cornerRadius: 15)
            Button {
                sendMessageHandler()
                messageText = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
        }
        .padding([.leading, .trailing])
    }
}

#Preview {
    ComposerView(messageText: .constant("Test")) {
        
    }
}
