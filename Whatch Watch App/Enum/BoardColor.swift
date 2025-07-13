//
//  BoardColor.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/8/25.
//

import SwiftUI

enum BoardColor: String, CaseIterable, Identifiable {
    case clear, gray1, gray2, gray3, gray4, gray5, gray6

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .clear: return .clear
        case .gray1: return Color.gray.opacity(0.1)
        case .gray2: return Color.gray.opacity(0.25)
        case .gray3: return Color.gray.opacity(0.4)
        case .gray4: return Color.gray.opacity(0.6)
        case .gray5: return Color.gray.opacity(0.8)
        case .gray6: return Color.gray
        }
    }

    var label: String {
        if self == .clear { return "Clear" }
        return "Gray \(rawValue.filter(\.isNumber))"
    }

    var nextColor: BoardColor {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return .gray1 }
        let nextIndex = (index + 1) % all.count
        return all[nextIndex]
    }
}

