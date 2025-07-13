//
//  HapticControllerContentView.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/12/25.
//

import SwiftUI

struct HapticControllerContentView: View {
    @ObservedObject var manager = HapticManager.shared
    var body: some View {
        let status: HapticStatus = manager.isPlaying ? .playing : .stopped
        Button {
            manager.handleTap()
        } label: {
            CenteredContainer {
                LockUp(item: status)
                    .foregroundColor(status.color)
            }
            .accessibilityLabel(manager.isPlaying ? "끄기" : "켜기")
        }
        .tint(status.color)
    }
}

#Preview {
    HapticControllerContentView()
}
