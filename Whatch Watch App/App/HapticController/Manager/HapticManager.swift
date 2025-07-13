//
//  HapticManager.swift
//  Whatch
//
//  Created by 박세진 on 7/12/25.
//

import Foundation

@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()

    @Published var isPlaying: Bool = false

    func handleTap() {
        PhoneSender.shared.sendHapticRequest(on: !isPlaying)
    }

    func updateState(_ isPlaying: Bool) {
        self.isPlaying = isPlaying
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ObjectWillChangePublisher().send()
        }
    }
}
