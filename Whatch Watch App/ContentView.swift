//
//  ContentView.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/5/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var isPresented = false
    @AppStorage("selectedFeature") var selectedFeature: Feature?
    
    @Environment(\.modelContext) private var context
    @StateObject private var manager = WatchBoardManager()
    @FocusState private var focusedField: Axis?
    @Query(sort: \Pixel.id) var savedPixels: [Pixel]
    
    
    var body: some View {
        NavigationStack {
            VStack {
                if let feature = selectedFeature {
                    switch feature {
                    case .accelerometer:
                        AccelerometerContentView()
                    case .rollTrackerX:
                        RollTrackerXContentView()
                    case .rollTrackerY:
                        RollTrackerYContentView()
                    case .vibrationDetector:
                        VibrationDetectorContentView()
                    case .watchBoard:
                        GeometryReader { geometry in
                            let size = geometry.size
                            let width = Int(size.width)
                            let height = Int(size.height)

                            Color.clear
                                .onChange(of: size, initial: false) {
                                    guard manager.unit == 0, width > 0, height > 0 else { return }
                                    print("💡 width:", width, "height:", height)
                                    manager.setupGrid(width: width, height: height, context: context, existingPixels: savedPixels)
                                    DispatchQueue.main.async {
                                        focusedField = .row
                                    }
                                }

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.fixed(CGFloat(manager.unit)), spacing: 0), count: manager.columnLimit),
                                spacing: 0
                            ) {
                                ForEach(manager.pixels, id: \.id) { pixel in
                                    Rectangle()
                                        .fill(pixel.color)
                                        .frame(width: CGFloat(manager.unit), height: CGFloat(manager.unit))
                                        .overlay {
                                            if manager.row == pixel.row && manager.column == pixel.column {
                                                Image(systemName: "plus")
                                            }
                                        }
                                }
                            }

                            // ✅ 디지털 크라운 바인딩
                            Rectangle()
                                .frame(width: 1, height: 1)
                                .opacity(0)
                                .focusable(true)
                                .focused($focusedField, equals: .row)
                                .digitalCrownRotation(
                                    Binding(get: { Double(manager.row) }, set: {
                                        manager.row = Int($0)
                                        manager.applyIfNeeded(context: context)
                                    }),
                                    from: 0,
                                    through: Double(max(manager.rowLimit - 1, 0)),
                                    by: 1,
                                    sensitivity: .low
                                )

                            Rectangle()
                                .frame(width: 1, height: 1)
                                .opacity(0)
                                .focusable(true)
                                .focused($focusedField, equals: .column)
                                .digitalCrownRotation(
                                    Binding(get: { Double(manager.column) }, set: {
                                        manager.column = Int($0)
                                        manager.applyIfNeeded(context: context)
                                    }),
                                    from: 0,
                                    through: Double(max(manager.columnLimit - 1, 0)),
                                    by: 1,
                                    sensitivity: .low
                                )
                        }
                    case .pingTest:
                        PingTestContentView()
                    case .flashlight:
                        FlashLightContentView()
                    case .hapticController:
                        HapticControllerContentView()
                    case .headingMonitor:
                        HeadingMonitorContentView()
                    case .batteryStatus:
                        BatteryStatusContentView()
                    default:
                        ContentUnavailableView(label: {
                            Label("선택되지 않음", systemImage: "questionmark")
                        })
                    }
                } else {
                    ContentUnavailableView(label: {
                        Label("선택되지 않음", systemImage: "questionmark")
                    })
                }
                
            }
            .navigationTitle(
                selectedFeature?.description ?? "기능을 선택해주세요"
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresented = true
                    } label: {
                        Label("app", systemImage: "list.bullet")
                    }
                }
                
                if selectedFeature == .watchBoard {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            // ✅ 축 전환 버튼 (아이콘 전용)
                            Button {
                                focusedField = focusedField == .row ? .column : .row
                            } label: {
                                Label("축 전환", systemImage: focusedField == .row ? "digitalcrown.arrow.clockwise.fill" : "digitalcrown.horizontal.arrow.counterclockwise.fill")
                                    .labelStyle(.iconOnly)
                                    .accessibilityLabel(focusedField == .row ? "세로 축" : "가로 축")
                            }

                            Spacer()

                            // ✅ 색상 선택기
                            Button {
                                manager.setColor(manager.selectedColor.nextColor, context: context)
                            } label: {
                                Circle().fill(manager.selectedColor.color)
                            }
                            Spacer()

                            // ✅ 펜 업/다운 토글
                            Button {
                                manager.setPenDown(!manager.isPenDown, context: context)
                            } label: {
                                Label("펜 상태", systemImage: manager.isPenDown ? "pencil" : "pencil.slash")
                                    .labelStyle(.iconOnly)
                                    .accessibilityLabel(manager.isPenDown ? "펜 내림" : "펜 올림")
                            }
                            .tint(manager.isPenDown ? .gray : .none)
                        }
                    }
                }
            }
            .sheet(isPresented: $isPresented) {
                AppSelector(selectedFeature: $selectedFeature)
            }
            .onAppear {
                if selectedFeature == nil {
                    isPresented = true
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
