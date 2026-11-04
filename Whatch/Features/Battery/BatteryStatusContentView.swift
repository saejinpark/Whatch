//
//  BatteryStatusContentView.swift
//  Whatch
//

import SwiftUI

struct BatteryStatusContentView: View {
    let monitor: BatteryMonitor

    var body: some View {
        VStack {
            LockUp(item: BatteryStatus.phone(level: monitor.localLevel), iconSize: 112)
                .frame(maxHeight: .infinity)
            Divider()
            LockUp(item: BatteryStatus.watch(level: monitor.remoteLevel), iconSize: 112)
                .frame(maxHeight: .infinity)
        }
        .font(.title3)
        .padding()
    }
}

#Preview {
    BatteryStatusContentView(monitor: BatteryMonitor())
}
