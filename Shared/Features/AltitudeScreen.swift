//
//  AltitudeScreen.swift
//  Whatch
//

import SwiftUI

/// How much higher one device is than the other, from their barometers.
struct AltitudeScreen: View {
    let model: AppModel

    /// Height difference that moves the icons to the ends of the picture.
    private static let fullScale = 1.0

    var body: some View {
        let meters = model.height.meters

        VStack(spacing: Layout.spacing) {
            GeometryReader { proxy in
                let travel = proxy.size.height / 2 - Layout.heroFont * 0.3
                let shift = CGFloat(max(min((meters ?? 0) / Self.fullScale, 1), -1)) * travel / 2

                ZStack {
                    Rectangle()
                        .fill(.secondary.opacity(0.35))
                        .frame(height: 1)
                    HStack {
                        deviceIcon(Device.symbol, name: Device.shortName)
                            .offset(y: shift)
                        Spacer()
                        deviceIcon(Device.counterpartSymbol, name: Device.counterpartShortName)
                            .offset(y: -shift)
                    }
                    .padding(.horizontal, Layout.spacing * 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeOut(duration: 0.4), value: shift)
            }
            #if !os(watchOS)
            .frame(height: 220)
            .card()
            #endif

            Text(meters.map(DistanceFormat.text(meters:)) ?? "--")
                .font(.system(size: Layout.heroFont * 0.7, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(caption(meters))
                .font(Layout.footnoteFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Button("영점 맞추기", systemImage: "arrow.down.to.line") {
                model.calibrateHeight()
            }
            .disabled(meters == nil)
            .tint(Feature.altitude.tint)
            #if !os(watchOS)
            .buttonStyle(.borderedProminent)
            #endif

            #if !os(watchOS)
            Text("두 기기를 나란히 두고 영점을 맞춘 뒤 한쪽을 들어 보세요. 기압계 특성상 10~20 cm 정도의 오차가 있어요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            #endif
        }
        .onAppear { model.setAltitudeVisible(true) }
        .onDisappear { model.setAltitudeVisible(false) }
    }

    private func deviceIcon(_ symbol: String, name: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: Layout.heroFont * 0.45))
                .foregroundStyle(Feature.altitude.tint)
            Text(name)
                .font(Layout.footnoteFont)
                .foregroundStyle(.secondary)
        }
    }

    private func caption(_ meters: Double?) -> String {
        switch model.altimeter.status {
        case .unavailable: return "이 기기에는 기압계가 없어요"
        case .denied: return "설정에서 동작 및 피트니스 권한을 허용해 주세요"
        case .idle, .running: break
        }
        guard let meters else {
            return model.link.advice ?? "\(Device.counterpartShortName)의 기압을 기다리는 중"
        }
        if abs(meters) < 0.05 { return "거의 같은 높이예요" }
        return "\(Device.counterpartSubject) 더 \(meters > 0 ? "높아요" : "낮아요")"
    }
}

#Preview {
    AltitudeScreen(model: AppModel())
        .padding()
}
