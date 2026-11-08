//
//  Feature.swift
//  Whatch
//

import Foundation

/// Everything the app can do. Raw values are used in deep links, so keep them stable.
enum Feature: String, CaseIterable, Identifiable, Sendable {
    // Watch only
    case impact
    case rotation
    case vibration
    case board
    // iPhone + Watch
    case ping
    case flashlight
    case haptic
    case heading
    case battery

    enum Group: CaseIterable, Identifiable, Sendable {
        case watchOnly
        case paired

        var id: Self { self }

        var title: String {
            switch self {
            case .watchOnly: "워치 단독"
            case .paired: "아이폰 연동"
            }
        }

        var features: [Feature] {
            Feature.allCases.filter { $0.group == self }
        }
    }

    var id: String { rawValue }

    var group: Group {
        switch self {
        case .impact, .rotation, .vibration, .board: .watchOnly
        case .ping, .flashlight, .haptic, .heading, .battery: .paired
        }
    }

    var title: String {
        switch self {
        case .impact: "가속도계"
        case .rotation: "회전 측정기"
        case .vibration: "떨림 감지기"
        case .board: "와치보드"
        case .ping: "핑 테스트"
        case .flashlight: "손전등"
        case .haptic: "진동기"
        case .heading: "방향 확인기"
        case .battery: "배터리"
        }
    }

    var detail: String {
        switch self {
        case .impact: "팔을 힘껏 내질러 보세요"
        case .rotation: "손목 회전 각도 누적"
        case .vibration: "손목 떨림을 그래프로"
        case .board: "손가락과 크라운으로 그리기"
        case .ping: "두 기기 사이의 응답 속도"
        case .flashlight: "워치로 아이폰 손전등 켜기"
        case .haptic: "워치로 아이폰 진동 울리기"
        case .heading: "두 기기가 향한 방향 비교"
        case .battery: "두 기기의 배터리 잔량"
        }
    }

    var systemImage: String {
        switch self {
        case .impact: "speedometer"
        case .rotation: "arrow.triangle.2.circlepath"
        case .vibration: "waveform.path.ecg"
        case .board: "square.grid.3x3.fill"
        case .ping: "dot.radiowaves.left.and.right"
        case .flashlight: "flashlight.on.fill"
        case .haptic: "iphone.radiowaves.left.and.right"
        case .heading: "location.north.line.fill"
        case .battery: "battery.75percent"
        }
    }
}
