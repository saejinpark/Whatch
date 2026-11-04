//
//  HapticStatus.swift
//  Whatch
//

import SwiftUI

enum HapticStatus: LockUpItem {
    case playing
    case stopped

    init(isPlaying: Bool) {
        self = isPlaying ? .playing : .stopped
    }

    var title: String {
        switch self {
        case .playing: "진동 재생 중"
        case .stopped: "진동 꺼짐"
        }
    }

    var systemImage: String {
        switch self {
        case .playing: "waveform.path.ecg"
        case .stopped: "waveform.path"
        }
    }

    var tint: Color {
        switch self {
        case .playing: .mint
        case .stopped: .secondary
        }
    }
}
