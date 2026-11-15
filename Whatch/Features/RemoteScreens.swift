//
//  RemoteScreens.swift
//  Whatch
//

import SwiftUI

/// The Watch Board, live on the big screen, with a way to save it.
struct MirrorScreen: View {
    @Environment(AppModel.self) private var model
    @State private var shareImage: Image?

    private let tint = Feature.mirror.tint

    var body: some View {
        VStack(spacing: 20) {
            Group {
                if let board = model.mirroredBoard {
                    BoardCanvas(board: board)
                } else {
                    BoardCanvas(board: Board())
                        .overlay {
                            Label("워치의 그림을 기다리는 중", systemImage: "applewatch")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

            if let shareImage {
                ShareLink(item: shareImage, preview: SharePreview("와치보드", image: shareImage)) {
                    Label("저장 및 공유", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(tint)
            }

            Label("워치에서 와치보드에 그리면 여기에 바로 나타나요", systemImage: "hand.draw")
                .font(.footnote)
                .foregroundStyle(.secondary)
            LinkAdvice(text: model.link.advice)
        }
        .onAppear { model.setWanted(.board, true) }
        .onDisappear { model.setWanted(.board, false) }
        .opensOnCounterpart(.board, model: model)
        .onChange(of: model.mirroredBoard, initial: true) { _, board in
            shareImage = board.flatMap(Self.render)
        }
    }

    /// The board as a picture, for the share sheet.
    private static func render(_ board: Board) -> Image? {
        guard !board.isEmpty else { return nil }
        let renderer = ImageRenderer(content: BoardCanvas(board: board).frame(width: 1200, height: 800))
        renderer.scale = 1
        return renderer.uiImage.map(Image.init(uiImage:))
    }
}

/// Sends taps and Morse code to the Watch's Taptic Engine.
struct BuzzScreen: View {
    @Environment(AppModel.self) private var model
    @State private var text = "SOS"
    @State private var lastSent: String?
    @State private var didFail = false
    @FocusState private var isTyping: Bool

    private let tint = Feature.buzz.tint
    private let presets: [(title: String, pattern: String)] = [
        ("톡", "."), ("톡톡", ". ."), ("길게", "-"), ("SOS", "... --- ..."),
    ]

    var body: some View {
        let pattern = MorseCode.pattern(for: text)

        VStack(spacing: 20) {
            HStack(spacing: 12) {
                ForEach(presets, id: \.title) { preset in
                    Button {
                        send(preset.pattern)
                    } label: {
                        VStack(spacing: 6) {
                            Text(MorseCode.display(preset.pattern))
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text(preset.title)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("모스부호")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("영문과 숫자", text: $text)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($isTyping)
                    .submitLabel(.send)
                    .onSubmit { send(pattern) }
                    .padding(12)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(pattern.isEmpty ? "영문 글자나 숫자를 입력하세요" : MorseCode.display(MorseCode.sanitized(pattern)))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(pattern.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                Button {
                    isTyping = false
                    send(pattern)
                } label: {
                    Label("워치로 보내기", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(tint)
                .disabled(pattern.isEmpty)
            }
            .card()

            if didFail {
                LinkAdvice(text: model.link.advice ?? "워치에 보내지 못했어요")
            } else if let lastSent {
                Label("보냄  \(MorseCode.display(lastSent))", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text("워치에서 Whatch가 열려 있을 때 울려요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .sensoryFeedback(.success, trigger: lastSent)
    }

    private func send(_ pattern: String) {
        let pattern = MorseCode.sanitized(pattern)
        guard !pattern.isEmpty else { return }
        didFail = !model.sendBuzz(pattern)
        lastSent = didFail ? nil : pattern
    }
}

#Preview("Mirror") {
    MirrorScreen()
        .padding()
        .environment(AppModel())
}

#Preview("Buzz") {
    BuzzScreen()
        .padding()
        .environment(AppModel())
}
