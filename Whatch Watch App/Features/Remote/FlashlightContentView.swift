//
//  FlashlightContentView.swift
//  Whatch Watch App
//

import SwiftUI

struct FlashlightContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let flashlight = model.flashlight
        StatusButton(item: FlashlightStatus(isOn: flashlight.isOn)) {
            flashlight.toggle()
        }
        .accessibilityLabel(flashlight.isOn ? "끄기" : "켜기")
    }
}

#Preview {
    FlashlightContentView()
        .environment(AppModel())
}
