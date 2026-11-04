//
//  LockUp.swift
//  Whatch
//

import SwiftUI

/// Icon stacked over a caption, in the item's tint.
struct LockUp<Item: LockUpItem>: View {
    let item: Item
    var iconSize: CGFloat = 56

    var body: some View {
        VStack {
            Image(systemName: item.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
            Text(item.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(item.tint)
    }
}

#Preview {
    LockUp(item: PingStatus.good)
}
