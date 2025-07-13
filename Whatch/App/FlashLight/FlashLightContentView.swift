//
//  FlashLightContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

struct FlashLightContentView: View {
    @StateObject var manager = FlashLightManager.shared

    var body: some View {
        let status: FlashLightStatus = manager.isOn ? .on : .off
        VStack {
            if manager.mode == .pressToShine {
                Button {
                    manager.handleTap()
                } label: {
                    CenteredContainer {
                        LockUp(item: status)
                            .foregroundColor(status.color)
                            .scaleEffect(2)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(status.color.opacity(0.1))
                    )
                    .accessibilityLabel(manager.isOn ? "끄기" : "켜기")
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in manager.handlePressBegan() }
                        .onEnded { _ in manager.handlePressEnded() }
                )
            } else {
                Button {
                    manager.handleTap()
                } label: {
                    CenteredContainer {
                        LockUp(item: status)
                            .foregroundColor(status.color)
                            .scaleEffect(2)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(status.color.opacity(0.1))
                    )
                    .accessibilityLabel(manager.isOn ? "끄기" : "켜기")
                }
            }
            Picker("모드", selection: $manager.mode) {
                Text("누르고").tag(FlashMode.pressToShine)
                Text("토글").tag(FlashMode.toggle)
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    FlashLightContentView()
}
