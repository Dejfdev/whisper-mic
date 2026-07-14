# WhisperMic

A lightweight, native macOS global dictation tool built in Swift and SwiftUI with zero external dependencies.

WhisperMic allows you to record audio from your microphone using a global keyboard shortcut, transcribe it using OpenAI's Whisper API, and automatically paste the transcription into any active text field. It serves as a free, open-source, and privacy-friendly alternative to paid dictation utilities.

---

## Features
* **Global Hotkey Activation**: Press `Option + Space` (configurable) to start recording from anywhere.
* **Animated HUD**: Displays a translucent, glassmorphic floating HUD overlay showing real-time recording waveforms and timers.
* **Optimized Audio**: Records mono, 16kHz audio in compressed AAC (`.m4a`) format to minimize API upload latency.
* **Secure Storage**: Your OpenAI API Key is stored safely in the native macOS System Keychain.
* **Universal Paste Injection**: Simulates keystroke pasting (`Cmd + V`) to automatically insert transcribed text into any application without requiring complex accessibility setups.

---

## Installation & Build

WhisperMic is compiled natively from source using standard macOS Command Line Tools.

### Prerequisites
* macOS 14.0 (Sonoma) or newer.
* Xcode Command Line Tools installed (run `xcode-select --install` in Terminal if missing).
* A valid OpenAI API Key.

### Building WhisperMic
1. Open Terminal in the root folder.
2. Run the build script:
   ```bash
   ./build.sh
   ```
3. Open the generated **`WhisperMic.app`** application bundle.

---

## Configuration & Permissions
1. On first launch, the **Preferences** panel will open automatically.
2. Enter your OpenAI API Key and click **Save Key** (you can click **Test Connection** to verify).
3. To enable the paste feature, click **Grant Access** to open System Settings, and check the box next to **WhisperMic** under **Privacy & Security -> Accessibility**.

---

## License

This project is open-source. Feel free to use, modify, and distribute it.
