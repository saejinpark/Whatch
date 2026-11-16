//
//  Haptics.swift
//  Whatch
//

#if os(watchOS)
import WatchKit
#else
import AudioToolbox
import UIKit
#endif

/// Short signals for moments when nobody is looking at the screen.
@MainActor
enum Haptics {
    enum Signal {
        /// Something started; keep doing what you are doing.
        case begin
        /// It finished.
        case done
        /// It finished badly or not at all.
        case trouble
    }

    static func play(_ signal: Signal) {
        #if os(watchOS)
        let device = WKInterfaceDevice.current()
        switch signal {
        case .begin: device.play(.start)
        case .done: device.play(.success)
        case .trouble: device.play(.failure)
        }
        #else
        switch signal {
        case .begin:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .done:
            // A full vibration: a tap is easy to miss in a hand held out at arm's length.
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        case .trouble:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}
