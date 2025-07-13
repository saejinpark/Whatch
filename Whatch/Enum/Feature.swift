//
//  Feature.swift
//  Whatch
//
//  Created by 박세진 on 7/8/25.
//
import SwiftUI

enum Feature: String, CaseIterable, Identifiable, CustomStringConvertible, DescriptiveItem {
    case pingTest
    case flashlight
    case hapticController
    case headingMonitor
    case batteryStatus

    var id: String { rawValue }

    var description: String {
        switch self {
        case .pingTest: return "핑 테스트"
        case .flashlight: return "라이트"
        case .hapticController: return "진동기"
        case .headingMonitor: return "방향 확인기"
        case .batteryStatus: return "배터리 확인"
        }
    }

    var detail: String {
        switch self {

        case .pingTest:
            return "워치와 아이폰이 잘 연결되는지 테스트해보세요."

        case .flashlight:
            return "워치로 아이폰의 손전등을 켜보세요"

        case .hapticController:
            return "아이폰의 진동을 워치에서 직접 제어해보세요."

        case .headingMonitor:
            return "워치가 향하고 있는 방향을 각도로 표시합니다."

        case .batteryStatus:
            return "아이폰의 배터리 잔량을 워치에서 확인해보세요."
        }
    }
    var systemImage: String {
        switch self {
        case .pingTest: return "dot.radiowaves.left.and.right"
        case .flashlight: return "flashlight.on.fill"
        case .hapticController: return "waveform.path"
        case .headingMonitor: return "location.north.line"
        case .batteryStatus: return "battery.100"
        }
    }

    var image: Image {
        Image(systemName: systemImage)
    }
}

