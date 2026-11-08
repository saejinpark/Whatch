//
//  RemoteControlScreen.swift
//  Whatch Watch App
//

import SwiftUI

/// Something on the iPhone that the Watch can switch on and off.
enum RemoteControl {
    case flashlight
    case haptic

    var feature: Feature {
        switch self {
        case .flashlight: .flashlight
        case .haptic: .haptic
        }
    }

    func systemImage(isOn: Bool) -> String {
        switch self {
        case .flashlight: isOn ? "flashlight.on.fill" : "flashlight.off.fill"
        case .haptic: isOn ? "iphone.radiowaves.left.and.right" : "iphone"
        }
    }

    func statusText(isOn: Bool) -> String {
        switch self {
        case .flashlight: isOn ? "아이폰 손전등 켜짐" : "아이폰 손전등 꺼짐"
        case .haptic: isOn ? "아이폰 진동 중" : "아이폰 진동 꺼짐"
        }
    }
}

/// A big button that switches the iPhone torch or vibration. It only shows "on" once the iPhone confirms.
struct RemoteControlScreen: View {
    @Environment(AppModel.self) private var model
    let control: RemoteControl

    private var isOn: Bool {
        switch control {
        case .flashlight: model.isRemoteFlashlightOn
        case .haptic: model.isRemoteHapticOn
        }
    }

    var body: some View {
        VStack(spacing: Layout.spacing) {
            PowerButton(isOn: isOn, systemImage: control.systemImage(isOn: isOn), tint: control.feature.tint) {
                switch control {
                case .flashlight: model.setRemoteFlashlight(!isOn)
                case .haptic: model.setRemoteHaptic(!isOn)
                }
            }
            .padding(.horizontal, 12)
            .accessibilityLabel(isOn ? "끄기" : "켜기")

            if let hint = model.remoteControlHint {
                LinkAdvice(text: hint)
            } else {
                Text(control.statusText(isOn: isOn))
                    .font(.caption)
                    .foregroundStyle(isOn ? control.feature.tint : .secondary)
            }
        }
        .animation(.default, value: model.remoteControlHint)
    }
}

#Preview {
    RemoteControlScreen(control: .flashlight)
        .environment(AppModel())
}
