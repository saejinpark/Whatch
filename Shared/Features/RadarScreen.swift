//
//  RadarScreen.swift
//  Whatch
//

import SwiftUI

/// Distance to the other device, measured with ultra-wideband.
struct RadarScreen: View {
    let model: AppModel

    var body: some View {
        let ranging = model.ranging

        VStack(spacing: Layout.spacing) {
            RadarDial(distance: ranging.distance, bearing: ranging.bearing, tint: Feature.radar.tint)
                .frame(maxHeight: .infinity)

            Text(ranging.distance.map(DistanceFormat.text(meters:)) ?? "--")
                .font(.system(size: Layout.heroFont * 0.7, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: ranging.distance.map { Int($0 * 20) })

            Text(caption(ranging))
                .font(Layout.footnoteFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .onAppear { ranging.start() }
        .onDisappear { ranging.stop() }
    }

    private func caption(_ ranging: RangingService) -> String {
        switch ranging.status {
        case .idle, .searching:
            return model.link.advice ?? "\(Device.counterpartShortName)에서도 레이더가 열리길 기다리는 중"
        case .unsupported:
            return "이 기기는 초광대역 거리 측정을 지원하지 않아요"
        case .denied:
            return "설정에서 근처 기기 찾기 권한을 허용해 주세요"
        case .failed:
            return "거리 측정을 시작하지 못했어요"
        case .ranging:
            guard let bearing = ranging.bearing else { return "\(Device.counterpartShortName)까지의 거리" }
            let degrees = Int(abs(bearing).rounded())
            return degrees < 8 ? "정면에 있어요" : "\(bearing > 0 ? "오른쪽" : "왼쪽") \(degrees)°"
        }
    }
}

/// Range rings around this device, with the other device as a blip.
private struct RadarDial: View {
    let distance: Double?
    let bearing: Double?
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2 - 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            // Three rings a metre apart up close, switching to wider rings when the blip would leave them.
            let fullScale = (distance ?? 0) > 3 ? 12.0 : 3.0

            for ring in 1...3 {
                let r = radius * CGFloat(ring) / 3
                context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                               with: .color(tint.opacity(ring == 3 ? 0.6 : 0.3)), lineWidth: 1)
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)),
                         with: .color(.primary))

            if let distance {
                let r = radius * CGFloat(min(distance / fullScale, 1))
                // Without a bearing the blip sits straight ahead.
                let angle = (bearing ?? 0) * .pi / 180
                let blip = CGPoint(x: center.x + r * CGFloat(sin(angle)), y: center.y - r * CGFloat(cos(angle)))
                let size = max(radius * 0.09, 5)
                context.fill(Path(ellipseIn: CGRect(x: blip.x - size * 1.8, y: blip.y - size * 1.8,
                                                    width: size * 3.6, height: size * 3.6)),
                             with: .color(tint.opacity(0.25)))
                context.fill(Path(ellipseIn: CGRect(x: blip.x - size, y: blip.y - size, width: size * 2, height: size * 2)),
                             with: .color(tint))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        #if !os(watchOS)
        .frame(maxWidth: 320)
        .padding(.vertical, 12)
        #endif
        .animation(.easeOut(duration: 0.25), value: distance)
        .accessibilityHidden(true)
    }
}

#Preview {
    RadarScreen(model: AppModel())
        .padding()
}
