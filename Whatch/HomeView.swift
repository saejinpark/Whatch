//
//  HomeView.swift
//  Whatch
//

import SwiftUI

/// The dashboard: connection status, a live card per paired feature, and what the Watch can do alone.
/// Launch with `-openFeature <id>` to start on a feature.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var path: [Feature] = {
        let requested = UserDefaults.standard.string(forKey: "openFeature").flatMap(Feature.init(rawValue:))
        return requested.flatMap { $0.group == .paired ? [$0] : nil } ?? []
    }()

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    LinkBanner(status: model.link)
                        .padding(16)
                        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))

                    section(Feature.Group.paired.title) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Feature.Group.paired.features) { feature in
                                NavigationLink(value: feature) {
                                    FeatureCard(feature: feature, status: status(for: feature))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    section("Apple Watch에서 사용") {
                        VStack(spacing: 0) {
                            ForEach(Feature.Group.watchOnly.features) { feature in
                                WatchOnlyRow(feature: feature)
                                if feature != Feature.Group.watchOnly.features.last {
                                    Divider().padding(.leading, 62)
                                }
                            }
                        }
                        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Whatch")
            .navigationDestination(for: Feature.self) { feature in
                FeatureScreen(feature: feature)
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
            content()
        }
    }

    /// One live line for the feature's card.
    private func status(for feature: Feature) -> String {
        switch feature {
        case .ping:
            return model.link.isConnected ? "측정 준비됨" : "워치 대기 중"
        case .flashlight:
            return model.flashlight.isOn ? "켜짐" : "꺼짐"
        case .haptic:
            return model.haptic.isPlaying ? "진동 중" : "꺼짐"
        case .heading:
            return "워치가 향한 방향 보기"
        case .battery:
            return "\(model.battery.reading.percentText) · 워치 \(model.remoteBattery.percentText)"
        case .impact, .rotation, .vibration, .board:
            return feature.detail
        }
    }
}

private struct FeatureCard: View {
    let feature: Feature
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                FeatureIcon(feature: feature, size: 44)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 14)
            Text(feature.title)
                .font(.headline)
            Text(status)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct WatchOnlyRow: View {
    let feature: Feature

    var body: some View {
        HStack(spacing: 12) {
            FeatureIcon(feature: feature, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(feature.title)
                    .font(.body.weight(.medium))
                Text(feature.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "applewatch")
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

/// Wraps a feature's screen in its title and background.
private struct FeatureScreen: View {
    @Environment(AppModel.self) private var model
    let feature: Feature

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [feature.tint.opacity(0.18), Color(.systemGroupedBackground)],
                               startPoint: .top, endPoint: .center)
                    .ignoresSafeArea()
            )
            .navigationTitle(feature.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        switch feature {
        case .ping:
            VStack(spacing: 20) {
                PingScreen(monitor: model.ping)
                LinkAdvice(text: model.link.advice)
                Spacer(minLength: 0)
            }
        case .flashlight:
            FlashlightScreen()
        case .haptic:
            HapticScreen()
        case .heading:
            HeadingScreen(model: model)
        case .battery:
            VStack {
                Spacer()
                BatteryScreen(model: model)
                Spacer()
                Spacer()
            }
        case .impact, .rotation, .vibration, .board:
            ContentUnavailableView("Apple Watch 전용", systemImage: "applewatch",
                                   description: Text("이 기능은 워치의 Whatch 앱에서 사용할 수 있어요."))
        }
    }
}

#Preview {
    HomeView()
        .environment(AppModel())
}
