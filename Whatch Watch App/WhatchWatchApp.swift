//
//  WhatchWatchApp.swift
//  Whatch Watch App
//

import SwiftData
import SwiftUI

@main
struct WhatchWatchApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .modelContainer(for: Pixel.self)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    switch phase {
                    case .active: model.start()
                    case .background: model.stop()
                    default: break
                    }
                }
        }
    }
}
