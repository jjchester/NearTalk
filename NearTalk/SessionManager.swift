import MultipeerConnectivity
import SwiftUI

class SessionManager: NSObject, ObservableObject {
    
    static let shared = SessionManager()
    private var sessions: [MCPeerID: PeerSession] = [:]
    private var knownUUIDs: Set<String> = []
    private var pendingInvites: [MCPeerID: Timer] = [:]

    private let serviceType = "neartalk"
    private let defaults = UserDefaults.standard
    private lazy var username: String = ""
    private lazy var uuid: String = ""
    private lazy var discoveryInfo: [String: String] = [:]
    private var pendingSessions: [PeerSession] = []
    @Published var activeSessions: [PeerSession] = []
    @Published var availablePeers: [String: MCPeerID] = [:] // Peers that are available to connect with but not currently paired
    @Published var savedPeers: [String] = [] // Peers that have been paired with but may not necessarily have an active connection
                                                // Peers that are paired and have an active connection can be accessed through the session object
    @Published var recvdInvite: Bool = false
    @Published var recvdInviteFrom: MCPeerID? = nil
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var conversations: [String: [ConversationMessage]] = [:]
    @Published var isSetup: Bool = false
    
    public lazy var peerID = MCPeerID(displayName: username)

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
        
    public func setup(username: String, uuid: String?) {
        let uuid = uuid ?? UUID().uuidString

        self.uuid = uuid
        self.username = username
        self.peerID = MCPeerID(displayName: username)
        
        self.discoveryInfo = [
            "session_username" : username,
            "session_uuid": uuid
        ]

        defaults.setValue(username, forKey: "session_username")
        defaults.setValue(uuid, forKey: "session_uuid")
        
        restartAdvertisingAndBrowsing()
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
        stopAdvertisingAndBrowsing()
        
        self.isSetup = false
    }
    
    private func stopAdvertisingAndBrowsing() {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    private func setupAdvertiserAndBrowser() {
        self.serviceAdvertiser = {
            let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
            advertiser.delegate = self
            return advertiser
        }()
        
        self.serviceBrowser = {
            let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
            browser.delegate = self
            return browser
        }()
    }
    
    private func restartAdvertisingAndBrowsing() {
        stopAdvertisingAndBrowsing()
        setupAdvertiserAndBrowser()
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    public override init() {
        super.init()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    public func acceptInvite() {
        if let invitationHandler = self.invitationHandler {
            let peerSession = PeerSession(peerID: self.peerID)
            peerSession.delegate = self
            addPendingSession(peerSession)
            invitationHandler(true, peerSession.session)
            DispatchQueue.main.async {
                self.recvdInvite = false
                self.recvdInviteFrom = nil
                self.invitationHandler = nil
            }
        }
    }
    
    public func declineInvite() {
        if let invitationHandler = self.invitationHandler {
            invitationHandler(false, nil)
        }
    }
    
    public func sendInvite(_ peerID: MCPeerID) {
        let peerSession = PeerSession(peerID: self.peerID)
        peerSession.delegate = self
        addPendingSession(peerSession)
        let context = InvitationContext(context: ["session_uuid" : self.uuid])
        let encodedContext = try! JSONEncoder().encode(context)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.invitationDidTimeout(for: peerID)
        }
        pendingInvites[peerID] = timer
        serviceBrowser.invitePeer(peerID, to: peerSession.session, withContext: encodedContext, timeout: 30)
    }
    
    func invitationDidTimeout(for peerID: MCPeerID) {
        print("Invitation to \(peerID.displayName) timed out.")
        pendingInvites[peerID]?.invalidate()
        pendingInvites.removeValue(forKey: peerID)
    }
    
    public func peerIDforUUID(_ uuid: String) -> MCPeerID? {
        return availablePeers[uuid]
    }
    
    func removePeerID(peerID: MCPeerID) {
        // Find the key associated with the given MCPeerID
        if let key = self.availablePeers.first(where: { $0.value == peerID })?.key {
            // Remove the entry from the dictionary using the found key
            DispatchQueue.main.async {
                withAnimation {
                    _ = self.availablePeers.removeValue(forKey: key)
                }
            }
        }
    }
    
    func addPendingSession(_ session: PeerSession) {
        DispatchQueue.main.async {
            self.pendingSessions.append(session)
        }
    }
}

extension SessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        if let peerUUID = info?["session_uuid"] {
            print("with UUID: \(peerUUID)")
            DispatchQueue.main.async {
                withAnimation {
                    self.availablePeers[peerUUID] = peerID
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
        removePeerID(peerID: peerID)
    }
}

extension SessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let context = try! JSONDecoder().decode(InvitationContext.self, from: context!)
        if savedPeers.contains(context.context["session_uuid"]!) {
            // Automatically accept invitation for known peers
            let session = PeerSession(peerID: self.peerID)
            invitationHandler(true, session.session)
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
}

extension SessionManager: PeerSessionDelegate {
    func addChatSession(_ session: PeerSession) {
        DispatchQueue.main.async {
            self.activeSessions.append(session)
        }
    }
    
    func removeChatSession(with peer: MCPeerID) {
        // not implemented
    }
    
    
}
