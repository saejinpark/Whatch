//
//  BatteryScreen.swift
//  Whatch
//

import SwiftUI

/// Battery level of both devices side by side.
struct BatteryScreen: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: Layout.spacing) {
            HStack(spacing: Layout.spacing * 2) {
                BatteryGauge(name: Device.shortName, symbol: Device.symbol, reading: model.battery.reading)
                BatteryGauge(name: Device.counterpartShortName, symbol: Device.counterpartSymbol, reading: model.remoteBattery)
            }
            if model.remoteBattery.level == nil {
                LinkAdvice(text: model.link.advice ?? "\(Device.counterpartName) 배터리를 기다리는 중")
            }
        }
    }
}

/// One device's battery as a ring.
struct BatteryGauge: View {
    let name: String
    let symbol: String
    let reading: BatteryReading

    var body: some View {
        VStack(spacing: Layout.spacing) {
            RingGauge(value: reading.level ?? 0, tint: reading.band.tint) {
                VStack(spacing: 0) {
                    Image(systemName: reading.isCharging ? "bolt.fill" : symbol)
                        .font(.system(size: Layout.heroFont * 0.3))
                        .foregroundStyle(reading.isCharging ? Color.green : Color.secondary)
                    Text(reading.percentText)
                        .font(.system(size: Layout.heroFont * 0.38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(Layout.ringWidth)
            }
            VStack(spacing: 0) {
                Text(name)
                    .font(Layout.footnoteFont)
                    .lineLimit(1)
                // Reserve the line so both gauges stay aligned.
                Text(reading.ageText() ?? " ")
                    .font(Layout.footnoteFont)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) 배터리 \(reading.percentText)\(reading.isCharging ? ", 충전 중" : "")")
    }
}

#Preview {
    BatteryScreen(model: AppModel())
        .padding()
}
