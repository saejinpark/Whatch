//
//  FlashLightContentView.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

struct FlashLightContentView: View {
    @ObservedObject var manager = FlashLightManager.shared
    
    var body: some View {
        let status: FlashLightStatus = manager.isOn ? .on : .off
        Button {
            manager.handleTap()
        } label: {
            CenteredContainer {
                LockUp(item: status)
                    .foregroundColor(status.color)
            }
            .accessibilityLabel(manager.isOn ? "끄기" : "켜기")
        }
        .tint(status.color)
    }
}

#Preview {
    FlashLightContentView()
}
