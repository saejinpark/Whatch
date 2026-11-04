//
//  BoardColor.swift
//  Whatch Watch App
//

import SwiftUI

/// Palette of the Watch Board. Raw values are stored in SwiftData, so keep them stable.
enum BoardColor: String, CaseIterable, Identifiable {
    case clear, gray1, gray2, gray3, gray4, gray5, gray6

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .clear: .clear
        case .gray1: .gray.opacity(0.1)
        case .gray2: .gray.opacity(0.25)
        case .gray3: .gray.opacity(0.4)
        case .gray4: .gray.opacity(0.6)
        case .gray5: .gray.opacity(0.8)
        case .gray6: .gray
        }
    }

    /// The palette entry after this one, wrapping around.
    var next: BoardColor {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }
}
