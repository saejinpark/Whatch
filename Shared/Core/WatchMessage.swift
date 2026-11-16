//
//  WatchMessage.swift
//  Whatch
//

import Foundation

/// A snapshot of one device, sent to the other so both screens agree.
struct DeviceState: Equatable, Sendable {
    /// Battery level in `0...1`, or `nil` when unknown.
    var batteryLevel: Double?
    var isCharging = false
    var isFlashlightOn = false
    var isHapticOn = false
    /// iPhone torch brightness in `0.1...1`.
    var flashlightBrightness = 1.0
    /// Whether the app is on screen. The iPhone torch and haptics need this.
    var isForeground = false
    /// When the snapshot was taken, in seconds since 1970.
    var timestamp: TimeInterval = 0
    /// The iPhone's calibration for estimating height from arm span, in metres. `nil` until someone calibrates.
    var armSpanOffset: Double?

    private enum Key {
        static let battery = "battery"
        static let charging = "charging"
        static let flashlight = "flashlight"
        static let haptic = "haptic"
        static let brightness = "brightness"
        static let foreground = "foreground"
        static let timestamp = "timestamp"
        static let armSpan = "armSpan"
    }

    init(
        batteryLevel: Double? = nil,
        isCharging: Bool = false,
        isFlashlightOn: Bool = false,
        isHapticOn: Bool = false,
        flashlightBrightness: Double = 1,
        isForeground: Bool = false,
        timestamp: TimeInterval = 0,
        armSpanOffset: Double? = nil
    ) {
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.isFlashlightOn = isFlashlightOn
        self.isHapticOn = isHapticOn
        self.flashlightBrightness = flashlightBrightness
        self.isForeground = isForeground
        self.timestamp = timestamp
        self.armSpanOffset = armSpanOffset
    }

    var payload: [String: Any] {
        var payload: [String: Any] = [
            Key.charging: isCharging,
            Key.flashlight: isFlashlightOn,
            Key.haptic: isHapticOn,
            Key.brightness: flashlightBrightness,
            Key.foreground: isForeground,
            Key.timestamp: timestamp,
        ]
        if let batteryLevel {
            payload[Key.battery] = batteryLevel
        }
        if let armSpanOffset {
            payload[Key.armSpan] = armSpanOffset
        }
        return payload
    }

    init?(payload: [String: Any]) {
        guard let timestamp = payload[Key.timestamp] as? NSNumber else { return nil }
        self.timestamp = timestamp.doubleValue
        batteryLevel = (payload[Key.battery] as? NSNumber)?.doubleValue
        isCharging = (payload[Key.charging] as? NSNumber)?.boolValue ?? false
        isFlashlightOn = (payload[Key.flashlight] as? NSNumber)?.boolValue ?? false
        isHapticOn = (payload[Key.haptic] as? NSNumber)?.boolValue ?? false
        flashlightBrightness = (payload[Key.brightness] as? NSNumber)?.doubleValue ?? 1
        isForeground = (payload[Key.foreground] as? NSNumber)?.boolValue ?? false
        armSpanOffset = (payload[Key.armSpan] as? NSNumber)?.doubleValue
    }
}

/// Data one device streams to the other only while it is asked to.
enum LiveStream: String, CaseIterable, Sendable {
    /// Watch → iPhone: the Watch Board, whenever it changes.
    case board
    /// Watch → iPhone: wrist motion for games and the air pointer.
    case motion
    /// Both ways: barometric pressure for the height difference.
    case pressure
}

/// How the wrist is held, sent from the Watch while the iPhone uses it as a controller.
struct ControllerSample: Equatable, Sendable {
    /// Gravity along the Watch screen's x and y axes, in G. Zero when the Watch lies flat.
    var tiltX = 0.0
    var tiltY = 0.0
    /// Rotation around the vertical axis and around the forearm's cross axis, in degrees.
    var yaw = 0.0
    var roll = 0.0
    /// Whether the button on the Watch's controller screen is held down.
    var isPressed = false

    var payload: [Double] {
        [tiltX, tiltY, yaw, roll, isPressed ? 1 : 0]
    }

    init(tiltX: Double = 0, tiltY: Double = 0, yaw: Double = 0, roll: Double = 0, isPressed: Bool = false) {
        self.tiltX = tiltX
        self.tiltY = tiltY
        self.yaw = yaw
        self.roll = roll
        self.isPressed = isPressed
    }

    init?(payload: Any?) {
        guard let numbers = payload as? [NSNumber], numbers.count == 5 else { return nil }
        tiltX = numbers[0].doubleValue
        tiltY = numbers[1].doubleValue
        yaw = numbers[2].doubleValue
        roll = numbers[3].doubleValue
        isPressed = numbers[4].doubleValue > 0.5
    }
}

/// Every message exchanged between the iPhone and Watch apps.
///
/// WatchConnectivity only carries property-list values, so each case is encoded as a
/// small dictionary (`kind` + optional `value`) and decoded back on the other side.
enum WatchMessage: Equatable, Sendable {
    /// Round-trip probe. The receiver answers with `.pong` carrying the same timestamp.
    case ping(sentAt: TimeInterval)
    case pong(sentAt: TimeInterval)
    /// Watch → iPhone: turn the torch on or off. Answered with `.state`.
    case setFlashlight(isOn: Bool)
    /// Watch → iPhone: start or stop the vibration. Answered with `.state`.
    case setHaptic(isOn: Bool)
    /// Asks the receiver to start or stop streaming `.heading`. Sent when the heading
    /// screen opens and closes, so the link is not flooded when nobody is looking.
    case headingSubscription(isOn: Bool)
    /// Sender's compass heading in degrees, streamed while the receiver is subscribed.
    case heading(Double)
    /// Sender's current state.
    case state(DeviceState)
    /// Asks the receiver to answer with `.state`.
    case stateRequest
    /// Asks the receiver to start or stop a `LiveStream`.
    case subscribe(LiveStream, isOn: Bool)
    /// Asks the receiver to show a feature's screen, because the sender needs its help.
    case open(Feature)
    /// Watch → iPhone: set the torch brightness (`0.1...1`). Answered with `.state`.
    case setFlashlightBrightness(Double)
    /// Watch → iPhone: the Watch Board in `Board.data` form.
    case board(Data)
    /// iPhone → Watch: play this pattern of `.`, `-`, space and `/` as taps.
    case buzz(String)
    /// Watch → iPhone: the latest controller reading.
    case controller(ControllerSample)
    /// Starts a reaction duel round: show "go" `delay` seconds after receiving this.
    case duelStart(round: Int, delay: TimeInterval)
    /// The sender's reaction time for a round, or `ReactionDuel.falseStart`.
    case duelResult(round: Int, milliseconds: Int)
    /// A Nearby Interaction discovery token; answer with `.rangingAnswer` if ranging here too.
    case rangingOffer(Data)
    case rangingAnswer(Data)
    /// Watch → iPhone: heart rate in beats per minute, or zero when the broadcast stops.
    case heartRate(Double)
    /// Sender's barometric pressure in kPa.
    case pressure(Double)

    private enum Kind: String {
        case ping, pong, setFlashlight, setHaptic, headingSubscription, heading, state, stateRequest
        case subscribe, open, setFlashlightBrightness, board, buzz, controller
        case duelStart, duelResult, rangingOffer, rangingAnswer, heartRate, pressure
    }

    private enum Key {
        static let kind = "kind"
        static let value = "value"
    }

    var payload: [String: Any] {
        switch self {
        case .ping(let sentAt): encode(.ping, sentAt)
        case .pong(let sentAt): encode(.pong, sentAt)
        case .setFlashlight(let isOn): encode(.setFlashlight, isOn)
        case .setHaptic(let isOn): encode(.setHaptic, isOn)
        case .headingSubscription(let isOn): encode(.headingSubscription, isOn)
        case .heading(let degrees): encode(.heading, degrees)
        case .state(let state): encode(.state, state.payload)
        case .stateRequest: encode(.stateRequest, nil)
        case .subscribe(let stream, let isOn): encode(.subscribe, ["stream": stream.rawValue, "on": isOn])
        case .open(let feature): encode(.open, feature.rawValue)
        case .setFlashlightBrightness(let value): encode(.setFlashlightBrightness, value)
        case .board(let data): encode(.board, data)
        case .buzz(let pattern): encode(.buzz, pattern)
        case .controller(let sample): encode(.controller, sample.payload)
        case .duelStart(let round, let delay): encode(.duelStart, ["round": round, "delay": delay])
        case .duelResult(let round, let milliseconds): encode(.duelResult, ["round": round, "ms": milliseconds])
        case .rangingOffer(let token): encode(.rangingOffer, token)
        case .rangingAnswer(let token): encode(.rangingAnswer, token)
        case .heartRate(let bpm): encode(.heartRate, bpm)
        case .pressure(let kPa): encode(.pressure, kPa)
        }
    }

    init?(payload: [String: Any]) {
        guard let rawKind = payload[Key.kind] as? String,
              let kind = Kind(rawValue: rawKind) else { return nil }
        let value = payload[Key.value]
        let number = value as? NSNumber

        switch kind {
        case .ping:
            guard let number else { return nil }
            self = .ping(sentAt: number.doubleValue)
        case .pong:
            guard let number else { return nil }
            self = .pong(sentAt: number.doubleValue)
        case .setFlashlight:
            guard let number else { return nil }
            self = .setFlashlight(isOn: number.boolValue)
        case .setHaptic:
            guard let number else { return nil }
            self = .setHaptic(isOn: number.boolValue)
        case .headingSubscription:
            guard let number else { return nil }
            self = .headingSubscription(isOn: number.boolValue)
        case .heading:
            guard let number else { return nil }
            self = .heading(number.doubleValue)
        case .state:
            guard let dictionary = value as? [String: Any],
                  let state = DeviceState(payload: dictionary) else { return nil }
            self = .state(state)
        case .stateRequest:
            self = .stateRequest
        case .subscribe:
            guard let dictionary = value as? [String: Any],
                  let stream = (dictionary["stream"] as? String).flatMap(LiveStream.init(rawValue:)),
                  let isOn = dictionary["on"] as? NSNumber else { return nil }
            self = .subscribe(stream, isOn: isOn.boolValue)
        case .open:
            guard let feature = (value as? String).flatMap(Feature.init(rawValue:)) else { return nil }
            self = .open(feature)
        case .setFlashlightBrightness:
            guard let number else { return nil }
            self = .setFlashlightBrightness(number.doubleValue)
        case .board:
            guard let data = value as? Data else { return nil }
            self = .board(data)
        case .buzz:
            guard let pattern = value as? String else { return nil }
            self = .buzz(pattern)
        case .controller:
            guard let sample = ControllerSample(payload: value) else { return nil }
            self = .controller(sample)
        case .duelStart:
            guard let dictionary = value as? [String: Any],
                  let round = dictionary["round"] as? NSNumber,
                  let delay = dictionary["delay"] as? NSNumber else { return nil }
            self = .duelStart(round: round.intValue, delay: delay.doubleValue)
        case .duelResult:
            guard let dictionary = value as? [String: Any],
                  let round = dictionary["round"] as? NSNumber,
                  let milliseconds = dictionary["ms"] as? NSNumber else { return nil }
            self = .duelResult(round: round.intValue, milliseconds: milliseconds.intValue)
        case .rangingOffer:
            guard let token = value as? Data else { return nil }
            self = .rangingOffer(token)
        case .rangingAnswer:
            guard let token = value as? Data else { return nil }
            self = .rangingAnswer(token)
        case .heartRate:
            guard let number else { return nil }
            self = .heartRate(number.doubleValue)
        case .pressure:
            guard let number else { return nil }
            self = .pressure(number.doubleValue)
        }
    }

    private func encode(_ kind: Kind, _ value: Any?) -> [String: Any] {
        var payload: [String: Any] = [Key.kind: kind.rawValue]
        if let value {
            payload[Key.value] = value
        }
        return payload
    }
}
