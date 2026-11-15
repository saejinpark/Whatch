//
//  ControllerScreen.swift
//  Whatch Watch App
//

import SwiftUI

/// The Watch as a controller for the iPhone: tilt steers, and the pad is a button to hold.
///
/// Motion is streamed for as long as the iPhone has a game or the air pointer open, whichever
/// Watch screen is showing. This screen adds the button and shows what is being sent.
struct ControllerScreen: View {
    @Environment(AppModel.self) private var model

    private let tint = Feature.controller.tint

    var body: some View {
        let sample = model.controllerSample
        let isActive = model.isControllerActive

        VStack(spacing: Layout.spacing) {
            HStack(spacing: 10) {
                TiltIndicator(x: sample.tiltX, y: -sample.tiltY, tint: isActive ? tint : .secondary)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text(isActive ? "보내는 중" : "대기 중")
                        .font(.headline)
                        .foregroundStyle(isActive ? tint : .secondary)
                    Text(isActive ? "손목을 기울여 조종해요" : (model.link.advice ?? "아이폰에서 놀이를 여세요"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }

            // A pad to hold: the pen of the air pointer.
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(model.isControllerPressed ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.card))
                .overlay {
                    Label(model.isControllerPressed ? "누르는 중" : "누르고 있기", systemImage: "hand.tap.fill")
                        .font(.headline)
                        .foregroundStyle(model.isControllerPressed ? .white : tint)
                }
                .frame(maxHeight: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !model.isControllerPressed { model.isControllerPressed = true }
                        }
                        .onEnded { _ in model.isControllerPressed = false }
                )
                .sensoryFeedback(.impact, trigger: model.isControllerPressed)
                .accessibilityLabel("누르고 있기")
                .accessibilityAddTraits(.isButton)
        }
        .onDisappear { model.isControllerPressed = false }
    }
}

/// A dot that slides off-centre as the Watch tilts.
private struct TiltIndicator: View {
    let x: Double
    let y: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2
            let reach = radius - 6
            ZStack {
                Circle().stroke(tint.opacity(0.4), lineWidth: 2)
                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)
                    .offset(x: CGFloat(min(max(x, -1), 1)) * reach, y: CGFloat(min(max(y, -1), 1)) * reach)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ControllerScreen()
        .environment(AppModel())
}
