//
//  HapticControllerContentView.swift
//  Whatch
//

import SwiftUI

struct HapticControllerContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var haptic = model.haptic

        VStack {
            StatusButton(item: HapticStatus(isPlaying: haptic.isPlaying), iconSize: 112, showsBackground: true) {
                haptic.tapped()
            }
            .pressEvents(onPress: haptic.pressBegan, onRelease: haptic.pressEnded)
            .accessibilityLabel(haptic.isPlaying ? "중지" : "시작")

            ActivationModePicker(selection: $haptic.mode)
        }
        .padding()
    }
}

#Preview {
    HapticControllerContentView()
        .environment(AppModel())
}
