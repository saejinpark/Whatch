//
//  DuelScreen.swift
//  Whatch
//

import SwiftUI

/// Reaction duel: one player on each device, first to tap after "go" wins.
struct DuelScreen: View {
    let model: AppModel

    var body: some View {
        let duel = model.duel.duel

        VStack(spacing: Layout.spacing) {
            Button {
                switch duel.phase {
                case .idle, .finished: model.duel.startRound()
                case .waiting, .go: model.duel.tap()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: icon(duel))
                        .font(.system(size: Layout.heroFont * 0.6, weight: .bold))
                    Text(title(duel))
                        .font(.system(size: Layout.heroFont * 0.5, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(subtitle(duel))
                        .font(Layout.footnoteFont)
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color(duel).gradient, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            #if !os(watchOS)
            .frame(height: 300)
            #endif

            HStack(spacing: Layout.spacing) {
                StatTile(title: "나", value: timeText(duel.myTime))
                StatTile(title: "\(duel.wins) : \(duel.losses)", value: "VS", tint: .secondary)
                StatTile(title: Device.counterpartShortName, value: timeText(duel.phase == .finished ? duel.theirTime : nil))
            }

            #if !os(watchOS)
            if !model.link.isConnected {
                LinkAdvice(text: "연결이 없으면 혼자 연습해요. " + (model.link.advice ?? ""))
            }
            #endif
        }
        .animation(.easeOut(duration: 0.12), value: duel.phase)
        .sensoryFeedback(.impact(weight: .heavy), trigger: duel.phase == .go)
        .opensOnCounterpart(.duel, model: model)
    }

    private func color(_ duel: ReactionDuel) -> Color {
        switch duel.phase {
        case .idle: Feature.duel.tint
        case .waiting: .red
        case .go: .green
        case .finished:
            switch duel.outcome {
            case .win: .green
            case .lose: .gray
            case .draw, nil: .indigo
            }
        }
    }

    private func icon(_ duel: ReactionDuel) -> String {
        switch duel.phase {
        case .idle: "bolt.fill"
        case .waiting: "hand.raised.fill"
        case .go: "hand.tap.fill"
        case .finished:
            switch duel.outcome {
            case .win: "trophy.fill"
            case .lose: "tortoise.fill"
            case .draw: "equal.circle.fill"
            case nil: "hourglass"
            }
        }
    }

    private func title(_ duel: ReactionDuel) -> String {
        switch duel.phase {
        case .idle: "시작"
        case .waiting: "기다려…"
        case .go: "지금!"
        case .finished:
            switch duel.outcome {
            case .win: "승리"
            case .lose: "패배"
            case .draw: "무승부"
            case nil: duel.myTime == ReactionDuel.falseStart ? "부정 출발" : timeText(duel.myTime)
            }
        }
    }

    private func subtitle(_ duel: ReactionDuel) -> String {
        switch duel.phase {
        case .idle: "탭하면 두 기기에서 시작해요"
        case .waiting: "초록색이 되면 탭!"
        case .go: "탭!"
        case .finished: duel.outcome == nil ? "상대를 기다리는 중 · 탭하면 다시" : "탭하면 다시"
        }
    }

    private func timeText(_ time: Int?) -> String {
        guard let time else { return "--" }
        return time == ReactionDuel.falseStart ? "부정 출발" : "\(time) ms"
    }
}

#Preview {
    DuelScreen(model: AppModel())
        .padding()
}
