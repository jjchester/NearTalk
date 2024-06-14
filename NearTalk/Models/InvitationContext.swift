//
//  InvitationContext.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-12.
//

import Foundation

class InvitationContext: NSObject, Codable, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(context, forKey: "context")
    }
    
    required init?(coder: NSCoder) {
        guard let context = coder.decodeObject(forKey: "context") as? [String : String] else {
            return nil
        }
        self.context = context
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case context
    }
    
    let context: [String : String]
    init(context: [String : String]) {
        self.context = context
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.context = try container.decode([String : String].self, forKey: .context)
    }
}
