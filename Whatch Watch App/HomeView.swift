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
        return requested.map { [$0] } ?? []
    }()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(Feature.Group.allCases) { group in
                    Section {
                        ForEach(group.features) { feature in
                            NavigationLink(value: feature) {
                                FeatureRow(feature: feature)
                            }
                        }
                    } header: {
                        Text(group.title)
                    } footer: {
                        if group == .paired {
                            LinkBanner(status: model.link)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .navigationTitle("Whatch")
            .navigationDestination(for: Feature.self) { feature in
                FeatureScreen(feature: feature)
            }
        }
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
        case .ping: PingScreen(monitor: model.ping)
        case .flashlight: RemoteControlScreen(control: .flashlight)
        case .haptic: RemoteControlScreen(control: .haptic)
        case .heading: HeadingScreen(model: model)
        case .battery: BatteryScreen(model: model)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppModel())
}
