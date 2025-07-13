//
//  Feature.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/7/25.
//

enum Feature: String, CaseIterable, Identifiable, CustomStringConvertible {
    case accelerometer
    case rollTrackerX
    case rollTrackerY
    case vibrationDetector
    case watchBoard
    case pingTest
    case flashlight
    case hapticController
    case headingMonitor
    case batteryStatus

    var id: String { rawValue }

    var description: String {
        switch self {
        case .accelerometer: return "워치 가속도계"
        case .rollTrackerX: return "회전측정기 (가로)"
        case .rollTrackerY: return "회전측정기 (세로)"
        case .vibrationDetector: return "떨림 감지기"
        case .watchBoard: return "와치보드"
        case .pingTest: return "핑 테스트"
        case .flashlight: return "라이트"
        case .hapticController: return "진동기"
        case .headingMonitor: return "방향 확인기"
        case .batteryStatus: return "배터리 확인"
        }
    }

    var detail: String {
        switch self {
        case .accelerometer:
            return "팔을 힘껏 내질러 보세요"

        case .rollTrackerX:
            return "가로 방향으로 회전시켜 보세요."

        case .rollTrackerY:
            return "세로 방향으로 회전해보세요."

        case .vibrationDetector:
            return "흔들어보세요."

        case .watchBoard:
            return "그림을 그려보세요"

        case .pingTest:
            return "워치와 아이폰이 잘 연결되는지 테스트해보세요."

        case .flashlight:
            return "워치로 아이폰의 손전등을 켜보세요"

        case .hapticController:
            return "아이폰의 진동을 워치에서 직접 제어해보세요."

        case .headingMonitor:
            return "아이폰이 향하고 있는 방향을 각도로 표시합니다."

        case .batteryStatus:
            return "아이폰의 배터리 잔량을 워치에서 확인해보세요."
        }
    }
}
