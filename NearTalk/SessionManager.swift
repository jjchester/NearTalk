import MultipeerConnectivity
import SwiftUI

class SessionManager: NSObject, ObservableObject {
    
    enum SessionStatus {
        case connected
        case disconnected
    }
    
    static let shared = SessionManager()
    //    private var sessions: [MCPeerID: PeerSession] = [:]
    //    private var knownUUIDs: Set<String> = []
    private var pendingInvites: [PeerSession: Timer] = [:]
    
    private let serviceType = "neartalk"
    private let defaults = UserDefaults.standard
    private lazy var username: String = ""
    private lazy var uuid: String = ""
    private lazy var discoveryInfo: [String: String] = [:]
    private var pendingSessions: [PeerSession] = []
    private var pairedUUIDs: [String] {
        return pairedSessions.map { (key: PeerSession, value: SessionStatus) in
            return key.uuid
        }
    }
    
    @Published var pairedSessions: [PeerSession: SessionStatus] = [:]
    @Published var availablePeers: [String: MCPeerID] = [:] // Peers that are available to connect with but not currently paired
    @Published var savedPeers: Set<String> = [] // Peers that have been paired with but may not necessarily have an active connection
    // Peers that are paired and have an active connection can be accessed through the session object
    @Published var recvdInvite: Bool = false
    @Published var recvdInviteFrom: MCPeerID? = nil
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var conversations: [String: [Message]] = [:]
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
            Constants.SESSION_USERNAME : username,
            Constants.SESSION_UUID: uuid
        ]
        
        if let peers = defaults.array(forKey: Constants.SAVED_PEERS) as? [String] {
            print("Discovered saved peers: \(peers)")
            self.savedPeers = Set(peers)
        }
        
        defaults.setValue(username, forKey: Constants.SESSION_USERNAME)
        defaults.setValue(uuid, forKey: Constants.SESSION_UUID)
        
        restartAdvertisingAndBrowsing()
        self.isSetup = true
    }
    
    public func resetSessionDetails() {
        DispatchQueue.main.async {
            self.username = ""
            self.uuid = ""
            self.discoveryInfo = [:]
            self.availablePeers = [:]
            self.pairedSessions.keys.forEach { session in
                session.session.disconnect()
            }
            self.pairedSessions = [:]
            self.savedPeers = []
            self.defaults.removeObject(forKey: Constants.SESSION_USERNAME)
            self.defaults.removeObject(forKey: Constants.SESSION_UUID)
            self.defaults.removeObject(forKey: Constants.SAVED_PEERS)
            self.stopAdvertisingAndBrowsing()
            self.isSetup = false
        }
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
            let peerSession = PeerSession(peerID: self.peerID, uuid: self.uuid)
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
        let peerSession = PeerSession(peerID: self.peerID, uuid: self.uuid)
        peerSession.delegate = self
        addPendingSession(peerSession)
        let context = InvitationContext(context: [Constants.SESSION_UUID : self.uuid])
        let encodedContext = try! JSONEncoder().encode(context)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.invitationDidTimeout(for: peerSession)
        }
        pendingInvites[peerSession] = timer
        serviceBrowser.invitePeer(peerID, to: peerSession.session, withContext: encodedContext, timeout: 30)
    }
    
    func invitationDidTimeout(for session: PeerSession) {
        print("Invitation to \(session.peerID.displayName) timed out.")
        pendingInvites[session]?.invalidate()
        pendingInvites.removeValue(forKey: session)
    }
    
    public func peerIDforUUID(_ uuid: String) -> MCPeerID? {
        return availablePeers[uuid]
    }
    
    func removePeerID(peerID: MCPeerID) {
        if let key = self.availablePeers.first(where: { $0.value == peerID })?.key {
            DispatchQueue.main.async(qos: .userInitiated) {
                withAnimation {
                    _ = self.availablePeers.removeValue(forKey: key)
                }
            }
        }
    }
    
    func removePeerSession(_ session: PeerSession) {
        DispatchQueue.main.async(qos: .userInitiated) {
            withAnimation {
                self.unsavePeer(for: session.pairedPeerUUID ?? "")
                session.sendMessage(Message(type: .disconnect, data: [Constants.DISCONNECT:""], senderUuid: session.uuid))
                _ = self.pairedSessions.removeValue(forKey: session)
            }
        }
    }
    
    func uuidIsPaired(_ uuid: String) -> Bool {
        return pairedUUIDs.contains(uuid)
    }
    
    func addPendingSession(_ session: PeerSession) {
        DispatchQueue.main.async(qos: .userInitiated) {
            self.pendingSessions.append(session)
        }
    }
    
    func savePeer(for uuid: String) {
        DispatchQueue.main.async(qos: .userInitiated) {
            self.savedPeers.insert(uuid);
            self.defaults.set(Array(self.savedPeers), forKey: Constants.SAVED_PEERS)
        }
    }
    
    func unsavePeer(for uuid: String) {
        DispatchQueue.main.async(qos: .userInitiated) {
            self.savedPeers.remove(uuid);
            self.defaults.set(Array(self.savedPeers), forKey: Constants.SAVED_PEERS)
        }
    }
}

extension SessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        if let peerUUID = info?[Constants.SESSION_UUID] {
            print("with UUID: \(peerUUID)")
//            guard !self.pairedSessions.contains(where: { (key: PeerSession, value: SessionStatus) in
//                key.pairedPeerUUID == peerUUID
//            }) else { return }
            DispatchQueue.main.async {
                withAnimation {
                    if self.savedPeers.contains(peerUUID) && !self.pairedUUIDs.contains(peerUUID) {
                        self.sendInvite(peerID);
                    }
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
        if savedPeers.contains(context.context[Constants.SESSION_UUID]!) {
            print("Invitation from saved peer")
            // Automatically accept invitation for known peers
            let session = PeerSession(peerID: self.peerID, uuid: self.uuid)
            DispatchQueue.main.async {
                self.invitationHandler = invitationHandler
                self.acceptInvite()
            }
        } else {
            print("Invitation from new peer")
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
    
    func saveConnectedPeer(for uuid: String) {
        self.savePeer(for: uuid)
    }
    
    func removeSavedPeer(for uuid: String) {
        self.unsavePeer(for: uuid)
    }
    
    func removePendingInvite(for session: PeerSession) {
        guard self.pendingInvites[session] != nil else { return }
        DispatchQueue.main.async(qos: .userInitiated) {
            self.pendingInvites[session]?.invalidate()
            self.pendingInvites.removeValue(forKey: session)
        }
    }
    
    func connectChatSession(for session: PeerSession) {
        guard !self.pairedUUIDs.contains(session.uuid) else { return }
        DispatchQueue.main.async(qos: .userInitiated) {
            self.pairedSessions[session] = .connected
        }
    }
    
    func disconnectChatSession(for session: PeerSession) {
        DispatchQueue.main.async(qos: .userInitiated) {
            self.pairedSessions.removeValue(forKey: session)
        }
    }
    
    func removePeerFromSearch(for uuid: String) {
        DispatchQueue.main.async(qos: .userInitiated) {
            withAnimation(.easeInOut) {
                _ = self.availablePeers.removeValue(forKey: uuid)
            }
        }
    }
}
