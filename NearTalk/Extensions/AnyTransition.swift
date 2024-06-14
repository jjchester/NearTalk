//
//  AnyTransition.swift
//  NearTalk
//
//  Created by Justin Chester on 2024-06-06.
//

import SwiftUI

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
    }
}
