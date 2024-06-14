//
//  ChatSession.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-06.
//

import Foundation
import MultipeerConnectivity
import SwiftUI
import SwiftData


class ChatSession: NSObject, ObservableObject {
    public static let shared = ChatSession()
    public lazy var peerID = MCPeerID(displayName: username)

    private let serviceType = "neartalk"
    private let defaults = UserDefaults.standard
    private lazy var username: String = ""
    private lazy var uuid: String = ""
    private lazy var discoveryInfo: [String: String] = [:]
    
    public lazy var serviceAdvertiser: MCNearbyServiceAdvertiser = {
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
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
    
    @Published var availablePeers: [String: MCPeerID] = [:] // Peers that are available to connect with but not currently paired
    @Published var savedPeers: [String] = [] // Peers that have been paired with but may not necessarily have an active connection
                                                // Peers that are paired and have an active connection can be accessed through the session object
    @Published var recvdInvite: Bool = false
    @Published var recvdInviteFrom: MCPeerID? = nil
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var conversations: [String: [ConversationMessage]] = [:]
    @Published var isSetup: Bool = false

    public func setup(username: String, uuid: String?) {
        let uuid = uuid ?? UUID().uuidString
        
        self.uuid = uuid
        self.username = username
        
        self.discoveryInfo = [
            "session_username" : username,
            "session_uuid": uuid
        ]

        defaults.setValue(username, forKey: "session_username")
        defaults.setValue(uuid, forKey: "session_uuid")
        
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
        self.isSetup = true
    }
    
    public func resetSessionDetails() {
        DispatchQueue.main.async {
            self.savedPeers = []
            self.username = ""
            self.uuid = ""
            self.discoveryInfo = [:]
            self.availablePeers = [:]
        }
        defaults.removeObject(forKey: "session_username")
        defaults.removeObject(forKey: "session_uuid")
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        
        self.isSetup = false
    }
    
    public override init() {
        super.init()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func sendMessage(message: String, receivingPeer: MCPeerID) {
        if self.session.connectedPeers.contains(receivingPeer) {
            do {
                let payload = Message(
                    uniqueID: "\(self.peerID.displayName)_\(Int(Date().timeIntervalSince1970))",
                    content: message,
                    timestamp: Date(),
                    peerIDData: try! NSKeyedArchiver.archivedData(withRootObject: self.peerID, requiringSecureCoding: true),
                    type: .text
                )
                let payloadData = try! JSONEncoder().encode(payload)
                try session.send(payloadData, toPeers: [receivingPeer], with: .reliable)
                DispatchQueue.main.async {
//                    self.conversations[receivingPeer, default: []].append(ConversationMessage(message: payload, status: .pending))
                }
            } catch {
                print("Error sending message")
            }
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
    
    func updateMessageStatus(peerID: MCPeerID, messageID: String, newStatus: ConversationMessage.Status) {
         guard let conversation = conversations["test"] else {
             // Peer not found in conversations dictionary
             return
         }
         
         // Find the ConversationMessage with the specified message ID
         if let index = conversation.firstIndex(where: { $0.message.id == messageID }) {
             DispatchQueue.main.async {
                 // Update the status of the ConversationMessage
                 conversation[index].setStatus(status: newStatus)
                 
                 // Update the conversations dictionary
                 self.conversations["test"] = conversation
             }
         }
     }
    
    func invitePeer(peerID: MCPeerID) {
        let context = InvitationContext(context: ["session_uuid" : self.uuid])
        let encodedContext = try! JSONEncoder().encode(context)
        serviceBrowser.invitePeer(peerID, to: session, withContext: encodedContext, timeout: 30)
    }
    
    private func removePeer(peerID: MCPeerID) {
        // Find the key-value pair with the provided MCPeerID
        if let uuidToRemove = availablePeers.first(where: { $0.value == peerID })?.key {
            // Remove the key-value pair from the dictionary
            DispatchQueue.main.async {
                self.availablePeers.removeValue(forKey: uuidToRemove)
            }
            // Refresh UI table/list view to reflect changes
        }
    }
}

extension ChatSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        switch state {
        case MCSessionState.notConnected:
            print("Peer \(peerID.displayName) has disconnected")
            break
        case MCSessionState.connected:
            print("Peer \(peerID.displayName) has connected")
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
        let message = try! JSONDecoder().decode(Message.self, from: data)
        let senderPeerID = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: message.peerIDData)
        if let senderPeerID = senderPeerID {
            switch message.type {
            case .text:
                print("Received text message from \(senderPeerID.displayName): \(message.content)")
                
                DispatchQueue.main.async {
//                    self.conversations[peerID, default: []].append(ConversationMessage(message: message, status: .acknowledged))
                }
                // Send acknowledgement message
                sendAcknowledgementMessage(to: senderPeerID, forMessage: message.id)
            case .media:
                // Handle media message
                break
            case .acknowledgement:
                updateMessageStatus(peerID: peerID, messageID: message.content, newStatus: .acknowledged)
                print("Received acknowledgement for message: \(message.content)")
            }
        } else {
            print("Failed to decode message sender MCPeerID")
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
        let context = try! JSONDecoder().decode(InvitationContext.self, from: context!)
        if savedPeers.contains(context.context["session_uuid"]!) {
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
        let uuid = discoveryInfo["session_uuid"]!
        if savedPeers.contains(discoveryInfo["session_uuid"]!) {
            invitePeer(peerID: peerID)
        }
        // Add the peer to the list of available peers
        DispatchQueue.main.async {
            self.availablePeers[uuid] = peerID
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("ServiceBrowser lost peer: \(peerID)")
        // Remove lost peer from list of available peers
        removePeer(peerID: peerID)
    }
}
