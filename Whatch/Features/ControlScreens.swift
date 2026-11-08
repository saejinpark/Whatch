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

        VStack(spacing: 24) {
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
                .padding(.bottom, 8)

            SettingsCard {
                SettingRow(title: "동작 방식") {
                    ActivationModePicker(selection: $flashlight.mode)
                }
                SettingRow(title: "밝기") {
                    LevelSlider(value: $flashlight.brightness, range: TorchLevel.minimumBrightness...1,
                                minimumImage: "sun.min", maximumImage: "sun.max.fill", tint: tint)
                }
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

        VStack(spacing: 24) {
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
                .padding(.bottom, 8)

            SettingsCard {
                SettingRow(title: "동작 방식") {
                    ActivationModePicker(selection: $haptic.mode)
                }
                SettingRow(title: "세기") {
                    LevelSlider(value: $haptic.intensity, range: 0.2...1,
                                minimumImage: "speaker.wave.1", maximumImage: "speaker.wave.3.fill", tint: tint)
                }
            }

            WatchRemoteNote(link: model.link)
        }
    }
}

// MARK: - Pieces

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
    }
}

private struct SettingRow<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            content
        }
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
    @Binding var value: Double
    let range: ClosedRange<Double>
    let minimumImage: String
    let maximumImage: String
    let tint: Color

    var body: some View {
        Slider(value: $value, in: range) {
            EmptyView()
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
