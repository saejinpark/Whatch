# ⌚️ Whatch

Whatch is a playful and experimental Apple Watch app packed with unusual and fun features.  
It was originally created out of curiosity and is now shared as an open-source project.

---

## 🧪 Features

- **Accelerometer**  
  Measures motion and acceleration.

- **Roll Tracker X**  
  Tracks horizontal wrist rotation (x-axis).

- **Roll Tracker Y**  
  Tracks vertical wrist rotation (y-axis).

- **Vibration Detector**  
  Detects shaking or sudden movement.

- **Watch Board**  
  Draw with the Digital Crown.

- **Ping Test**  
  Measures ping between iPhone and Apple Watch.

- **Flashlight Control**  
  Turn your iPhone flashlight on/off from the Watch.

- **Haptic Controller**  
  Start or stop vibration from the Watch with press or toggle modes.

- **Heading Monitor**  
  Compare Watch heading and iPhone heading in real-time.

- **Battery Status**  
  Displays battery levels of both devices.

---

## 🏗 Project Structure

The Xcode project has two targets that share one folder of code:

- `Shared/` — compiled into both apps.
  - `Connectivity/` — `ConnectivitySession` (the single `WCSession` owner), the typed `WatchMessage` enum and `PingMonitor`.
  - `Features/` — the `Feature` list, status models and the monitors that run on both devices (battery, heading).
  - `UI/` — `LockUp`, `StatusButton`, `FeaturePicker` and other reusable views.
- `Whatch/` — iPhone app. `AppModel` wires the services together; `FlashlightController` and `HapticController` act on Watch requests.
- `Whatch Watch App/` — Watch app. `AppModel` plus the Watch-only features (accelerometer, rotation tracker, vibration detector, Watch Board) and `RemoteSwitch`, which mirrors a phone-side toggle.

State is modelled with `@Observable` classes and injected through the SwiftUI environment; messages between the devices are always a `WatchMessage` case, never a raw dictionary.

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

