import Carbon
import Cocoa

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var localModifierMonitor: Any?
    private var globalModifierMonitor: Any?
    
    // Double tap Option state
    private var lastOptionTapTime: Date?
    private var optionTapCount = 0
    
    var onTrigger: (() -> Void)?
    
    init() {}
    
    enum ShortcutType: String, CaseIterable, Identifiable {
        case optionSpace = "Option + Space"
        case controlSpace = "Control + Space"
        case cmdShiftD = "Cmd + Shift + D"
        case doubleTapOption = "Double-Tap Option"
        
        var id: String { self.rawValue }
    }
    
    func setupShortcut(_ type: ShortcutType) {
        // Reset all
        unregisterAll()
        
        switch type {
        case .optionSpace:
            // Space code: 49, Option modifier: optionKey (2048)
            let optionModifier = UInt32(optionKey)
            registerCarbonHotkey(keyCode: 49, modifiers: optionModifier)
            
        case .controlSpace:
            // Space code: 49, Control modifier: controlKey (4096)
            let controlModifier = UInt32(controlKey)
            registerCarbonHotkey(keyCode: 49, modifiers: controlModifier)
            
        case .cmdShiftD:
            // D code: 2, Cmd (256) + Shift (512) modifiers
            let cmdShiftModifiers = UInt32(cmdKey | shiftKey)
            registerCarbonHotkey(keyCode: 2, modifiers: cmdShiftModifiers)
            
        case .doubleTapOption:
            registerDoubleTapModifier()
        }
    }
    
    private func registerCarbonHotkey(keyCode: UInt32, modifiers: UInt32) {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)
        
        let handlerUPP: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr && hotKeyID.signature == OSType(13245) {
                DispatchQueue.main.async {
                    GlobalHotkeyManager.shared.onTrigger?()
                }
            }
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerUPP,
            1,
            &eventType,
            nil,
            nil
        )
        
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.signature = OSType(13245)
        gMyHotKeyID.id = UInt32(1)
        
        var ref: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        
        if registerStatus == noErr {
            self.hotKeyRef = ref
        } else {
            print("Failed to register Carbon HotKey: \(registerStatus)")
        }
    }
    
    private func registerDoubleTapModifier() {
        let eventHandler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Check for Option key alone
            if flags == .option {
                let now = Date()
                if let last = self.lastOptionTapTime, now.timeIntervalSince(last) < 0.35 {
                    self.optionTapCount += 1
                } else {
                    self.optionTapCount = 1
                }
                self.lastOptionTapTime = now
                
                if self.optionTapCount == 2 {
                    self.optionTapCount = 0
                    DispatchQueue.main.async {
                        self.onTrigger?()
                    }
                }
            } else if flags.isEmpty {
                // Flag key released, normal flow
            } else {
                // Other modifiers pressed, reset count
                self.optionTapCount = 0
            }
        }
        
        globalModifierMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: eventHandler)
        localModifierMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            eventHandler(event)
            return event
        }
    }
    
    private func unregisterAll() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        
        if let monitor = globalModifierMonitor {
            NSEvent.removeMonitor(monitor)
            globalModifierMonitor = nil
        }
        
        if let monitor = localModifierMonitor {
            NSEvent.removeMonitor(monitor)
            localModifierMonitor = nil
        }
        
        optionTapCount = 0
        lastOptionTapTime = nil
    }
}
