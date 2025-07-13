//
//  Status.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

enum PingStatus: LockUpItem {
    case good
    case bad
    case pending
    case unknown

    var description: String {
        switch self {
        case .good: return "연결 양호"
        case .bad: return "연결 불량"
        case .pending: return "대기 중"
        case .unknown: return "알 수 없음"
        }
    }

    var systemImage: String {
        switch self {
        case .good: return "checkmark.circle"
        case .bad: return "xmark.octagon"
        case .pending: return "hourglass"
        case .unknown: return "questionmark"
        }
    }

    var color: Color {
        switch self {
        case .good: return .green
        case .bad: return .red
        case .pending: return .gray
        case .unknown: return .clear
        }
    }
}
