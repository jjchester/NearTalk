import MultipeerConnectivity

class PeerSession: NSObject, MCSessionDelegate, ObservableObject {
    
    let peerID: MCPeerID
    let session: MCSession
    lazy var pairedPeer = session.connectedPeers[0]
    weak var delegate: PeerSessionDelegate?
    
    init(peerID: MCPeerID) {
        self.peerID = peerID
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
    }
    
    func acceptInvite() {
        // Accept the invite for this session
    }
    
    func sendMessage(_ message: Data) {
        do {
            try session.send(message, toPeers: [pairedPeer], with: .reliable)
        } catch {
            print("Failed to send message to peer.")
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        switch state {
        case MCSessionState.notConnected:
            print("Peer \(peerID.displayName) has disconnected")
            break
        case MCSessionState.connected:
            print("Peer \(peerID.displayName) has connected")
            delegate?.addChatSession(self)
            break
        default:
            // Peer connecting or something else
//            DispatchQueue.main.async {
//                self.paired = false
//            }
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Received message:")
        print(data)
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

protocol PeerSessionDelegate: AnyObject {
    func  addChatSession(_ session: PeerSession)
    func removeChatSession(with peer: MCPeerID)
}
