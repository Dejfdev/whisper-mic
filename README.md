# WhisperMic & SnipFlow

A suite of lightweight, native macOS productivity utilities built in Swift and SwiftUI with zero external dependencies.

This repository contains two main tools:
1. **WhisperMic**: A keyboard-driven global dictation tool that transcribes your speech using OpenAI's Whisper API and automatically pastes it into any active text field. A completely free, open-source alternative to paid utilities.
2. **SnipFlow**: A screenshot overlay utility inspired by the Windows 11 Snipping Tool. Supports Rectangular, Window, and Fullscreen captures, extracts text locally using offline OCR, pins floating resizable reference stickers on screen, and auto-saves to `Pictures/Screenshots`.

---

## Features

### 🎙️ WhisperMic
* **Global Hotkey Activation**: Press `Option + Space` (configurable) to start recording from anywhere.
* **Animated HUD**: Displays a translucent, glassmorphic floating HUD overlay showing real-time recording waveforms and timers.
* **Optimized Audio**: Records mono, 16kHz audio in compressed AAC (`.m4a`) format to minimize API upload latency.
* **Secure Storage**: Your OpenAI API Key is stored safely in the native macOS System Keychain.
* **Universal Paste Injection**: Simulates keystroke pasting (`Cmd + V`) to automatically insert transcribed text into any application without requiring complex accessibility setups.

### ✂️ SnipFlow
* **Windows-Style Selection Bar**: Press `Option + Shift + S` to show an overlay bar at the top-center of the screen with Rectangular, Window, and Fullscreen capture options.
* **Native Selection Integration**: Utilizes macOS's built-in crop and camera capture interfaces.
* **Local Offline OCR**: Extracts text from any screenshot instantly using Apple's native **Vision Framework** (no internet connection required).
* **Floating Stickers (Snip & Pin)**: Keep screenshots floating on top of your work. Supports dragging, aspect-ratio-locked resizing, and transparency adjustments.
* **Auto-Save**: Saves every capture automatically as a timestamped PNG in `~/Pictures/Screenshots/`.

---

## Installation & Build

Both applications are compiled natively from source using standard macOS Command Line Tools.

### Prerequisites
* macOS 14.0 (Sonoma) or newer.
* Xcode Command Line Tools installed (run `xcode-select --install` in Terminal if missing).
* A valid OpenAI API Key (only required for WhisperMic).

### Building WhisperMic
1. Open Terminal in the root folder.
2. Run the build script:
   ```bash
   ./build.sh
   ```
3. Open the generated **`WhisperMic.app`** application bundle.

### Building SnipFlow
1. Open Terminal in the `snipflow` subdirectory.
2. Run the build script:
   ```bash
   cd snipflow
   ./build.sh
   ```
3. Open the generated **`SnipFlow.app`** application bundle.

---

## Configuration & Permissions

### WhisperMic Setup
1. On first launch, the **Preferences** panel will open.
2. Enter your OpenAI API Key and click **Save Key** (you can click **Test Connection** to verify).
3. To enable the paste feature, click **Grant Access** to open System Settings, and check the box next to **WhisperMic** under **Privacy & Security -> Accessibility**.

### SnipFlow Setup
1. Press `Option + Shift + S` to start your first capture.
2. macOS will prompt you to grant **Screen Recording** permissions.
3. Open System Settings and enable the switch next to **SnipFlow** under **Privacy & Security -> Screen & System Audio Recording**.

---

## License

This project is open-source. Feel free to use, modify, and distribute it.
