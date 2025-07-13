//
//  AppSelector.swift
//  Whatch
//
//  Created by 박세진 on 7/8/25.
//

import SwiftUI

struct AppSelector: View {
    @Binding var selectedFeature: Feature?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                List {
                    Section("Phone + Watch") {
                        Button {
                            selectedFeature = .pingTest
                            dismiss()
                        } label: {
                            DescriptiveIconRow(item: Feature.pingTest)
                        }

                        Button {
                            selectedFeature = .flashlight
                            dismiss()
                        } label: {
                            DescriptiveIconRow(item: Feature.flashlight)
                        }

                        Button {
                            selectedFeature = .hapticController
                            dismiss()
                        } label: {
                            DescriptiveIconRow(item: Feature.hapticController)
                        }

                        Button {
                            selectedFeature = .headingMonitor
                            dismiss()
                        } label: {
                            DescriptiveIconRow(item: Feature.headingMonitor)
                        }

                        Button {
                            selectedFeature = .batteryStatus
                            dismiss()
                        } label: {
                            DescriptiveIconRow(item: Feature.batteryStatus)
                        }
                    }
                }

            }
            .navigationTitle("앱 목록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
