import Carbon
import Cocoa

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    var onTrigger: (() -> Void)?
    
    init() {}
    
    enum ShortcutType: String, CaseIterable, Identifiable {
        case optionShiftS = "Option + Shift + S"
        case controlShiftS = "Control + Shift + S"
        case cmdShiftS = "Cmd + Shift + S"
        
        var id: String { self.rawValue }
    }
    
    func setupShortcut(_ type: ShortcutType) {
        unregisterAll()
        
        switch type {
        case .optionShiftS:
            // S code: 1, Modifiers: Option (2048) + Shift (512)
            let modifiers = UInt32(optionKey | shiftKey)
            registerCarbonHotkey(keyCode: 1, modifiers: modifiers)
            
        case .controlShiftS:
            // S code: 1, Modifiers: Control (4096) + Shift (512)
            let modifiers = UInt32(controlKey | shiftKey)
            registerCarbonHotkey(keyCode: 1, modifiers: modifiers)
            
        case .cmdShiftS:
            // S code: 1, Modifiers: Cmd (256) + Shift (512)
            let modifiers = UInt32(cmdKey | shiftKey)
            registerCarbonHotkey(keyCode: 1, modifiers: modifiers)
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
            
            if status == noErr && hotKeyID.signature == OSType(54321) {
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
        gMyHotKeyID.signature = OSType(54321)
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
            print("Failed to register SnipFlow HotKey: \(registerStatus)")
        }
    }
    
    private func unregisterAll() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
