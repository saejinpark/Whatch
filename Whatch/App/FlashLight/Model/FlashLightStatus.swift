//
//  FlashLightStatus.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

enum FlashLightStatus: LockUpItem {
    case on
    case off

    var description: String {
        switch self {
        case .on: return "손전등 켜짐"
        case .off: return "손전등 꺼짐"
        }
    }

    var systemImage: String {
        switch self {
        case .on: return "flashlight.on.fill"
        case .off: return "flashlight.off.fill"
        }
    }

    var color: Color {
        switch self {
        case .on: return .orange
        case .off: return .secondary
        }
    }
}
