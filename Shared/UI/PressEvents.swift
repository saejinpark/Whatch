//
//  PressEvents.swift
//  Whatch
//

import SwiftUI

extension View {
    /// Reports when a finger goes down on and lifts off the view, without blocking taps.
    /// `onPress` may fire repeatedly while the finger moves, so callers should be idempotent.
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
