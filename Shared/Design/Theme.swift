//
//  Theme.swift
//  Whatch
//

import SwiftUI

/// Sizes that differ between a wrist and a phone.
enum Layout {
    #if os(watchOS)
    static let heroFont: CGFloat = 34
    static let ringWidth: CGFloat = 8
    static let spacing: CGFloat = 6
    static let tilePadding: CGFloat = 3
    static let labelFont: Font = .caption
    static let footnoteFont: Font = .caption2
    static let tileValueFont: Font = .system(.headline, design: .rounded)
    static let cornerRadius: CGFloat = 12
    static let chartHeight: CGFloat = 40
    #else
    static let heroFont: CGFloat = 80
    static let ringWidth: CGFloat = 18
    static let spacing: CGFloat = 16
    static let tilePadding: CGFloat = 14
    static let labelFont: Font = .headline
    static let footnoteFont: Font = .subheadline
    static let tileValueFont: Font = .system(.title2, design: .rounded).weight(.semibold)
    static let cornerRadius: CGFloat = 20
    static let chartHeight: CGFloat = 160
    #endif
}

extension Color {
    /// Fill for tiles and cards.
    static var card: Color {
        #if os(watchOS)
        Color.white.opacity(0.12)
        #else
        Color(.secondarySystemGroupedBackground)
        #endif
    }
}

extension Feature {
    var tint: Color {
        switch self {
        case .impact: .red
        case .rotation: .orange
        case .vibration: .pink
        case .board: .purple
        case .ping: .teal
        case .flashlight: .yellow
        case .haptic: .mint
        case .heading: .cyan
        case .battery: .green
        }
    }
}

extension LinkStatus {
    var tint: Color {
        switch self {
        case .connecting: .secondary
        case .connected: .green
        case .needsForeground: .orange
        case .notPaired, .appMissing, .unreachable: .red
        }
    }
}

extension PingTracker.Status {
    var title: String {
        switch self {
        case .idle, .waiting: "응답 대기 중"
        case .connected: "연결 양호"
        case .lost: "응답 없음"
        }
    }

    var systemImage: String {
        switch self {
        case .idle, .waiting: "hourglass"
        case .connected: "checkmark.circle.fill"
        case .lost: "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .idle, .waiting: .secondary
        case .connected: .green
        case .lost: .red
        }
    }
}

extension BatteryReading.Band {
    var tint: Color {
        switch self {
        case .unknown: .secondary
        case .low: .red
        case .medium: .yellow
        case .high: .green
        }
    }
}

extension VibrationAnalyzer.Level {
    var tint: Color {
        switch self {
        case .calm: .green
        case .moving: .yellow
        case .intense: .red
        }
    }
}
