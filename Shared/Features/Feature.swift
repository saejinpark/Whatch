//
//  Feature.swift
//  Whatch
//

import Foundation

/// Everything the app can show. Raw values are persisted in `@AppStorage`, so keep them stable.
enum Feature: String, CaseIterable, Identifiable {
    // Watch only
    case accelerometer
    case rollTrackerX
    case rollTrackerY
    case vibrationDetector
    case watchBoard
    // iPhone + Watch
    case pingTest
    case flashlight
    case hapticController
    case headingMonitor
    case batteryStatus

    enum Group: CaseIterable, Identifiable {
        case watchOnly
        case paired

        var id: Self { self }

        var title: String {
            switch self {
            case .watchOnly: "Watch"
            case .paired: "Phone + Watch"
            }
        }

        var features: [Feature] {
            Feature.allCases.filter { $0.group == self }
        }
    }

    /// Groups that make sense on the running platform.
    static var availableGroups: [Group] {
        #if os(watchOS)
        Group.allCases
        #else
        [.paired]
        #endif
    }

    var id: String { rawValue }

    var group: Group {
        switch self {
        case .accelerometer, .rollTrackerX, .rollTrackerY, .vibrationDetector, .watchBoard:
            .watchOnly
        case .pingTest, .flashlight, .hapticController, .headingMonitor, .batteryStatus:
            .paired
        }
    }

    var title: String {
        switch self {
        case .accelerometer: "워치 가속도계"
        case .rollTrackerX: "회전측정기 (가로)"
        case .rollTrackerY: "회전측정기 (세로)"
        case .vibrationDetector: "떨림 감지기"
        case .watchBoard: "와치보드"
        case .pingTest: "핑 테스트"
        case .flashlight: "라이트"
        case .hapticController: "진동기"
        case .headingMonitor: "방향 확인기"
        case .batteryStatus: "배터리 확인"
        }
    }

    var detail: String {
        switch self {
        case .accelerometer: "팔을 힘껏 내질러 보세요"
        case .rollTrackerX: "가로 방향으로 회전시켜 보세요."
        case .rollTrackerY: "세로 방향으로 회전해보세요."
        case .vibrationDetector: "흔들어보세요."
        case .watchBoard: "그림을 그려보세요"
        case .pingTest: "워치와 아이폰이 잘 연결되는지 테스트해보세요."
        case .flashlight: "워치로 아이폰의 손전등을 켜보세요"
        case .hapticController: "아이폰의 진동을 워치에서 직접 제어해보세요."
        case .headingMonitor: "\(Device.counterpartSubject) 향하고 있는 방향을 각도로 표시합니다."
        case .batteryStatus: "아이폰의 배터리 잔량을 워치에서 확인해보세요."
        }
    }

    var systemImage: String {
        switch self {
        case .accelerometer: "speedometer"
        case .rollTrackerX: "arrow.left.arrow.right.circle"
        case .rollTrackerY: "arrow.up.arrow.down.circle"
        case .vibrationDetector: "waveform"
        case .watchBoard: "square.grid.3x3"
        case .pingTest: "dot.radiowaves.left.and.right"
        case .flashlight: "flashlight.on.fill"
        case .hapticController: "waveform.path"
        case .headingMonitor: "location.north.line"
        case .batteryStatus: "battery.100"
        }
    }
}
