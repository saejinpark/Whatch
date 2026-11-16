# ⌚️ Whatch

Whatch is a playful and experimental Apple Watch app packed with unusual and fun features.  
It was originally created out of curiosity and is now shared as an open-source project.

---

## 🧪 Features

**On the Watch alone**

- **Accelerometer** — a ring gauge of the current G-force, with your best swing and swing count.
- **Rotation Tracker** — adds up how far you turn your wrist, around either axis.
- **Vibration Detector** — a live trace of how much your wrist is shaking.
- **Watch Board** — a pixel canvas you draw on with a finger or steer with the Digital Crown.

**Remote control**

- **Flashlight** — switch the iPhone torch from the Watch and set its brightness with the Digital Crown.
- **Haptic Controller** — start and stop the iPhone vibration from the Watch.
- **Buzz the Watch** — send taps and Morse code from the iPhone to the Watch's Taptic Engine.
- **Watch Board Mirroring** — see the Watch drawing live on the iPhone, then save or share it.

**Play**

- **Ball Game** — tilt your wrist to roll a ball on the iPhone onto the target.
- **Air Pointer** — point your arm to move a pointer on the iPhone; hold the pad on the Watch to draw.
- **Reaction Duel** — one player per device; first to tap after "go" wins.

**Measure**

- **Ping Test** — round-trip time between the two apps, with a history chart.
- **Heading Monitor** — a compass showing where the other device points.
- **Battery** — both battery levels side by side.
- **Distance Radar** — distance between the devices with ultra-wideband (iPhone 11 and Apple Watch Series 6 or later). It also measures a length held between the two, and estimates height from arm span; both wait for the devices to hold still and are good to about 10 cm.
- **Heart Rate Relay** — the Watch's live heart rate on the iPhone's big screen. Nothing is saved to Health.
- **Height Difference** — compares the two barometers to tell how much higher one device is.

Opening a feature on one device opens its partner screen on the other. The torch and the vibration motor
only work while the iPhone app is on screen (an iOS rule), and anything sent from the iPhone needs the Watch
app in front. When something cannot work, the app says why instead of failing silently.

---

## 🏗 Project Structure

Two app targets share one folder of code:

- `Shared/Core/` — pure logic with no UI or device access: the message format, ping bookkeeping, rotation and impact maths, the board, compass arithmetic. Unit-tested.
- `Shared/Connectivity/` — `ConnectivitySession`, the single owner of `WCSession`, and `PingMonitor`.
- `Shared/Services/` — battery and compass monitors.
- `Shared/App/` — `AppModel`, which keeps the two devices in sync, and the on-device `SelfTest`.
- `Shared/Design/`, `Shared/Features/` — the design system and the screens both apps use.
- `Whatch/` — iPhone app: dashboard, torch and haptic controllers.
- `Whatch Watch App/` — Watch app: feature list and the Watch-only screens.

Each device broadcasts a `DeviceState` snapshot when it changes and stores it for the other to find later, so
a screen can show the last known value even when the other app is closed. High-rate data (the compass) is only
streamed while the other device has the heading screen open. The same goes for wrist motion, the Watch Board and
pressure: each is a stream the other device subscribes to, sent one message at a time and only when the previous
one was acknowledged, so a slow link gets fewer, fresher messages instead of a growing queue.

---

## ✅ Testing

Unit tests for `Shared/Core` run on a Mac, without a simulator:

```bash
swift test
```

Hardware and the live connection are checked by a self-test built into both apps. Launch either app with
`-selfTest` and it prints one `SELFTEST PASS/FAIL/SKIP` line per check (battery, compass, connection, ping,
state exchange, torch, haptics, motion sensors):

```bash
xcrun devicectl device process launch --console --device <device id> -- dev.pinocchio.Whatch -selfTest
```

Launching with `-openFeature <id>` (for example `-openFeature ping`) opens that feature directly.

---

## 🔐 Privacy & Contact

This app does **not collect, store, or transmit any personal data**.  
It only exchanges heading, flashlight, battery, and vibration data between your own devices for the purpose of real-time testing.

For feedback, bug reports, or privacy-related requests (including data removal if any), please contact:

📧 590824@naver.com  
📞 +82 10-6208-0784

---

## 💼 License

This project is open-source and distributed under the **MIT License**.  
You are free to use, modify, and share it, but please credit the original creator.

---

