//
//  DecodeError.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-05-09.
//

import Foundation

struct DecodeError: LocalizedError {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var errorDescription: String? {
        description
    }
}
