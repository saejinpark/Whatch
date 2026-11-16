//
//  RadarScreen.swift
//  Whatch
//

import SwiftUI

/// Distance to the other device, measured with ultra-wideband, and two things to do with it:
/// measure a length between the devices, and estimate a height from arm span.
struct RadarScreen: View {
    let model: AppModel

    /// What a measurement is for.
    private enum Kind: String {
        case length
        case height
    }

    /// `-measure length` or `-measure height` on the command line starts that measurement as soon
    /// as the radar has a reading, so the flow can be checked without anyone tapping.
    private static let requestedKind = UserDefaults.standard.string(forKey: "measure").flatMap(Kind.init(rawValue:))
    @State private var didAutoStart = false

    @State private var measure = SteadyDistance()
    @State private var kind = Kind.length
    /// The time of the latest tick, so the countdown redraws.
    @State private var now = Date()
    #if os(iOS)
    @State private var isCalibrating = false
    @State private var knownHeight = 170
    @State private var calibrationNote: String?
    #endif

    var body: some View {
        let ranging = model.ranging

        VStack(spacing: Layout.spacing) {
            if measure.phase == .idle {
                radar(ranging)
            } else {
                measurement
            }
        }
        .animation(.default, value: measure.phase)
        .onAppear { ranging.start() }
        .onDisappear { ranging.stop() }
        .task(id: measure.isRunning) {
            await run()
        }
        .onChange(of: measure.phase) { old, new in
            signal(from: old, to: new)
        }
        // A measurement in progress means nothing without readings.
        .onChange(of: ranging.status, initial: true) { _, status in
            if status != .ranging, measure.isRunning {
                measure.reset()
            }
            if status == .ranging, !didAutoStart, let kind = Self.requestedKind {
                didAutoStart = true
                begin(kind)
            }
        }
    }

    // MARK: Radar

    @ViewBuilder
    private func radar(_ ranging: RangingService) -> some View {
        RadarDial(distance: ranging.distance, bearing: ranging.bearing, tint: Feature.radar.tint)
            .frame(maxHeight: .infinity)

        Text(ranging.distance.map(DistanceFormat.text(meters:)) ?? "--")
            .font(.system(size: Layout.heroFont * 0.7, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.default, value: ranging.distance.map { Int($0 * 20) })

        if showsCaption(ranging) {
            Text(caption(ranging))
                .font(Layout.footnoteFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }

        HStack(spacing: Layout.spacing) {
            Button {
                begin(.length)
            } label: {
                Label("길이", systemImage: "ruler")
                    .frame(maxWidth: .infinity)
            }
            Button {
                begin(.height)
            } label: {
                Label("키", systemImage: "figure.arms.open")
                    .frame(maxWidth: .infinity)
            }
        }
        .disabled(ranging.status != .ranging)
        .tint(Feature.radar.tint)
        #if os(watchOS)
        .font(.caption)
        .buttonStyle(.bordered)
        .controlSize(.small)
        #else
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        #endif

        #if !os(watchOS)
        Text("길이는 두 기기를 양 끝에 대고, 키는 한 손에 아이폰을 쥐고 양팔을 벌려서 재요. 초광대역 특성상 10 cm 안팎의 오차가 있어요.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        #endif
    }

    /// The Watch has no room for a caption that only says the obvious.
    private func showsCaption(_ ranging: RangingService) -> Bool {
        #if os(watchOS)
        ranging.status != .ranging
        #else
        true
        #endif
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

    // MARK: Measuring

    @ViewBuilder
    private var measurement: some View {
        Spacer(minLength: 0)
        switch measure.phase {
        case .idle:
            EmptyView()
        case .preparing:
            hero("\(measure.countdown(now: now))")
            note(kind == .length ? "두 기기를 재려는 양 끝에 대세요" : "한 손에 아이폰을 쥐고 양팔을 쭉 벌리세요")
        case .measuring:
            ProgressView()
                .controlSize(.large)
                .tint(Feature.radar.tint)
            note("진동이 올 때까지 가만히 있어요")
        case .done(let result):
            hero(resultText(result))
            note(resultNote(result), isWarning: !result.isSteady)
            #if os(iOS)
            if kind == .height {
                calibration(result)
            }
            #endif
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: Layout.heroFont * 0.5))
                .foregroundStyle(.orange)
            note("거리를 읽지 못했어요. 두 기기가 서로 보이게 해 주세요", isWarning: true)
        }
        Spacer(minLength: 0)

        HStack(spacing: Layout.spacing) {
            if !measure.isRunning {
                Button {
                    begin(kind)
                } label: {
                    Label("다시", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
            }
            Button(role: .cancel) {
                measure.reset()
            } label: {
                Text(measure.isRunning ? "취소" : "닫기")
                    .frame(maxWidth: .infinity)
            }
        }
        .tint(Feature.radar.tint)
        .buttonStyle(.bordered)
        #if os(watchOS)
        .font(.caption)
        .controlSize(.small)
        #else
        .controlSize(.large)
        #endif
    }

    private func hero(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.heroFont, weight: .bold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .contentTransition(.numericText())
    }

    private func note(_ text: String, isWarning: Bool = false) -> some View {
        Text(text)
            .font(Layout.footnoteFont)
            .foregroundStyle(isWarning ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.8)
    }

    private func resultText(_ result: SteadyDistance.Result) -> String {
        switch kind {
        case .length:
            DistanceFormat.text(meters: result.meters)
        case .height:
            DistanceFormat.height(meters: ArmSpan.height(distance: result.meters, offset: model.armSpanOffset))
        }
    }

    private func resultNote(_ result: SteadyDistance.Result) -> String {
        guard result.isSteady else {
            return "값이 흔들렸어요. 가만히 있고 다시 재 보세요"
        }
        switch kind {
        case .length:
            return "두 기기 사이 거리 · 오차 약 ±10\u{00A0}cm"
        case .height:
            return model.isArmSpanCalibrated
                ? "양팔 길이로 추정한 키 · 보정값 사용"
                : "양팔 길이로 추정한 키 · 평균 체형 기준"
        }
    }

    #if os(iOS)
    /// Lets someone whose height is known replace the average-body guess with their own measurement.
    @ViewBuilder
    private func calibration(_ result: SteadyDistance.Result) -> some View {
        VStack(spacing: 10) {
            if isCalibrating {
                Stepper(value: $knownHeight, in: 80...230) {
                    Text("실제 키 \(knownHeight) cm")
                        .font(.headline)
                        .monospacedDigit()
                }
                Button("이 키로 보정하기") {
                    let done = model.calibrateArmSpan(height: Double(knownHeight) / 100, distance: result.meters)
                    calibrationNote = done ? "보정했어요. 이제 다른 사람도 이 기준으로 잴 수 있어요"
                                           : "잰 길이와 키가 너무 달라요. 양팔을 쭉 벌리고 다시 재 주세요"
                    isCalibrating = !done
                }
                .buttonStyle(.borderedProminent)
                .tint(Feature.radar.tint)
            } else {
                HStack(spacing: 12) {
                    Button("내 키로 보정", systemImage: "slider.horizontal.3") {
                        knownHeight = Int((ArmSpan.height(distance: result.meters, offset: model.armSpanOffset) * 100).rounded())
                        calibrationNote = nil
                        isCalibrating = true
                    }
                    if model.isArmSpanCalibrated {
                        Button("보정 지우기", role: .destructive) {
                            model.resetArmSpan()
                            calibrationNote = "평균 체형 기준으로 되돌렸어요"
                        }
                    }
                }
                .font(.subheadline)
                .buttonStyle(.bordered)
                .tint(Feature.radar.tint)
            }
            if let calibrationNote {
                Text(calibrationNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .card()
    }
    #endif

    private func begin(_ kind: Kind) {
        self.kind = kind
        #if os(iOS)
        isCalibrating = false
        calibrationNote = nil
        #endif
        now = Date()
        measure.start(now: now)
    }

    /// Feeds the measurement while it runs: every new reading once, and a tick in between.
    private func run() async {
        guard measure.isRunning else { return }
        let ranging = model.ranging
        var seen = ranging.readingCount
        while !Task.isCancelled, measure.isRunning {
            let date = Date()
            if ranging.readingCount != seen, let distance = ranging.distance {
                seen = ranging.readingCount
                measure.add(distance, now: date)
            } else {
                measure.tick(now: date)
            }
            now = date
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Whoever is measuring is not looking at the screen, so each step is felt instead.
    private func signal(from old: SteadyDistance.Phase, to new: SteadyDistance.Phase) {
        switch new {
        case .measuring:
            Haptics.play(.begin)
        case .done(let result):
            Haptics.play(result.isSteady ? .done : .trouble)
        case .failed:
            Haptics.play(.trouble)
        case .idle, .preparing:
            break
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
