import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultAction") private var defaultAction: String = "menu"
    @AppStorage("shortcutType") private var shortcutType: String = GlobalHotkeyManager.ShortcutType.optionShiftS.rawValue
    
    let actions = [
        ("Show Quick Menu", "menu"),
        ("Extract Text (OCR)", "ocr"),
        ("Pin as Sticker", "sticker"),
        ("Copy Image to Clipboard", "copy")
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Capture Trigger").font(.headline)) {
                Picker("Global Shortcut", selection: $shortcutType) {
                    ForEach(GlobalHotkeyManager.ShortcutType.allCases) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .onChange(of: shortcutType) { _, newValue in
                    if let type = GlobalHotkeyManager.ShortcutType(rawValue: newValue) {
                        GlobalHotkeyManager.shared.setupShortcut(type)
                    }
                }
                
                Text("Press this shortcut from anywhere to select a screen region.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section(header: Text("Post-Capture Action").font(.headline)) {
                Picker("Action after snip", selection: $defaultAction) {
                    ForEach(actions, id: \.1) { name, code in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Group {
                        if defaultAction == "menu" {
                            Text("Displays a sleek action overlay right at your cursor, letting you choose to Copy, Extract Text (OCR), or Pin.")
                        } else if defaultAction == "ocr" {
                            Text("Performs high-accuracy text recognition in the background and copies text to your clipboard.")
                        } else if defaultAction == "sticker" {
                            Text("Pins the screenshot as a borderless window floating on top of all applications and workspaces.")
                        } else {
                            Text("Copies the cropped image to the clipboard, ready to paste in chats, mails, or editors.")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 32, alignment: .topLeading)
                }
                .padding(.top, 4)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section(header: Text("Permissions").font(.headline)) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Capture Privileges")
                            .fontWeight(.medium)
                        Text("SnipFlow uses macOS screen capture APIs. System prompt will trigger on your first capture.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 440, height: 380)
    }
}
