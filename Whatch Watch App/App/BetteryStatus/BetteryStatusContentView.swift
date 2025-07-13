//
//  BetteryStatusContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/13/25.
//

import SwiftUI

struct BatteryStatusContentView: View {
    @StateObject var manager = BatteryStatusManager.shared

    var body: some View {
        VStack {
            GeometryReader { geometry in
                TabView {
                    LockUp(item: BatteryStatus.watch(level: manager.batteryLevel))
                    
                    LockUp(item: BatteryStatus.phone(level: manager.anotherBatteryLevel))
                    
                
                }.tabViewStyle(.page)
            
            }
        }
    }
}

#Preview {
    BatteryStatusContentView()
}
