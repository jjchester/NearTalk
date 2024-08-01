import MultipeerConnectivity

class PeerSession: NSObject, MCSessionDelegate, ObservableObject {
    
    let peerID: MCPeerID
    let session: MCSession
    let uuid: String
    var pairedPeer: MCPeerID?
    var pairedPeerUUID: String?
    weak var delegate: PeerSessionDelegate?
    
    init(peerID: MCPeerID, uuid: String) {
        self.peerID = peerID
        self.uuid = uuid
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
    }
    
    func sendMessage(_ message: Message) {
        do {
            guard let pairedPeer = self.pairedPeer, let encodedMessage = encodeMessage(message) else { return }
            try session.send(encodedMessage, toPeers: [pairedPeer], with: .reliable)
        } catch {
            print("Failed to send message to peer.")
        }
    }
    
    func sendConnectionAcknowledgement() {
        do {
            guard let pairedPeer = self.pairedPeer else { return } // need to handle else more gracefully
            let message = Message(type: .acknowledgement, data: [Constants.UUID: self.uuid])
            if let encodedMessage = encodeMessage(message) {
                try session.send(encodedMessage, toPeers: [pairedPeer], with: .reliable)
            }
            else {
                // failure case
            }
        } catch {
            print("Failed to send message to peer.")
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        switch state {
        case MCSessionState.notConnected:
            print("Peer \(peerID.displayName) has disconnected")
            delegate?.disconnectChatSession(for: self)
            break
        case MCSessionState.connected:
            print("Peer \(peerID.displayName) has connected")
            delegate?.connectChatSession(for: self)
            delegate?.removePendingInvite(for: self)
            self.pairedPeer = peerID
            self.sendConnectionAcknowledgement()
            break
        default:
            // Peer connecting or something else
            //            DispatchQueue.main.async {
            //                self.paired = false
            //            }
            break
        }
    }
    
    
    func handleMessage(_ message: Message) {
        switch message.type {
        case .acknowledgement:
            if let uuid = message.data[Constants.UUID] {
                print("Received UUID: \(uuid)")
                self.pairedPeerUUID = uuid
                delegate?.removePeerFromSearch(for: uuid)
                delegate?.saveConnectedPeer(for: uuid)
            }
        case .disconnect:
            if let disconnect = message.data[Constants.DISCONNECT] {
                print("Received disconnect")
                delegate?.removeSavedPeer(for: self.pairedPeerUUID ?? "")
                delegate?.disconnectChatSession(for: self)
            }
        case .text:
                if let text = message.data[Constants.TEXT] {
                print("Received Text: \(text)")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Received message")
        if let message = decodeMessage(data) {
            handleMessage(message)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("Receiving streams is not supported")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("Receiving resources is not supported")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("Receiving Resources is not supported")
    }
}

extension PeerSession {
    // Encode a Message to Data
    func encodeMessage(_ message: Message) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(message)
    }

    // Decode Data to a Message
    func decodeMessage(_ data: Data) -> Message? {
        let decoder = JSONDecoder()
        return try? decoder.decode(Message.self, from: data)
    }

}

protocol PeerSessionDelegate: AnyObject {
    func connectChatSession(for session: PeerSession)
    func disconnectChatSession(for session: PeerSession)
    func removePendingInvite(for session: PeerSession)
    func removePeerFromSearch(for uuid: String)
    func saveConnectedPeer(for uuid: String)
    func removeSavedPeer(for uuid: String)
}
