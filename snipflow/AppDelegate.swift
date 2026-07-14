import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindow: NSWindow?
    private var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBar()
        
        // Bind hotkey trigger
        GlobalHotkeyManager.shared.onTrigger = { [weak self] in
            self?.triggerCapture()
        }
        
        // Initialize hotkey from configurations
        let savedShortcut = UserDefaults.standard.string(forKey: "shortcutType") ?? GlobalHotkeyManager.ShortcutType.optionShiftS.rawValue
        if let type = GlobalHotkeyManager.ShortcutType(rawValue: savedShortcut) {
            GlobalHotkeyManager.shared.setupShortcut(type)
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "viewfinder.circle.fill", accessibilityDescription: "SnipFlow")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        let captureItem = NSMenuItem(title: "Capture Area", action: #selector(menuTriggerCapture), keyEquivalent: "")
        captureItem.target = self
        menu.addItem(captureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit SnipFlow", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func menuTriggerCapture() {
        triggerCapture()
    }
    
    private func triggerCapture() {
        let action = UserDefaults.standard.string(forKey: "defaultAction") ?? "menu"
        CaptureManager.shared.showCaptureBar(defaultAction: action)
    }
    
    @objc private func openPreferences() {
        openPreferencesWindow()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    func openPreferencesWindow() {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnipFlow Preferences"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
