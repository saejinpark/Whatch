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
/// For the torch, the Digital Crown sets the brightness.
struct RemoteControlScreen: View {
    @Environment(AppModel.self) private var model
    let control: RemoteControl

    /// Brightness as set on the crown, `0.1...1`.
    @State private var crown = 1.0
    @State private var lastCrownTurn = Date.distantPast

    private var isOn: Bool {
        switch control {
        case .flashlight: model.isRemoteFlashlightOn
        case .haptic: model.isRemoteHapticOn
        }
    }

    private var hasBrightness: Bool {
        control == .flashlight
    }

    var body: some View {
        VStack(spacing: Layout.spacing) {
            PowerButton(isOn: isOn, systemImage: control.systemImage(isOn: isOn), tint: control.feature.tint) {
                switch control {
                case .flashlight: model.setRemoteFlashlight(!isOn)
                case .haptic: model.setRemoteHaptic(!isOn)
                }
            }
            .padding(5)
            .overlay {
                if hasBrightness {
                    // The brightness as an arc around the button.
                    Circle()
                        .trim(from: 0, to: crown)
                        .stroke(control.feature.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .aspectRatio(1, contentMode: .fit)
                        .animation(.easeOut(duration: 0.15), value: crown)
                }
            }
            .padding(.horizontal, 10)
            .accessibilityLabel(isOn ? "끄기" : "켜기")

            if let hint = model.remoteControlHint {
                LinkAdvice(text: hint)
            } else {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(isOn ? control.feature.tint : .secondary)
            }
        }
        .animation(.default, value: model.remoteControlHint)
        .focusable(hasBrightness)
        .digitalCrownRotation($crown, from: TorchLevel.minimumBrightness, through: 1, by: 0.05,
                              sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crown) { _, value in
            // Ignore the change made below when the iPhone reports its own brightness.
            guard hasBrightness, abs(value - model.remoteFlashlightBrightness) > 0.001 else { return }
            lastCrownTurn = Date()
            model.setRemoteFlashlightBrightness(value)
        }
        .onChange(of: model.remoteFlashlightBrightness, initial: true) { _, value in
            // Follow the iPhone, but not while the crown is being turned: its reports lag behind.
            if Date().timeIntervalSince(lastCrownTurn) > 1 {
                crown = value
            }
        }
    }

    private var statusText: String {
        guard hasBrightness else { return control.statusText(isOn: isOn) }
        return "\(isOn ? "켜짐" : "꺼짐") · 밝기 \(Int((crown * 100).rounded()))%"
    }
}

#Preview {
    RemoteControlScreen(control: .flashlight)
        .environment(AppModel())
}
