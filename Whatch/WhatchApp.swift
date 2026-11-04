//
//  WhatchApp.swift
//  Whatch
//

import SwiftUI

@main
struct WhatchApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
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
