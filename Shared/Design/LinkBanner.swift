//
//  LinkBanner.swift
//  Whatch
//

import SwiftUI

/// Connection status with what to do about it, when something needs doing.
struct LinkBanner: View {
    let status: LinkStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.systemImage)
                .foregroundStyle(status.tint)
                .font(.title3)
                .symbolEffect(.pulse, isActive: status == .connecting)
            VStack(alignment: .leading, spacing: 1) {
                Text(status.title)
                    .font(.headline)
                if let advice = status.advice {
                    Text(advice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// One caption line of advice, shown only when the connection needs attention.
struct LinkAdvice: View {
    let text: String?

    var body: some View {
        if let text {
            Label(text, systemImage: "exclamationmark.triangle.fill")
                .font(Layout.footnoteFont)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .transition(.opacity)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        LinkBanner(status: .connected)
        LinkBanner(status: .unreachable)
        LinkBanner(status: .needsForeground)
        LinkAdvice(text: "아이폰에서 Whatch를 열어 주세요")
    }
    .padding()
}
