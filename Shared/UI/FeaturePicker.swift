//
//  FeaturePicker.swift
//  Whatch
//

import SwiftUI

/// Sheet that lets the user pick which feature to show.
struct FeaturePicker: View {
    @Binding var selection: Feature?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                #if os(watchOS)
                TabView {
                    ForEach(Feature.availableGroups) { group in
                        Form {
                            section(for: group)
                        }
                    }
                }
                .tabViewStyle(.page)
                #else
                Form {
                    ForEach(Feature.availableGroups) { group in
                        section(for: group)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                }
                #endif
            }
            .navigationTitle("앱 목록")
        }
    }

    private func section(for group: Feature.Group) -> some View {
        Section(group.title) {
            ForEach(group.features) { feature in
                Button {
                    selection = feature
                    dismiss()
                } label: {
                    FeatureRow(feature: feature)
                }
            }
        }
    }
}

#Preview {
    FeaturePicker(selection: .constant(.pingTest))
}
