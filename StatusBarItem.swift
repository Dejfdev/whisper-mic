import Cocoa

class StatusBarItemManager: NSObject {
    static let shared = StatusBarItemManager()
    
    private var statusItem: NSStatusItem!
    private var flashTimer: Timer?
    private var isFlashOn = false
    
    var onRecordToggle: (() -> Void)?
    var onOpenPreferences: (() -> Void)?
    
    override init() {
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenu()
        setIdleState()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        let recordItem = NSMenuItem(title: "Start Dictation", action: #selector(toggleRecord), keyEquivalent: "")
        recordItem.target = self
        menu.addItem(recordItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit WhisperMic", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    func setIdleState() {
        stopFlashing()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "WhisperMic")
            button.image?.isTemplate = true
        }
        statusItem.menu?.items.first?.title = "Start Dictation"
    }
    
    func setRecordingState() {
        statusItem.menu?.items.first?.title = "Stop Dictation"
        startFlashing()
    }
    
    func setTranscribingState() {
        stopFlashing()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.doc.on.clipboard", accessibilityDescription: "Transcribing")
            button.image?.isTemplate = true
        }
        statusItem.menu?.items.first?.title = "Transcribing..."
    }
    
    @objc private func toggleRecord() {
        onRecordToggle?()
    }
    
    @objc private func openPreferences() {
        onOpenPreferences?()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func startFlashing() {
        stopFlashing()
        isFlashOn = false
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            guard let self = self, let button = self.statusItem.button else { return }
            self.isFlashOn.toggle()
            if self.isFlashOn {
                button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Recording Active")
                button.image?.isTemplate = true
            } else {
                button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Recording")
                button.image?.isTemplate = true
            }
        }
    }
    
    private func stopFlashing() {
        flashTimer?.invalidate()
        flashTimer = nil
    }
}
