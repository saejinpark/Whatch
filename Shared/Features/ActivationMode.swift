//
//  ActivationMode.swift
//  Whatch
//

import Foundation

/// How a press-style control behaves: active only while held, or flipped on each tap.
enum ActivationMode: String, CaseIterable, Identifiable {
    case hold
    case toggle

    var id: Self { self }

    var title: String {
        switch self {
        case .hold: "누르고"
        case .toggle: "토글"
        }
    }
}
