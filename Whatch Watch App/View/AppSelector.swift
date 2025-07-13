//
//  AppSelectorView.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/5/25.
//

import SwiftUI

struct AppSelector: View {
    @Binding var selectedFeature: Feature?
    @Environment(\.dismiss) private var dismiss
    @State var page = 1
    
    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                // 🟥 Watch 전용 기능 탭
                Form {
                    List {
                        Section("Watch") {
                            Button {
                                selectedFeature = .accelerometer
                                dismiss()
                            } label: {
                                FeatureRow(feature: .accelerometer)
                            }
                            
                            Button {
                                selectedFeature = .rollTrackerX
                                dismiss()
                            } label: {
                                FeatureRow(feature: .rollTrackerX)
                            }
                            
                            Button {
                                selectedFeature = .rollTrackerY
                                dismiss()
                            } label: {
                                FeatureRow(feature: .rollTrackerY)
                            }
                            
                            Button {
                                selectedFeature = .vibrationDetector
                                dismiss()
                            } label: {
                                FeatureRow(feature: .vibrationDetector)
                            }
                            
                            Button {
                                selectedFeature = .watchBoard
                                dismiss()
                            } label: {
                                FeatureRow(feature: .watchBoard)
                            }
                        }
                    }
                }
                .tag(1)

                // 🟩 Watch + Phone 연동 기능 탭
                Form {
                    List {
                        Section("Phone + Watch") {
                            Button {
                                selectedFeature = .pingTest
                                dismiss()
                            } label: {
                                FeatureRow(feature: .pingTest)
                            }
                            
                            Button {
                                selectedFeature = .flashlight
                                dismiss()
                            } label: {
                                FeatureRow(feature: .flashlight)
                            }
                            
                            Button {
                                selectedFeature = .hapticController
                                dismiss()
                            } label: {
                                FeatureRow(feature: .hapticController)
                            }
                            Button {
                                selectedFeature = .headingMonitor
                                dismiss()
                            } label: {
                                FeatureRow(feature: .headingMonitor)
                            }
                            Button {
                                selectedFeature = .batteryStatus
                                dismiss()
                            } label: {
                                FeatureRow(feature: .batteryStatus)
                            }
                        }
                    }
                    
                }
                .tag(2)


            }
            .tabViewStyle(.page)
            .navigationTitle("앱 목록")
        }
    }
}

#Preview {
    AppSelector(selectedFeature: .constant(.accelerometer))
}
