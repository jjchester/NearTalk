import Foundation

struct Message: Codable, Hashable {
    let senderUuid: String
    let type: MessageType
    let data: [String: String]
    let timeCreated: Date
    var timeReceived: Date? = nil
    let uuid: String
    var status: MessageStatus
    
    init(type: MessageType, data: [String : String], senderUuid: String) {
        self.senderUuid = senderUuid
        self.type = type
        self.data = data
        self.timeCreated = Date.now
        self.uuid = UUID().uuidString
        self.status = .pending
    }
    
    enum MessageType: String, Codable {
        case acknowledgement
        case disconnect
        case text
        case handshake
    }
    
    enum MessageStatus: String, Codable {
        case pending
        case acknowledged
        case failed
    }
}
