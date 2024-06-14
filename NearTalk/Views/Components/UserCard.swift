import SwiftUI

struct UserCard: View {
    var username: String
    var uuid: String
    var action: () -> Void
    
    @State private var isDisabled: Bool = false
    @State private var cooldownTimer: Timer?
    @State private var remainingCooldown: Int = 0

    private var animatedPeriods: String {
        let numberOfPeriods = (30 - remainingCooldown) % 4
        return String(repeating: ".", count: numberOfPeriods)
    }
    
    var body: some View {
        ZStack {
            Button(action: {
                if !isDisabled {
                    action()
                    startCooldown()
                }
            }) {
                VStack(alignment: .leading) {
                    Text(username)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(uuid)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled)
            if isDisabled {
                VStack {
                    Text("Awaiting response\(animatedPeriods)")
                        .font(.caption)
                        .animation(.default, value: animatedPeriods)
                    Text("\(remainingCooldown)s")
                        .font(.caption)

                }
            }
        }
        .listRowSeparator(.hidden)
    }

    private func startCooldown() {
        isDisabled = true
        remainingCooldown = 30
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if remainingCooldown > 0 {
                remainingCooldown -= 1
            } else {
                isDisabled = false
                timer.invalidate()
            }
        }
    }
}

struct UserCard_Previews: PreviewProvider {
    static var previews: some View {
        UserCard(username: "JohnDoe", uuid: "123e4567-e89b-12d3-a456-426614174000", action: {})
            .previewLayout(.sizeThatFits)
    }
}
