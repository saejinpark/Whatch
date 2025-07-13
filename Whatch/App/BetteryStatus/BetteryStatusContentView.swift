//
//  BetteryStatusContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/13/25.
//

import SwiftUI

@MainActor
struct BatteryStatusContentView: View {
    @StateObject var manager = BatteryStatusManager.shared

    var body: some View {
        VStack {
            LockUp(item: BatteryStatus.phone(level: manager.batteryLevel))
                .scaleEffect(2)
                .frame(width: 300, height: 300)
            Divider()
            LockUp(item: BatteryStatus.watch(level: manager.anotherBatteryLevel))
                .scaleEffect(2)
                .frame(width: 300, height: 300)
            
        }
    }
}

#Preview {
    BatteryStatusContentView()
}
