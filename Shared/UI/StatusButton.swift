//
//  StatusButton.swift
//  Whatch
//

import SwiftUI

/// A large tappable `LockUp` that fills the available space.
struct StatusButton<Item: LockUpItem>: View {
    let item: Item
    var iconSize: CGFloat = 56
    var showsBackground = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CenteredContainer {
                LockUp(item: item, iconSize: iconSize)
            }
            .background {
                if showsBackground {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(item.tint.opacity(0.1))
                }
            }
        }
        .tint(item.tint)
    }
}

#Preview {
    StatusButton(item: FlashlightStatus.on) {}
}
