import Cocoa

class CaptureManager: NSObject {
    static let shared = CaptureManager()
    
    // Hold reference to open sticker controllers so they don't get garbage collected
    private var stickerControllers: [StickerWindowController] = []
    
    override init() {
        super.init()
    }
    
    func showCaptureBar(defaultAction: String) {
        CaptureBarWindowController.shared.show { [weak self] mode in
            guard let self = self else { return }
            if mode == "close" {
                return
            }
            
            // Run screen capture on global queue
            DispatchQueue.global(qos: .userInitiated).async {
                self.startCapture(mode: mode, defaultAction: defaultAction)
            }
        }
    }
    
    private func startCapture(mode: String, defaultAction: String) {
        // Resolve path to ~/Pictures/Screenshots
        guard let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else {
            print("Failed to find Pictures directory.")
            return
        }
        let screenshotsURL = picturesURL.appendingPathComponent("Screenshots")
        
        // Ensure folder exists
        do {
            try FileManager.default.createDirectory(at: screenshotsURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create Screenshots folder: \(error)")
            return
        }
        
        // Generate timestamped file name
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let dateString = formatter.string(from: Date())
        let fileURL = screenshotsURL.appendingPathComponent("Screenshot \(dateString).png")
        
        // Spawn asynchronous system screencapture utility
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        
        switch mode {
        case "rectangular":
            task.arguments = ["-i", "-s", fileURL.path] // Forces selection mode only
        case "window":
            task.arguments = ["-i", "-w", fileURL.path] // Forces window selection mode only
        case "fullscreen":
            // Fullscreen captures immediately. Delay slightly so overlay window can fade out completely
            Thread.sleep(forTimeInterval: 0.25)
            task.arguments = [fileURL.path]
        default:
            return
        }
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // If file was successfully created, capture succeeded
            if FileManager.default.fileExists(atPath: fileURL.path),
               let image = NSImage(contentsOf: fileURL) {
                
                // Copy captured image to clipboard
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.writeObjects([image])
                
                let mousePos = NSEvent.mouseLocation
                
                DispatchQueue.main.async {
                    self.handleCapturedImage(image, action: defaultAction, position: mousePos)
                }
            }
        } catch {
            print("Failed to run screencapture: \(error)")
        }
    }
    
    func handleCapturedImage(_ image: NSImage, action: String, position: NSPoint) {
        switch action {
        case "copy":
            // Image is already in pasteboard, just show confirmation
            HUDWindowController.shared.show(state: .message("Saved & Copied"))
            HUDWindowController.shared.hide(delay: 1.5)
            
        case "ocr":
            HUDWindowController.shared.show(state: .loading("Recognizing Text..."))
            OCRManager.performOCR(on: image) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(text, forType: .string)
                        HUDWindowController.shared.show(state: .message("Text Copied to Clipboard"))
                        HUDWindowController.shared.hide(delay: 2.0)
                    case .failure(let error):
                        HUDWindowController.shared.show(state: .error(error.localizedDescription))
                        HUDWindowController.shared.hide(delay: 3.5)
                    }
                }
            }
            
        case "sticker":
            let controller = StickerWindowController(image: image, position: position)
            self.addSticker(controller)
            HUDWindowController.shared.show(state: .message("Sticker Pinned"))
            HUDWindowController.shared.hide(delay: 1.2)
            
        case "menu":
            // Present interactive quick action overlay
            InteractiveMenuWindowController.shared.show(image: image, position: position) { selectedAction in
                self.handleCapturedImage(image, action: selectedAction, position: position)
            }
            
        default:
            break
        }
    }
    
    private func addSticker(_ controller: StickerWindowController) {
        stickerControllers.append(controller)
        
        // Listen to window close notifications to release the controllers
        if let window = controller.window {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(stickerWindowClosed(_:)),
                name: NSWindow.willCloseNotification,
                object: window
            )
        }
    }
    
    @objc private func stickerWindowClosed(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            stickerControllers.removeAll { $0.window == window }
            // Remove observer
            NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        }
    }
}
