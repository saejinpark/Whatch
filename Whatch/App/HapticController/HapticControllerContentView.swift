//
//  hapticControllerContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/12/25.
//

import SwiftUI

struct HapticControllerContentView: View {
    @StateObject var manager = HapticManager.shared
    
    var body: some View {
        let status: HapticStatus = manager.isPlaying ? .playing : .stopped

        VStack {
            if manager.mode == .pressToVibrate {
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
                    .accessibilityLabel(manager.isPlaying ? "중지" : "시작")
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
                    .accessibilityLabel(manager.isPlaying ? "중지" : "시작")
                }
            }
        }
        
        Picker("모드", selection: $manager.mode) {
            Text("누르고").tag(HapticMode.pressToVibrate)
            Text("토글").tag(HapticMode.toggle)
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    HapticControllerContentView()
}
