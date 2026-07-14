import Cocoa
import SwiftUI
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindow: NSWindow?
    private let recorder = AudioRecorder()
    private let apiWriter = OpenAIClient()
    
    // Recording timer state
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set up menu item callbacks
        StatusBarItemManager.shared.onRecordToggle = { [weak self] in
            self?.toggleDictation()
        }
        StatusBarItemManager.shared.onOpenPreferences = { [weak self] in
            self?.openPreferencesWindow()
        }
        
        // Set up hotkey trigger callback
        GlobalHotkeyManager.shared.onTrigger = { [weak self] in
            self?.toggleDictation()
        }
        
        // Initialize the hotkey from UserDefaults (default: Option + Space)
        let savedShortcut = UserDefaults.standard.string(forKey: "shortcutType") ?? GlobalHotkeyManager.ShortcutType.optionSpace.rawValue
        if let type = GlobalHotkeyManager.ShortcutType(rawValue: savedShortcut) {
            GlobalHotkeyManager.shared.setupShortcut(type)
        }
        
        // Show preferences window on launch if API key is missing to assist setup
        if KeychainHelper.load() == nil {
            openPreferencesWindow()
        }
    }
    
    func toggleDictation() {
        if recorder.isRecording {
            stopDictation()
        } else {
            startDictation()
        }
    }
    
    private func startDictation() {
        // 1. Verify API Key exists
        guard let _ = KeychainHelper.load() else {
            NSSound.beep()
            HUDWindowController.shared.show(state: .error(message: "Add OpenAI API Key in Preferences."))
            HUDWindowController.shared.hide(delay: 3.5)
            openPreferencesWindow()
            return
        }
        
        // 2. Verify Microphone Permission
        recorder.checkPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                // Play standard start sound
                NSSound(named: "Pop")?.play()
                
                // Start physical recording
                if self.recorder.startRecording() {
                    // Update menu bar status
                    StatusBarItemManager.shared.setRecordingState()
                    
                    // Show recording HUD and trigger timer
                    self.recordingDuration = 0
                    HUDWindowController.shared.show(state: .recording(duration: 0))
                    self.startTimer()
                } else {
                    HUDWindowController.shared.show(state: .error(message: "Failed to access microphone."))
                    HUDWindowController.shared.hide(delay: 3.0)
                }
            } else {
                NSSound.beep()
                HUDWindowController.shared.show(state: .error(message: "Microphone permission denied."))
                HUDWindowController.shared.hide(delay: 4.0)
            }
        }
    }
    
    private func stopDictation() {
        stopTimer()
        
        // Play standard stop sound
        NSSound(named: "Purr")?.play()
        
        // Update statuses
        StatusBarItemManager.shared.setTranscribingState()
        HUDWindowController.shared.show(state: .transcribing)
        
        guard let fileURL = recorder.stopRecording() else {
            handleError(message: "Recording file not found.")
            return
        }
        
        // Read active transcription configurations
        let language = UserDefaults.standard.string(forKey: "transcriptionLanguage")
        let prompt = UserDefaults.standard.string(forKey: "customPrompt")
        
        // Perform transcription API request
        apiWriter.transcribe(fileURL: fileURL, language: language, prompt: prompt) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let text):
                let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanedText.isEmpty {
                    self.handleError(message: "No speech detected.")
                } else {
                    self.handleSuccess(text: cleanedText)
                }
            case .failure(let error):
                self.handleError(message: error.localizedDescription)
            }
        }
    }
    
    private func handleSuccess(text: String) {
        DispatchQueue.main.async {
            HUDWindowController.shared.show(state: .pasting)
            self.pasteText(text)
            
            StatusBarItemManager.shared.setIdleState()
            HUDWindowController.shared.show(state: .success)
            HUDWindowController.shared.hide(delay: 1.0)
        }
    }
    
    private func handleError(message: String) {
        DispatchQueue.main.async {
            NSSound.beep()
            StatusBarItemManager.shared.setIdleState()
            HUDWindowController.shared.show(state: .error(message: message))
            HUDWindowController.shared.hide(delay: 4.0)
        }
    }
    
    // Timer controls
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 1.0
            HUDWindowController.shared.show(state: .recording(duration: self.recordingDuration))
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // Clipboard simulation method to paste text universally
    private func pasteText(_ text: String) {
        let pb = NSPasteboard.general
        
        // Backup existing clipboard content
        var backupItems: [NSPasteboardItem] = []
        if let pasteboardItems = pb.pasteboardItems {
            for item in pasteboardItems {
                let backupItem = NSPasteboardItem()
                for type in item.types {
                    if let data = item.data(forType: type) {
                        backupItem.setData(data, forType: type)
                    }
                }
                backupItems.append(backupItem)
            }
        }
        
        // Write new text to clipboard
        pb.clearContents()
        pb.setString(text, forType: .string)
        
        // Post key events (Cmd + V)
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 'v' Virtual Keycode is 9
        guard let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) else { return }
        vKeyDown.flags = .maskCommand
        
        guard let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
        vKeyUp.flags = .maskCommand
        
        vKeyDown.post(tap: .cgSessionEventTap)
        vKeyUp.post(tap: .cgSessionEventTap)
        
        // Restore previous clipboard state after a delay allowing target app to register paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let pbRestore = NSPasteboard.general
            pbRestore.clearContents()
            if !backupItems.isEmpty {
                pbRestore.writeObjects(backupItems)
            }
        }
    }
    
    // Preferences Window Controller
    func openPreferencesWindow() {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WhisperMic Preferences"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        
        preferencesWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
