//
//  ChatSession.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-06.
//

import Foundation
import MultipeerConnectivity

class ChatSession: NSObject, ObservableObject {
    public static let shared = ChatSession()
    private let serviceType = "neartalk"
    private lazy var peerID = MCPeerID(displayName: username)
    private var knownPeers: [MCPeerID] = []

    private var username: String = ""
    @Published var isSetup: Bool = false
    

    public lazy var serviceAdvertiser: MCNearbyServiceAdvertiser = {
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        return advertiser
    }()
    
    public lazy var serviceBrowser: MCNearbyServiceBrowser = {
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
        return browser
    }()
    
    public lazy var session: MCSession = {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    @Published var availablePeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedMessage: String = ""
    @Published var recvdInvite: Bool = false
    @Published var recvdInviteFrom: MCPeerID? = nil
    @Published var paired: Bool = false
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var conversations: [MCPeerID: [Message]] = [:]
    
    public func setup(username: String) {
        self.username = username
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
        self.isSetup = true
    }
    
    private func loadKnownPeers() {
        // Load known peers from persistent storage
        // Example using UserDefaults:
        if let data = UserDefaults.standard.data(forKey: "knownPeers") {
            let peers = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: MCPeerID.self, from: data)
            knownPeers = peers ?? []
        }
    }
    
    private func saveKnownPeers() {
        // Save known peers to persistent storage
        // Example using UserDefaults:
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: [self.knownPeers], requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "knownPeers")
        }
    }
    
    private override init() {
        super.init()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func sendMessage(message: String, receivingPeer: [MCPeerID]) {
        if self.connectedPeers.contains(receivingPeer) {
            do {
                let payload = Message(
                    uniqueID: "\(self.peerID.displayName)_\(Int(Date().timeIntervalSince1970))",
                    content: message,
                    timestamp: Date(),
                    peerIDData: try! NSKeyedArchiver.archivedData(withRootObject: self.peerID, requiringSecureCoding: true),
                    type: .text
                )
                let payloadData = try! JSONEncoder().encode(payload)
                try session.send(payloadData, toPeers: receivingPeer, with: .reliable)
            } catch {
                print("Error sending message")
            }
        }
    }
}

extension ChatSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        switch state {
        case MCSessionState.notConnected:
            // Peer disconnected
            DispatchQueue.main.async {
                self.paired = false
            }
            // Peer disconnected, start accepting invitaions again
            serviceAdvertiser.startAdvertisingPeer()
            break
        case MCSessionState.connected:
            // Peer connected
            DispatchQueue.main.async {
                self.paired = true
                self.connectedPeers.append(peerID)
                self.availablePeers.removeAll(where: {$0 == peerID})
            }
            // We are paired, stop accepting invitations
            serviceAdvertiser.stopAdvertisingPeer()
            break
        default:
            // Peer connecting or something else
            DispatchQueue.main.async {
                self.paired = false
            }
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let message = try! JSONDecoder().decode(Message.self, from: data)
        let senderPeerID = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: message.peerIDData)
        if let senderPeerID = senderPeerID {
            switch message.type {
            case .text:
                print("Received text message from \(senderPeerID.displayName): \(message.content)")
                
                DispatchQueue.main.async {
                    self.conversations[peerID, default: []].append(message)
                }
                // Send acknowledgement message
                sendAcknowledgementMessage(to: senderPeerID, forMessage: message.uniqueID)
            case .media:
                // Handle media message
                break
            case .acknowledgement:
                print("Received acknowledgement for message: \(message.content)")
            }
        } else {
            print("Failed to decode message sender MCPeerID")
        }
    }

    func sendAcknowledgementMessage(to peer: MCPeerID, forMessage messageID: String) {
        let acknowledgementMessage = Message(
            uniqueID: "\(self.peerID.displayName)_\(Int(Date().timeIntervalSince1970))",
            content: messageID, // Use the original message's unique ID as the content
            timestamp: Date(),
            peerIDData: try! NSKeyedArchiver.archivedData(withRootObject: self.peerID, requiringSecureCoding: true),
            type: .acknowledgement
        )
        
        do {
            let messageData = try JSONEncoder().encode(acknowledgementMessage)
            try session.send(messageData, toPeers: [peer], with: .reliable)
        } catch {
            print("Error sending acknowledgement message: \(error)")
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Receiving streams is not supported")
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Receiving resources is not supported")
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Receiving resources is not supported")
    }
    
    public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

extension ChatSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from peer \(peerID)")
        if knownPeers.contains(peerID) {
            // Automatically accept invitation for known peers
            invitationHandler(true, self.session)
        } else {
            DispatchQueue.main.async {
                // Tell PairView to show the invitation alert
                self.recvdInvite = true
                // Give PairView the peerID of the peer who invited us
                self.recvdInviteFrom = peerID
                // Give PairView the `invitationHandler` so it can accept/deny the invitation
                self.invitationHandler = invitationHandler
            }
        }
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }
}

extension ChatSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        //TODO: Tell the user something went wrong and try again
        print("ServiceBroser didNotStartBrowsingForPeers: \(String(describing: error))")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("ServiceBrowser found peer: \(peerID)")
        // Add the peer to the list of available peers
        DispatchQueue.main.async {
            self.availablePeers.append(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("ServiceBrowser lost peer: \(peerID)")
        // Remove lost peer from list of available peers
        DispatchQueue.main.async {
            self.availablePeers.removeAll(where: {
                $0 == peerID
            })
        }
    }
}
