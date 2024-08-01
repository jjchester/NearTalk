import Foundation

struct Message: Codable {
    let type: MessageType
    let data: [String: String]
    
    enum MessageType: String, Codable {
        case acknowledgement
        case disconnect
        case text
//        case command
    }
}
