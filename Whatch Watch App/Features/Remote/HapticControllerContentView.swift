//
//  HapticControllerContentView.swift
//  Whatch Watch App
//

import SwiftUI

struct HapticControllerContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let haptic = model.haptic
        StatusButton(item: HapticStatus(isPlaying: haptic.isOn)) {
            haptic.toggle()
        }
        .accessibilityLabel(haptic.isOn ? "끄기" : "켜기")
    }
}

#Preview {
    HapticControllerContentView()
        .environment(AppModel())
}
