//
//  PingScreen.swift
//  Whatch
//

import SwiftUI

/// Live round-trip time to the counterpart app.
struct PingScreen: View {
    let monitor: PingMonitor

    var body: some View {
        let tracker = monitor.tracker

        VStack(spacing: Layout.spacing) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(tracker.latency.map(Self.milliseconds) ?? "--")
                        .font(.system(size: Layout.heroFont, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.default, value: tracker.latency)
                    Text("ms")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Label(tracker.status.title, systemImage: tracker.status.systemImage)
                    .font(Layout.labelFont)
                    .foregroundStyle(tracker.status.tint)
            }
            .accessibilityElement(children: .combine)

            Sparkline(values: tracker.samples.map { $0 * 1000 }, tint: Feature.ping.tint)
                .frame(minHeight: 24, maxHeight: Layout.chartHeight)

            HStack(spacing: Layout.spacing) {
                StatTile(title: "평균", value: tracker.average.map(Self.milliseconds) ?? "--")
                #if !os(watchOS)
                StatTile(title: "최소", value: tracker.minimum.map(Self.milliseconds) ?? "--")
                StatTile(title: "최대", value: tracker.maximum.map(Self.milliseconds) ?? "--")
                #endif
                StatTile(title: "손실", value: "\(tracker.lostCount)",
                         tint: tracker.lostCount > 0 ? .red : .primary)
            }
        }
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }

    private static func milliseconds(_ seconds: TimeInterval) -> String {
        "\(Int((seconds * 1000).rounded()))"
    }
}

#Preview {
    PingScreen(monitor: PingMonitor(session: ConnectivitySession()))
        .padding()
}
