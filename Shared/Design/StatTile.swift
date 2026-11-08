//
//  StatTile.swift
//  Whatch
//

import SwiftUI

/// A small labelled number.
struct StatTile: View {
    let title: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(Layout.tileValueFont)
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(Layout.footnoteFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.tilePadding)
        .padding(.horizontal, 4)
        .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        StatTile(title: "평균", value: "24 ms")
        StatTile(title: "손실", value: "0", tint: .red)
    }
    .padding()
}
