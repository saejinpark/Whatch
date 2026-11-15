//
//  Feature.swift
//  Whatch
//

import Foundation

/// Everything the app can do. Raw values are used in deep links and messages, so keep them stable.
enum Feature: String, CaseIterable, Identifiable, Sendable {
    // Watch alone
    case impact
    case rotation
    case vibration
    case board
    // Remote control
    case flashlight
    case haptic
    case buzz
    case mirror
    // Play
    case controller
    case ballGame
    case airPointer
    case duel
    // Measure
    case ping
    case heading
    case battery
    case radar
    case heartRate
    case altitude

    enum Platform: Sendable {
        case watch
        case phone
    }

    enum Group: CaseIterable, Identifiable, Sendable {
        case watchOnly
        case remote
        case play
        case measure

        var id: Self { self }

        var title: String {
            switch self {
            case .watchOnly: "워치 단독"
            case .remote: "원격 제어"
            case .play: "놀이"
            case .measure: "측정"
            }
        }

        /// Whether the features in this group need the other device.
        var isPaired: Bool {
            self != .watchOnly
        }

        var features: [Feature] {
            Feature.allCases.filter { $0.group == self }
        }

        func features(on platform: Platform) -> [Feature] {
            features.filter { $0.isAvailable(on: platform) }
        }
    }

    var id: String { rawValue }

    var group: Group {
        switch self {
        case .impact, .rotation, .vibration, .board: .watchOnly
        case .flashlight, .haptic, .buzz, .mirror: .remote
        case .controller, .ballGame, .airPointer, .duel: .play
        case .ping, .heading, .battery, .radar, .heartRate, .altitude: .measure
        }
    }

    /// Whether this feature has a screen of its own on the platform.
    func isAvailable(on platform: Platform) -> Bool {
        switch self {
        case .impact, .rotation, .vibration, .board, .controller:
            platform == .watch
        case .buzz, .mirror, .ballGame, .airPointer:
            platform == .phone
        case .flashlight, .haptic, .duel, .ping, .heading, .battery, .radar, .heartRate, .altitude:
            true
        }
    }

    var title: String {
        switch self {
        case .impact: "가속도계"
        case .rotation: "회전 측정기"
        case .vibration: "떨림 감지기"
        case .board: "와치보드"
        case .flashlight: "손전등"
        case .haptic: "진동기"
        case .buzz: "워치 울리기"
        case .mirror: "와치보드 미러링"
        case .controller: "컨트롤러"
        case .ballGame: "공 굴리기"
        case .airPointer: "에어 포인터"
        case .duel: "반응속도 대결"
        case .ping: "핑 테스트"
        case .heading: "방향 확인기"
        case .battery: "배터리"
        case .radar: "거리 레이더"
        case .heartRate: "심박 중계"
        case .altitude: "높이 차이"
        }
    }

    var detail: String {
        switch self {
        case .impact: "팔을 힘껏 내질러 보세요"
        case .rotation: "손목 회전 각도 누적"
        case .vibration: "손목 떨림을 그래프로"
        case .board: "손가락과 크라운으로 그리기"
        case .flashlight: "워치로 아이폰 손전등 켜기"
        case .haptic: "워치로 아이폰 진동 울리기"
        case .buzz: "워치로 진동과 모스부호 보내기"
        case .mirror: "워치 그림을 크게 보고 저장"
        case .controller: "손목으로 아이폰 조종하기"
        case .ballGame: "손목을 기울여 공 굴리기"
        case .airPointer: "허공에 팔로 그림 그리기"
        case .duel: "누가 더 빨리 누를까"
        case .ping: "두 기기 사이의 응답 속도"
        case .heading: "두 기기가 향한 방향 비교"
        case .battery: "두 기기의 배터리 잔량"
        case .radar: "두 기기 사이 거리 재기"
        case .heartRate: "워치 심박을 아이폰에 실시간으로"
        case .altitude: "기압계로 두 기기 높이 비교"
        }
    }

    var systemImage: String {
        switch self {
        case .impact: "speedometer"
        case .rotation: "arrow.triangle.2.circlepath"
        case .vibration: "waveform.path.ecg"
        case .board: "square.grid.3x3.fill"
        case .flashlight: "flashlight.on.fill"
        case .haptic: "iphone.radiowaves.left.and.right"
        case .buzz: "applewatch.radiowaves.left.and.right"
        case .mirror: "rectangle.on.rectangle"
        case .controller: "gamecontroller.fill"
        case .ballGame: "soccerball"
        case .airPointer: "scribble.variable"
        case .duel: "bolt.fill"
        case .ping: "dot.radiowaves.left.and.right"
        case .heading: "location.north.line.fill"
        case .battery: "battery.75percent"
        case .radar: "scope"
        case .heartRate: "heart.fill"
        case .altitude: "mountain.2.fill"
        }
    }
}
