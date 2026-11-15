//
//  PlayScreens.swift
//  Whatch
//

import SwiftUI

// MARK: - Ball game

/// Runs the ball game at the display's pace.
@MainActor
@Observable
final class BallGameRunner {
    private(set) var game = BallGame(seed: UInt64.random(in: 1...UInt64.max))
    private(set) var best = UserDefaults.standard.integer(forKey: BallGameRunner.bestKey)

    @ObservationIgnored private var loop: Task<Void, Never>?
    private static let bestKey = "ballGameBest"

    /// Starts a round. `tilt` is asked for the current steering before every step.
    func start(tilt: @escaping @MainActor () -> (x: Double, y: Double)) {
        loop?.cancel()
        game.start()
        loop = Task { [weak self] in
            var last = Date()
            while !Task.isCancelled, let self, self.game.isRunning {
                try? await Task.sleep(for: .milliseconds(16))
                let now = Date()
                let steering = tilt()
                self.game.step(dt: now.timeIntervalSince(last), tiltX: steering.x, tiltY: steering.y)
                last = now
            }
            self?.finish()
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    private func finish() {
        guard !game.isRunning, game.score > best else { return }
        best = game.score
        UserDefaults.standard.set(best, forKey: Self.bestKey)
    }
}

/// Tilt the wrist to roll the ball onto the target.
struct BallGameScreen: View {
    @Environment(AppModel.self) private var model
    @State private var runner = BallGameRunner()

    private let tint = Feature.ballGame.tint

    var body: some View {
        let game = runner.game

        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatTile(title: "점수", value: "\(game.score)", tint: tint)
                StatTile(title: "남은 시간", value: "\(Int(game.timeRemaining.rounded(.up)))초")
                StatTile(title: "최고", value: "\(runner.best)")
            }

            Canvas { context, size in
                let side = min(size.width, size.height)
                func circle(_ x: Double, _ y: Double, _ radius: Double) -> Path {
                    Path(ellipseIn: CGRect(x: (x - radius) * side, y: (y - radius) * side,
                                           width: radius * 2 * side, height: radius * 2 * side))
                }
                context.stroke(circle(game.targetX, game.targetY, BallGame.targetRadius),
                               with: .color(.green), lineWidth: 4)
                context.fill(circle(game.targetX, game.targetY, BallGame.targetRadius * 0.45),
                             with: .color(.green.opacity(0.5)))
                context.fill(circle(game.x, game.y, BallGame.ballRadius), with: .color(tint))
                context.fill(circle(game.x - 0.012, game.y - 0.012, BallGame.ballRadius * 0.3),
                             with: .color(.white.opacity(0.7)))
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .overlay {
                if !game.isRunning {
                    VStack(spacing: 12) {
                        if game.score > 0 {
                            Text("\(game.score)점")
                                .font(.system(size: 54, weight: .heavy, design: .rounded))
                        }
                        Button(game.score > 0 ? "다시 하기" : "시작") {
                            runner.start { [model] in
                                guard model.isControllerFresh, let sample = model.controllerSample else { return (0, 0) }
                                // The Watch's y axis points up its screen; the field's points down.
                                return (sample.tiltX, -sample.tiltY)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(tint)
                    }
                }
            }

            ControllerNote(model: model, ready: "손목을 기울여 공을 초록 과녁으로 굴리세요")
        }
        .onAppear { model.setWanted(.motion, true) }
        .onDisappear {
            runner.stop()
            model.setWanted(.motion, false)
        }
        .opensOnCounterpart(.controller, model: model)
    }
}

// MARK: - Air pointer

/// Turns controller readings into a pointer and the strokes it draws.
@MainActor
@Observable
final class AirPointerCanvasModel {
    private(set) var pointer: CGPoint?
    private(set) var strokes: [[CGPoint]] = []
    var invertsVertical = false {
        didSet { mapper.invertsVertical = invertsVertical }
    }

    @ObservationIgnored private var mapper = PointerMapper()
    @ObservationIgnored private var isDrawing = false
    private static let pointLimit = 6000

    func update(_ sample: ControllerSample) {
        let mapped = mapper.point(yaw: sample.yaw, roll: sample.roll)
        let point = CGPoint(x: mapped.x, y: mapped.y)
        pointer = point
        guard sample.isPressed else {
            isDrawing = false
            return
        }
        if isDrawing, !strokes.isEmpty {
            strokes[strokes.count - 1].append(point)
        } else {
            strokes.append([point])
            isDrawing = true
        }
        // Forget the oldest strokes rather than grow without bound.
        while strokes.count > 1, strokes.reduce(0, { $0 + $1.count }) > Self.pointLimit {
            strokes.removeFirst()
        }
    }

    func clear() {
        strokes = []
        isDrawing = false
    }

    /// Makes wherever the arm points now the middle of the canvas.
    func recenter() {
        mapper.recenter()
    }
}

/// Point the arm to move a pointer; hold the pad on the Watch to draw.
struct AirPointerScreen: View {
    @Environment(AppModel.self) private var model
    @State private var canvas = AirPointerCanvasModel()

    private let tint = Feature.airPointer.tint

    var body: some View {
        VStack(spacing: 16) {
            Canvas { context, size in
                func place(_ point: CGPoint) -> CGPoint {
                    CGPoint(x: point.x * size.width, y: point.y * size.height)
                }
                for stroke in canvas.strokes {
                    var path = Path()
                    path.addLines(stroke.map(place))
                    if stroke.count == 1, let only = stroke.first {
                        path.addEllipse(in: CGRect(origin: place(only), size: .zero).insetBy(dx: -3, dy: -3))
                    }
                    context.stroke(path, with: .color(tint),
                                   style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                }
                if let pointer = canvas.pointer {
                    let center = place(pointer)
                    context.stroke(Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)),
                                   with: .color(.primary), lineWidth: 2)
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)),
                                 with: .color(.primary))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))

            HStack(spacing: 12) {
                Button("지우기", systemImage: "trash") { canvas.clear() }
                    .disabled(canvas.strokes.isEmpty)
                Button("중심 맞추기", systemImage: "scope") { canvas.recenter() }
            }
            .buttonStyle(.bordered)
            .tint(tint)

            Toggle("위아래 반대로", isOn: $canvas.invertsVertical)
                .card()

            ControllerNote(model: model, ready: "팔을 움직여 포인터를 옮기고, 워치의 패드를 누르는 동안 그려요")
        }
        .onChange(of: model.controllerSampleDate) {
            if let sample = model.controllerSample {
                canvas.update(sample)
            }
        }
        .onAppear { model.setWanted(.motion, true) }
        .onDisappear { model.setWanted(.motion, false) }
        .opensOnCounterpart(.controller, model: model)
    }
}

/// Says whether the Watch's controller is being heard, and what to do if not.
private struct ControllerNote: View {
    let model: AppModel
    let ready: String

    var body: some View {
        // The sample date changes with every reading, which keeps this current.
        let isFresh = model.controllerSampleDate.timeIntervalSinceNow > -2
        if isFresh {
            Label(ready, systemImage: "applewatch.radiowaves.left.and.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } else {
            LinkAdvice(text: model.link.advice ?? "워치의 컨트롤러 신호를 기다리는 중이에요")
        }
    }
}

#Preview("Ball") {
    BallGameScreen()
        .padding()
        .environment(AppModel())
}

#Preview("Pointer") {
    AirPointerScreen()
        .padding()
        .environment(AppModel())
}
