//
//  FlashMode.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

enum FlashMode: String, CaseIterable, Identifiable {
    case pressToShine
    case toggle

    var id: String { rawValue }
}

