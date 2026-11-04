//
//  FlashlightStatus.swift
//  Whatch
//

import SwiftUI

enum FlashlightStatus: LockUpItem {
    case on
    case off

    init(isOn: Bool) {
        self = isOn ? .on : .off
    }

    var title: String {
        switch self {
        case .on: "손전등 켜짐"
        case .off: "손전등 꺼짐"
        }
    }

    var systemImage: String {
        switch self {
        case .on: "flashlight.on.fill"
        case .off: "flashlight.off.fill"
        }
    }

    var tint: Color {
        switch self {
        case .on: .orange
        case .off: .secondary
        }
    }
}
