//
//  SelfTest.swift
//  Whatch
//

import Foundation
#if os(watchOS)
import CoreMotion
#endif

/// A hardware check that runs when the app is launched with `-selfTest`.
///
/// It exercises the real sensors and the real connection and prints one line per check
/// to standard output, so a developer can run it on a device from the command line:
///
///     xcrun devicectl device process launch --console --device <id> <bundle id> -selfTest
@MainActor
enum SelfTest {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-selfTest")
    }

    static func run(model: AppModel) async {
        line("START", Device.name)

        model.battery.refresh()
        let battery = model.battery.reading
        report("battery", battery.level != nil, battery.percentText + (battery.isCharging ? " charging" : ""))

        model.setHeadingVisible(true)
        let heading = await wait(seconds: 6) { model.heading.heading }
        report("heading", heading != nil,
               heading.map { "\(Int($0))° \(model.heading.isTrueNorth ? "true" : "magnetic") north" } ?? "no reading")

        let activated = await wait(seconds: 6) { model.session.isActivated ? true : nil } != nil
        report("session", activated,
               "paired=\(model.session.isPaired) installed=\(model.session.isCounterpartInstalled) reachable=\(model.session.isReachable)")

        if await wait(seconds: 12, { model.session.isReachable ? true : nil }) != nil {
            await checkLink(model)
        } else {
            skip("ping", "\(Device.counterpartName) app is not reachable")
            skip("state", "\(Device.counterpartName) app is not reachable")
        }

        #if os(iOS)
        await checkPhoneHardware(model)
        #else
        await checkMotion()
        #endif

        model.setHeadingVisible(false)
        line("DONE", "")
    }

    private static func checkLink(_ model: AppModel) async {
        model.ping.start()
        let latency = await wait(seconds: 10) { model.ping.tracker.latency }
        model.ping.stop()
        report("ping", latency != nil, latency.map { "\(Int($0 * 1000)) ms round trip" } ?? "no answer")

        model.session.send(.stateRequest)
        let remote = await wait(seconds: 6) { model.isRemoteLive ? model.remote : nil }
        report("state", remote != nil, remote.map {
            "\(Device.counterpartName) battery=\(BatteryReading(level: $0.batteryLevel).percentText) foreground=\($0.isForeground)"
        } ?? "no answer")

        // The heading screen is "open" for the duration of the test, so a counterpart on screen streams its compass.
        if remote?.isForeground == true {
            let theirs = await wait(seconds: 6) { model.remoteHeading }
            report("remote heading", theirs != nil, theirs.map { "\(Device.counterpartName) points \(Int($0))°" } ?? "no value")
        } else {
            skip("remote heading", "\(Device.counterpartName) app is not on screen")
        }

        await checkStreams(model, counterpartOnScreen: remote?.isForeground == true)

        #if os(watchOS)
        // Drive the iPhone torch for real if its app is on screen; otherwise expect a refusal.
        guard let remote else { return }
        let before = remote.timestamp
        model.setRemoteFlashlight(true)
        if remote.isForeground {
            let lit = await wait(seconds: 6) { model.isRemoteFlashlightOn ? true : nil } != nil
            report("remote flashlight", lit, lit ? "iPhone torch came on" : "iPhone did not confirm")
            model.setRemoteFlashlight(false)
            let dark = await wait(seconds: 6) { model.isRemoteFlashlightOn ? nil : true } != nil
            report("remote flashlight off", dark, dark ? "iPhone torch went off" : "iPhone did not confirm")
        } else {
            // A newer state must arrive in answer to the command, still reporting the torch as off.
            let answered = await wait(seconds: 6) { (model.remote?.timestamp ?? before) > before ? true : nil } != nil
            report("remote refusal", answered && !model.isRemoteFlashlightOn && model.link == .needsForeground,
                   answered ? "iPhone app is in the background and said so" : "iPhone did not answer")
        }
        #endif
    }

    /// The streams and commands behind the newer features.
    private static func checkStreams(_ model: AppModel, counterpartOnScreen: Bool) async {
        #if os(watchOS)
        // The iPhone stores a brightness even while its app is in the background.
        let original = model.remoteFlashlightBrightness
        let target = original > 0.6 ? 0.4 : 0.8
        model.setRemoteFlashlightBrightness(target)
        let applied = await wait(seconds: 8) { abs(model.remoteFlashlightBrightness - target) < 0.01 ? true : nil } != nil
        report("remote brightness", applied,
               applied ? "iPhone set its torch to \(Int(target * 100))%" : "iPhone did not confirm")
        model.setRemoteFlashlightBrightness(original)
        #endif

        guard counterpartOnScreen else {
            return skip("streams", "\(Device.counterpartName) app is not on screen")
        }

        model.setAltitudeVisible(true)
        let height = await wait(seconds: 10) { model.height.meters }
        report("pressure exchange", height != nil,
               height.map { "height difference \(DistanceFormat.text(meters: $0))" } ?? "no pressure from both barometers")
        model.setAltitudeVisible(false)

        if RangingService.isSupported {
            model.ranging.start()
            let distance = await wait(seconds: 12) { model.ranging.distance }
            report("ranging", distance != nil,
                   distance.map { "\(Device.counterpartName) is \(DistanceFormat.text(meters: $0)) away" } ?? "no distance (\(model.ranging.status))")
            model.ranging.stop()
        } else {
            skip("ranging", "no ultra-wideband on this device")
        }

        #if os(iOS)
        model.setWanted(.board, true)
        let board = await wait(seconds: 8) { model.mirroredBoard }
        report("board mirror", board != nil, board.map { "\($0.columns)x\($0.rows) board received" } ?? "no board")
        model.setWanted(.board, false)

        model.setWanted(.motion, true)
        let sample = await wait(seconds: 8) { model.controllerSample }
        report("controller stream", sample != nil,
               sample.map { String(format: "tilt %.2f, %.2f", $0.tiltX, $0.tiltY) } ?? "no sample")
        model.setWanted(.motion, false)

        report("buzz", model.sendBuzz(".-"), "sent a dot and a dash to the Watch")
        #endif
    }

    #if os(iOS)
    private static func checkPhoneHardware(_ model: AppModel) async {
        guard model.flashlight.hasTorch else {
            skip("torch", "no torch on this device")
            return await checkHaptics(model)
        }
        model.flashlight.setOn(true)
        try? await Task.sleep(for: .milliseconds(500))
        let lit = model.flashlight.isOn && model.flashlight.isTorchActive
        model.flashlight.setOn(false)
        try? await Task.sleep(for: .milliseconds(300))
        let dark = !model.flashlight.isOn && !model.flashlight.isTorchActive
        report("torch", lit && dark, "on=\(lit) off=\(dark)")

        // Every brightness must be a level AVFoundation accepts; an invalid one crashes the app.
        let original = model.flashlight.brightness
        var dimLit = true
        for brightness in [0.1, 0.5, 1.0] {
            model.flashlight.brightness = brightness
            model.flashlight.setOn(true)
            try? await Task.sleep(for: .milliseconds(250))
            dimLit = dimLit && model.flashlight.isTorchActive
            model.flashlight.setOn(false)
            try? await Task.sleep(for: .milliseconds(150))
        }
        model.flashlight.brightness = original
        report("torch brightness", dimLit, "lit at 10%, 50% and 100%")
        await checkHaptics(model)
    }

    private static func checkHaptics(_ model: AppModel) async {
        guard model.haptic.isSupported else {
            return skip("haptics", "not supported on this device")
        }
        model.haptic.setPlaying(true)
        try? await Task.sleep(for: .milliseconds(500))
        let played = model.haptic.isPlaying
        model.haptic.setPlaying(false)
        report("haptics", played && !model.haptic.isPlaying, played ? "engine played and stopped" : "engine did not start")
    }
    #else
    private static func checkMotion() async {
        #if targetEnvironment(simulator)
        skip("motion", "simulators have no motion sensors")
        #else
        let manager = CMMotionManager()
        report("accelerometer available", manager.isAccelerometerAvailable, "")
        report("device motion available", manager.isDeviceMotionAvailable, "")

        manager.accelerometerUpdateInterval = 0.02
        manager.startAccelerometerUpdates()
        let acceleration = await wait(seconds: 4) { manager.accelerometerData?.acceleration }
        manager.stopAccelerometerUpdates()
        report("accelerometer data", acceleration != nil, acceleration.map {
            String(format: "%.2f G", ($0.x * $0.x + $0.y * $0.y + $0.z * $0.z).squareRoot())
        } ?? "no sample")

        manager.deviceMotionUpdateInterval = 0.02
        manager.startDeviceMotionUpdates()
        let attitude = await wait(seconds: 4) { manager.deviceMotion?.attitude }
        manager.stopDeviceMotionUpdates()
        report("device motion data", attitude != nil, attitude.map {
            String(format: "yaw %.0f° roll %.0f°", $0.yaw * 180 / .pi, $0.roll * 180 / .pi)
        } ?? "no sample")
        #endif
    }
    #endif

    // MARK: Helpers

    /// Polls `value` until it returns something or the time is up.
    private static func wait<T>(seconds: Double, _ value: () -> T?) async -> T? {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if let result = value() { return result }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return value()
    }

    private static func report(_ name: String, _ passed: Bool, _ detail: String) {
        line(passed ? "PASS" : "FAIL", "\(name)\(detail.isEmpty ? "" : " — \(detail)")")
    }

    private static func skip(_ name: String, _ reason: String) {
        line("SKIP", "\(name) — \(reason)")
    }

    private static func line(_ tag: String, _ text: String) {
        print("SELFTEST \(tag) \(text)")
        fflush(stdout)
    }
}
