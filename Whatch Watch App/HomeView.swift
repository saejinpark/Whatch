//
//  HomeView.swift
//  Whatch Watch App
//

import SwiftUI

/// The feature list. Launch with `-openFeature <id>` to start on a feature.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var path: [Feature] = {
        let requested = UserDefaults.standard.string(forKey: "openFeature").flatMap(Feature.init(rawValue:))
        return requested.flatMap { $0.isAvailable(on: .watch) ? [$0] : nil } ?? []
    }()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(Feature.Group.allCases) { group in
                    if group == .remote {
                        // Everything from here on needs the iPhone.
                        Section {
                            LinkBanner(status: model.link)
                        }
                    }
                    Section(group.title) {
                        ForEach(group.features(on: .watch)) { feature in
                            NavigationLink(value: feature) {
                                FeatureRow(feature: feature)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Whatch")
            .navigationDestination(for: Feature.self) { feature in
                FeatureScreen(feature: feature)
            }
        }
        .overlay(alignment: .top) {
            BuzzBanner(player: model.buzzPlayer)
        }
        .onChange(of: model.pendingOpen, initial: true) { _, feature in
            open(feature)
        }
    }

    /// Shows a screen the iPhone asked for.
    private func open(_ feature: Feature?) {
        guard let feature else { return }
        model.pendingOpen = nil
        guard feature.isAvailable(on: .watch), path.last != feature else { return }
        path = [feature]
    }
}

private struct FeatureRow: View {
    let feature: Feature

    var body: some View {
        HStack(spacing: 9) {
            FeatureIcon(feature: feature, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(.vertical, 1)
    }
}

/// Shows the taps arriving from the iPhone, with the one playing now lit up.
private struct BuzzBanner: View {
    let player: BuzzPlayer

    var body: some View {
        if let position = player.position {
            let symbols = Array(player.pattern)
            let window = max(position - 5, 0)...min(position + 5, symbols.count - 1)
            HStack(spacing: 3) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.caption2)
                ForEach(Array(window), id: \.self) { index in
                    Text(MorseCode.display(String(symbols[index])))
                        .font(.system(.headline, design: .monospaced))
                        .opacity(index == position ? 1 : 0.35)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Feature.buzz.tint.gradient, in: Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityLabel("아이폰에서 보낸 진동")
        }
    }
}

/// Wraps a feature's screen in its title and tinted background.
private struct FeatureScreen: View {
    @Environment(AppModel.self) private var model
    let feature: Feature

    var body: some View {
        content
            .padding(.horizontal, feature == .board ? 0 : 6)
            .navigationTitle(feature.title)
            .containerBackground(feature.tint.gradient.opacity(0.3), for: .navigation)
    }

    @ViewBuilder
    private var content: some View {
        switch feature {
        case .impact: ImpactScreen()
        case .rotation: RotationScreen()
        case .vibration: VibrationScreen()
        case .board: BoardScreen()
        case .flashlight: RemoteControlScreen(control: .flashlight)
        case .haptic: RemoteControlScreen(control: .haptic)
        case .controller: ControllerScreen()
        case .duel: DuelScreen(model: model)
        case .ping: PingScreen(monitor: model.ping)
        case .heading: HeadingScreen(model: model)
        case .battery: BatteryScreen(model: model)
        case .radar: RadarScreen(model: model)
        case .heartRate: HeartBroadcastScreen()
        case .altitude: AltitudeScreen(model: model)
        case .buzz, .mirror, .ballGame, .airPointer:
            // These live on the iPhone; the Watch takes part through other screens.
            ContentUnavailableView("아이폰에서 열어 주세요", systemImage: "iphone")
        }
    }
}

#Preview {
    HomeView()
        .environment(AppModel())
}
