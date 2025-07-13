//
//  HapticStatus.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/12/25.
//

import SwiftUI

enum HapticStatus: LockUpItem {
    case playing
    case stopped

    var description: String {
        switch self {
        case .playing: return "진동 재생 중"
        case .stopped: return "진동 꺼짐"
        }
    }

    var systemImage: String {
        switch self {
        case .playing: return "waveform.path.ecg"
        case .stopped: return "waveform.path"
        }
    }

    var color: Color {
        switch self {
        case .playing: return .mint
        case .stopped: return .secondary
        }
    }
}
