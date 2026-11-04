//
//  BatteryStatusContentView.swift
//  Whatch Watch App
//

import SwiftUI

struct BatteryStatusContentView: View {
    let monitor: BatteryMonitor

    var body: some View {
        TabView {
            LockUp(item: BatteryStatus.watch(level: monitor.localLevel))
            LockUp(item: BatteryStatus.phone(level: monitor.remoteLevel))
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    BatteryStatusContentView(monitor: BatteryMonitor())
}
