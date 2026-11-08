//
//  TorchLevel.swift
//  Whatch
//

import Foundation

/// What to ask the torch for, given a brightness setting.
///
/// AVFoundation accepts a level in `0 < level <= 1`, or a special "as bright as currently
/// possible" value. Anything else raises an exception that takes the app down, so the
/// mapping lives here where it can be tested.
enum TorchLevel: Equatable, Sendable {
    /// As bright as the hardware currently allows.
    case maximum
    /// A fraction of full brightness, always within `0 < value <= 1`.
    case fraction(Float)

    static let minimumBrightness = 0.1

    init(brightness: Double) {
        guard brightness.isFinite else {
            self = .maximum
            return
        }
        if brightness >= 0.995 {
            self = .maximum
        } else {
            self = .fraction(Float(min(max(brightness, Self.minimumBrightness), 1)))
        }
    }
}
