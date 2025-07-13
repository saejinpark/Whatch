//
//  FlashLightManager.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/11/25.
//

import Foundation

@MainActor
class FlashLightManager: ObservableObject {
    static let shared = FlashLightManager()
    
    @Published var isOn: Bool = false
    
    func handleTap() {
        PhoneSender.shared.sendFlashLightRequest(on: !isOn)
    }
    
    func updateState(_ isOn: Bool) {
        self.isOn = isOn
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ObjectWillChangePublisher().send()
        }
    }

}
