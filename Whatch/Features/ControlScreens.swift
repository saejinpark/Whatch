//
//  ControlScreens.swift
//  Whatch
//

import SwiftUI

/// The torch: a big button, plus how it behaves and how bright it is.
struct FlashlightScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var flashlight = model.flashlight
        let tint = Feature.flashlight.tint

        VStack(spacing: 20) {
            Spacer(minLength: 0)

            PowerButton(isOn: flashlight.isOn,
                        systemImage: flashlight.isOn ? "flashlight.on.fill" : "flashlight.off.fill",
                        tint: tint) {
                flashlight.tapped()
            }
            .pressEvents(onPress: flashlight.pressBegan, onRelease: flashlight.pressEnded)
            .frame(maxWidth: 230)
            .accessibilityLabel(flashlight.isOn ? "손전등 끄기" : "손전등 켜기")

            Text(flashlight.isOn ? "켜짐" : "꺼짐")
                .font(.title2.weight(.semibold))
                .foregroundStyle(flashlight.isOn ? tint : .secondary)

            Spacer(minLength: 0)

            SettingsCard {
                ActivationModePicker(selection: $flashlight.mode)
                LevelSlider(title: "밝기", value: $flashlight.brightness, range: TorchLevel.minimumBrightness...1,
                            minimumImage: "sun.min", maximumImage: "sun.max.fill", tint: tint)
            }

            WatchRemoteNote(link: model.link)
        }
    }
}

/// The vibration motor: a big button, plus how it behaves and how strong it is.
struct HapticScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var haptic = model.haptic
        let tint = Feature.haptic.tint

        VStack(spacing: 20) {
            Spacer(minLength: 0)

            PowerButton(isOn: haptic.isPlaying,
                        systemImage: haptic.isPlaying ? "iphone.radiowaves.left.and.right" : "iphone",
                        tint: tint) {
                haptic.tapped()
            }
            .pressEvents(onPress: haptic.pressBegan, onRelease: haptic.pressEnded)
            .frame(maxWidth: 230)
            .accessibilityLabel(haptic.isPlaying ? "진동 멈추기" : "진동 시작")

            Text(haptic.isPlaying ? "진동 중" : "꺼짐")
                .font(.title2.weight(.semibold))
                .foregroundStyle(haptic.isPlaying ? tint : .secondary)

            Spacer(minLength: 0)

            SettingsCard {
                ActivationModePicker(selection: $haptic.mode)
                LevelSlider(title: "세기", value: $haptic.intensity, range: 0.2...1,
                            minimumImage: "speaker.wave.1", maximumImage: "speaker.wave.3.fill", tint: tint)
            }

            WatchRemoteNote(link: model.link)
        }
    }
}

// MARK: - Pieces

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 16) {
            content
        }
        .padding(16)
        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
    }
}

private struct ActivationModePicker: View {
    @Binding var selection: ActivationMode

    var body: some View {
        Picker("동작 방식", selection: $selection) {
            ForEach(ActivationMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct LevelSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let minimumImage: String
    let maximumImage: String
    let tint: Color

    var body: some View {
        Slider(value: $value, in: range) {
            Text(title)
        } minimumValueLabel: {
            Image(systemName: minimumImage).foregroundStyle(.secondary)
        } maximumValueLabel: {
            Image(systemName: maximumImage).foregroundStyle(.secondary)
        }
        .tint(tint)
    }
}

/// Tells the user whether the Watch can drive this control right now.
private struct WatchRemoteNote: View {
    let link: LinkStatus

    var body: some View {
        Label(link.isConnected ? "워치에서도 켜고 끌 수 있어요" : (link.advice ?? link.title),
              systemImage: link.isConnected ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

extension View {
    /// Reports when a finger goes down on and lifts off the view, without blocking taps.
    /// `onPress` may fire repeatedly while the finger moves, so callers should be idempotent.
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

#Preview("Flashlight") {
    FlashlightScreen()
        .padding()
        .environment(AppModel())
}

#Preview("Haptic") {
    HapticScreen()
        .padding()
        .environment(AppModel())
}
