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

**With the iPhone**

- **Ping Test** — round-trip time between the two apps, with a history chart.
- **Flashlight** — switch the iPhone torch from the Watch; brightness and hold/toggle on the phone.
- **Haptic Controller** — start and stop the iPhone vibration from the Watch.
- **Heading Monitor** — a compass showing where the other device points.
- **Battery** — both battery levels side by side.

The torch and the vibration motor only work while the iPhone app is on screen (an iOS rule).
When something cannot work, the app says why instead of failing silently.

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
streamed while the other device has the heading screen open.

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

