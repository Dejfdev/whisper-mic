import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @AppStorage("transcriptionLanguage") private var transcriptionLanguage: String = "auto"
    @AppStorage("customPrompt") private var customPrompt: String = ""
    @AppStorage("shortcutType") private var shortcutType: String = GlobalHotkeyManager.ShortcutType.optionSpace.rawValue
    
    // Testing state
    @State private var isTestingConnection = false
    @State private var testResult: Result<Void, Error>? = nil
    
    // Accessibility state
    @State private var hasAccessibilityAccess = AXIsProcessTrusted()
    
    // Languages list
    let languages = [
        ("Auto-Detect", "auto"),
        ("English", "en"),
        ("Polish", "pl"),
        ("German", "de"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("Italian", "it"),
        ("Portuguese", "pt"),
        ("Ukrainian", "uk")
    ]
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Integration").font(.headline)) {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 380)
                
                HStack(spacing: 12) {
                    Button("Save Key") {
                        saveApiKey()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: testConnection) {
                        if isTestingConnection {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        } else {
                            Text("Test Connection")
                        }
                    }
                    .disabled(apiKey.isEmpty || isTestingConnection)
                    
                    if let result = testResult {
                        switch result {
                        case .success:
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Connection valid!")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        case .failure(let error):
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: 200, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(.top, 4)
                
                Text("Your API key is stored securely in the macOS Keychain.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section(header: Text("Dictation Settings").font(.headline)) {
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
                
                Picker("Transcription Language", selection: $transcriptionLanguage) {
                    ForEach(languages, id: \.1) { name, code in
                        Text(name).tag(code)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom Prompt (Optional)")
                        .font(.body)
                    
                    TextEditor(text: $customPrompt)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 70)
                        .border(Color.secondary.opacity(0.2), width: 1)
                    
                    Text("Guide Whisper on spelling names, adding punctuation, or using tech words (e.g., 'API, Python, Xcode').")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Section(header: Text("System Permissions").font(.headline)) {
                HStack(spacing: 12) {
                    Image(systemName: hasAccessibilityAccess ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title)
                        .foregroundColor(hasAccessibilityAccess ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasAccessibilityAccess ? "Accessibility permission is granted." : "Accessibility permission is required.")
                            .fontWeight(.medium)
                        
                        Text("WhisperMic uses Accessibility APIs to paste transcribed text directly into the active field of other apps.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: 350, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
                
                HStack(spacing: 12) {
                    if !hasAccessibilityAccess {
                        Button("Grant Access") {
                            requestAccessibilityAccess()
                        }
                    }
                    
                    Button("Check Again") {
                        checkAccessibilityAccess()
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 480, height: 480)
        .onAppear {
            apiKey = KeychainHelper.load() ?? ""
            checkAccessibilityAccess()
        }
    }
    
    private func saveApiKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if KeychainHelper.save(key: trimmed) {
            testResult = .success(())
        } else {
            testResult = .failure(NSError(domain: "KeychainError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save key in Keychain."]))
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        OpenAIClient().testConnection(apiKey: trimmed) { result in
            DispatchQueue.main.async {
                self.isTestingConnection = false
                self.testResult = result
                if case .success = result {
                    // Auto-save key if connection test passes
                    KeychainHelper.save(key: trimmed)
                }
            }
        }
    }
    
    private func checkAccessibilityAccess() {
        hasAccessibilityAccess = AXIsProcessTrusted()
    }
    
    private func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Guide user to the preference pane directly
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
