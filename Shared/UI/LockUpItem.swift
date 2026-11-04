//
//  LockUpItem.swift
//  Whatch
//

import SwiftUI

/// Something that can be shown as an icon over a short caption, tinted by state.
protocol LockUpItem {
    var title: String { get }
    var systemImage: String { get }
    var tint: Color { get }
}
