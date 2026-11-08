//
//  HomeView.swift
//  Whatch
//

import SwiftUI

/// The dashboard: both devices and the link between them, a live card per paired feature,
/// and what the Watch can do on its own. Launch with `-openFeature <id>` to start on a feature.
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
                VStack(alignment: .leading, spacing: 28) {
                    DevicesCard(model: model)

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

                    section("Apple Watch에서") {
                        VStack(spacing: 0) {
                            ForEach(Feature.Group.watchOnly.features) { feature in
                                WatchOnlyRow(feature: feature)
                                if feature != Feature.Group.watchOnly.features.last {
                                    Divider().padding(.leading, 64)
                                }
                            }
                        }
                        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Whatch")
            .navigationDestination(for: Feature.self) { feature in
                FeatureScreen(feature: feature)
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.leading, 4)
            content()
        }
    }

    /// One live line for the feature's card.
    private func status(for feature: Feature) -> (text: String, isActive: Bool) {
        switch feature {
        case .ping:
            return model.link.isConnected ? ("측정 가능", true) : ("워치 대기 중", false)
        case .flashlight:
            return model.flashlight.isOn ? ("켜짐", true) : ("꺼짐", false)
        case .haptic:
            return model.haptic.isPlaying ? ("진동 중", true) : ("꺼짐", false)
        case .heading:
            return ("워치가 향한 방향", model.link.isConnected)
        case .battery:
            return ("워치 \(model.remoteBattery.percentText)", model.remoteBattery.level != nil)
        case .impact, .rotation, .vibration, .board:
            return (feature.detail, false)
        }
    }
}

// MARK: - Devices card

/// This phone, the Watch, and the state of the link between them.
private struct DevicesCard: View {
    let model: AppModel

    var body: some View {
        let status = model.link

        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 0) {
                DeviceColumn(symbol: "iphone", name: "iPhone", reading: model.battery.reading)
                LinkIndicator(status: status)
                    .padding(.top, 22)
                DeviceColumn(symbol: "applewatch", name: "Apple Watch", reading: model.remoteBattery)
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: status.systemImage)
                    .foregroundStyle(status.tint)
                    .symbolEffect(.pulse, isActive: status == .connecting)
                Text(status.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let advice = status.advice {
                    Text(advice)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(16)
        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .animation(.default, value: status)
        .accessibilityElement(children: .combine)
    }
}

private struct DeviceColumn: View {
    let symbol: String
    let name: String
    let reading: BatteryReading

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 30))
                .foregroundStyle(.primary)
                .frame(height: 36)
            Text(name)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 3) {
                if reading.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                }
                Text(reading.percentText)
                    .monospacedDigit()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(reading.band.tint)
            if let age = reading.ageText() {
                Text(age)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// A dotted line between the two devices, in the colour of the connection.
private struct LinkIndicator: View {
    let status: LinkStatus

    var body: some View {
        ZStack {
            Line()
                .stroke(status.tint.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 6]))
                .frame(height: 2)
            Image(systemName: status.isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(status.tint)
                .padding(6)
                .background(Color.card, in: Circle())
                .overlay(Circle().strokeBorder(status.tint.opacity(0.5), lineWidth: 1))
        }
        .frame(width: 72)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

// MARK: - Feature cards

private struct FeatureCard: View {
    let feature: Feature
    let status: (text: String, isActive: Bool)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FeatureIcon(feature: feature, size: 42)
            Spacer(minLength: 16)
            Text(feature.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Pill(text: status.text, tint: status.isActive ? feature.tint : .secondary)
                .padding(.top, 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
            shape.fill(Color.card)
                .overlay(
                    LinearGradient(colors: [feature.tint.opacity(0.22), feature.tint.opacity(0.06)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(shape)
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("열기")
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
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Feature screens

/// Wraps a feature's screen in its title and a tinted background.
private struct FeatureScreen: View {
    @Environment(AppModel.self) private var model
    let feature: Feature

    var body: some View {
        ScrollView {
            content
                .padding(16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(
            LinearGradient(colors: [feature.tint.opacity(0.28), Color(.systemGroupedBackground)],
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
            PingScreen(monitor: model.ping)
            LinkAdvice(text: model.link.advice)
                .padding(.top, 12)
        case .flashlight:
            FlashlightScreen()
        case .haptic:
            HapticScreen()
        case .heading:
            HeadingScreen(model: model)
        case .battery:
            BatteryScreen(model: model)
                .padding(.top, 24)
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
