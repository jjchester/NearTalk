import MultipeerConnectivity

class PeerSession: NSObject, MCSessionDelegate, ObservableObject {
    
    let peerID: MCPeerID
    let session: MCSession
    let uuid: String
    var pairedPeer: MCPeerID?
    var pairedPeerUUID: String?
    weak var delegate: PeerSessionDelegate?
    @Published var messages: [String:Message] = [:] // UUID : Message
    
    init(peerID: MCPeerID, uuid: String) {
        self.peerID = peerID
        self.uuid = uuid
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
    }
    
    private func loadMessages() {
        // load from swiftdata storage?
    }
    
    func sendMessage(_ message: Message) {
        do {
            guard let pairedPeer = self.pairedPeer, let encodedMessage = encodeMessage(message) else { return }
            try session.send(encodedMessage, toPeers: [pairedPeer], with: .reliable)
            if message.type == .text {
                self.messages[message.uuid] = message
            }
        } catch {
            print("Failed to send message to peer.")
        }
    }
    
    func sendConnectionHandshake() {
        do {
            guard let pairedPeer = self.pairedPeer else { return } // need to handle else more gracefully
            let message = Message(type: .handshake, data: [Constants.UUID: self.uuid], senderUuid: self.uuid)
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
            self.sendConnectionHandshake()
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
        case .handshake:
            if let uuid = message.data[Constants.UUID] {
                print("Received acknowledgement from UUID: \(uuid)")
                self.pairedPeerUUID = uuid
                delegate?.removePeerFromSearch(for: uuid)
                delegate?.saveConnectedPeer(for: uuid)
            }
        case .disconnect:
            if let _ = message.data[Constants.DISCONNECT] {
                print("Received disconnect from \(self.pairedPeerUUID ?? "")")
                delegate?.removeSavedPeer(for: self.pairedPeerUUID ?? "")
                delegate?.disconnectChatSession(for: self)
            }
        case .text:
            if let text = message.data[Constants.TEXT] {
                print("Received Text: \(text)")
                let acknowledgementMessage = Message(type: .acknowledgement, data: [Constants.UUID:message.uuid], senderUuid: self.uuid)
                sendMessage(acknowledgementMessage)
                DispatchQueue.main.async {
                    self.messages[message.uuid] = message
                    self.messages[message.uuid]?.status = .acknowledged
                }
            }
        case .acknowledgement:
            if let uuid = message.data[Constants.UUID] {
                print("Received acknowledgement for message with UUID \(uuid)")
                DispatchQueue.main.async {
                    self.messages[uuid]?.status = .acknowledged
                }
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
        do {
            let message = try encoder.encode(message)
            return message
        } catch {
            print("Failed to encode outgoing message with UUID: \(message.uuid)")
            return nil
        }
    }

    // Decode Data to a Message
    func decodeMessage(_ data: Data) -> Message? {
        let decoder = JSONDecoder()
        do {
            let message = try decoder.decode(Message.self, from: data)
            return message
        } catch {
            print("Failed to decode incoming message")
            return nil
        }
    }

    func syncMessages() async {
        // some kind of job that takes the union of both sesssions' messages in case of desync and then publishes?
        // I think better than intersecting and potentially losing messages
        // Needs to be batched by timestamp, maybe some other scaling techniques
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
