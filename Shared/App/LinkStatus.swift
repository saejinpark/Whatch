//
//  LinkStatus.swift
//  Whatch
//

import Foundation

/// Where the connection to the counterpart app stands, in terms the user can act on.
enum LinkStatus: Equatable {
    /// This device cannot pair with a Watch at all (iPad).
    case unsupported
    case connecting
    /// iPhone only: no Watch is paired with this phone.
    case notPaired
    /// The app is not installed on the other device.
    case appMissing
    /// The other device or its app cannot be reached right now.
    case unreachable
    /// Watch only: the iPhone answers, but its app is not on screen.
    case needsForeground
    case connected

    var isConnected: Bool {
        self == .connected
    }

    var title: String {
        switch self {
        case .unsupported: "워치 연결을 지원하지 않는 기기"
        case .connecting: "연결 확인 중"
        case .notPaired: "페어링된 워치 없음"
        case .appMissing: "\(Device.counterpartName)에 앱 없음"
        case .unreachable: "\(Device.counterpartName) 연결 안 됨"
        case .needsForeground: "\(Device.counterpartName) 앱이 닫혀 있음"
        case .connected: "\(Device.counterpartName) 연결됨"
        }
    }

    /// What to do about it, or `nil` when nothing needs doing.
    var advice: String? {
        switch self {
        case .connecting, .connected:
            nil
        case .unsupported:
            "Apple Watch 기능은 iPhone에서 사용할 수 있어요"
        case .notPaired:
            "Apple Watch를 페어링해 주세요"
        case .appMissing:
            "\(Device.counterpartName)에 Whatch를 설치해 주세요"
        case .unreachable:
            #if os(watchOS)
            "아이폰이 가까이 있는지 확인해 주세요"
            #else
            "워치에서 Whatch를 열어 주세요"
            #endif
        case .needsForeground:
            "아이폰에서 Whatch를 열어 주세요"
        }
    }

    var systemImage: String {
        switch self {
        case .unsupported: "applewatch.slash"
        case .connecting: "ellipsis.circle"
        case .connected: "checkmark.circle.fill"
        case .needsForeground: "exclamationmark.circle.fill"
        case .notPaired, .appMissing, .unreachable: "xmark.circle.fill"
        }
    }
}
