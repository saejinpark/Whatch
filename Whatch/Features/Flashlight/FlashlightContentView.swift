//
//  FlashlightContentView.swift
//  Whatch
//

import SwiftUI

struct FlashlightContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var flashlight = model.flashlight

        VStack {
            StatusButton(item: FlashlightStatus(isOn: flashlight.isOn), iconSize: 112, showsBackground: true) {
                flashlight.tapped()
            }
            .pressEvents(onPress: flashlight.pressBegan, onRelease: flashlight.pressEnded)
            .accessibilityLabel(flashlight.isOn ? "끄기" : "켜기")

            ActivationModePicker(selection: $flashlight.mode)
        }
        .padding()
    }
}

#Preview {
    FlashlightContentView()
        .environment(AppModel())
}
