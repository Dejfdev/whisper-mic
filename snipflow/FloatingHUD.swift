import SwiftUI
import AppKit

enum HUDState {
    case message(String)
    case loading(String)
    case error(String)
}

// 1. Standalone HUD Notification Window
class HUDWindowController: NSWindowController {
    static let shared = HUDWindowController()
    
    private var hudWindow: NSWindow?
    
    class HUDViewModel: ObservableObject {
        @Published var state: HUDState = .message("")
    }
    private var viewModel = HUDViewModel()
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        window.hasShadow = true
        
        let hostingView = NSHostingView(rootView: HUDView(viewModel: viewModel))
        window.contentView = hostingView
        
        super.init(window: window)
        self.hudWindow = window
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(state: HUDState) {
        DispatchQueue.main.async {
            self.viewModel.state = state
            
            guard let window = self.hudWindow else { return }
            
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let windowRect = window.frame
                let newX = screenRect.origin.x + (screenRect.width - windowRect.width) / 2
                let newY = screenRect.origin.y + (screenRect.height - windowRect.height) / 4
                window.setFrameOrigin(NSPoint(x: newX, y: newY))
            }
            
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().alphaValue = 1.0
            }
        }
    }
    
    func hide(delay: TimeInterval = 0.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let window = self.hudWindow, window.isVisible else { return }
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                window.orderOut(nil)
            })
        }
    }
}

// 2. Interactive Menu Window (Appears near the mouse cursor post-capture)
class InteractiveMenuWindowController: NSWindowController {
    static let shared = InteractiveMenuWindowController()
    
    private var menuWindow: NSWindow?
    private var onSelectAction: ((String) -> Void)?
    
    class MenuViewModel: ObservableObject {
        @Published var image: NSImage?
    }
    private var viewModel = MenuViewModel()
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar // Sit on top of menus and panels
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = true
        
        super.init(window: window)
        self.menuWindow = window
        
        let hostingView = NSHostingView(rootView: InteractiveMenuView(viewModel: viewModel) { [weak self] action in
            self?.selectAction(action)
        })
        window.contentView = hostingView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(image: NSImage, position: NSPoint, onSelect: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            self.viewModel.image = image
            self.onSelectAction = onSelect
            
            guard let window = self.menuWindow else { return }
            
            // Adjust position relative to the cursor
            let newX = position.x - window.frame.width / 2
            let newY = position.y - window.frame.height / 2
            window.setFrameOrigin(NSPoint(x: newX, y: newY))
            
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            
            // Make app active so click registers immediately
            NSApp.activate(ignoringOtherApps: true)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().alphaValue = 1.0
            }
        }
    }
    
    private func selectAction(_ action: String) {
        onSelectAction?(action)
        hide()
    }
    
    func hide() {
        DispatchQueue.main.async {
            guard let window = self.menuWindow, window.isVisible else { return }
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                window.orderOut(nil)
            })
        }
    }
}

// SwiftUI Frosted Glass Background View
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// SwiftUI HUD Notification View
struct HUDView: View {
    @ObservedObject var viewModel: HUDWindowController.HUDViewModel
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(18)
            
            VStack(spacing: 12) {
                switch viewModel.state {
                case .message(let text):
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text(text)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        
                case .loading(let text):
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.1)
                    Text(text)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        
                case .error(let text):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                    Text(text)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .frame(width: 240, height: 120)
    }
}

// SwiftUI Interactive Quick Action Menu View
struct InteractiveMenuView: View {
    @ObservedObject var viewModel: InteractiveMenuWindowController.MenuViewModel
    let onSelect: (String) -> Void
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(18)
            
            HStack(spacing: 12) {
                // Mini preview of the crop
                if let img = viewModel.image {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 54, height: 54)
                        .cornerRadius(8)
                        .clipped()
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snip Captured")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Select quick action:")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 6) {
                    ActionButton(icon: "doc.on.doc.fill", label: "Copy", color: .blue) {
                        onSelect("copy")
                    }
                    
                    ActionButton(icon: "text.viewfinder", label: "OCR", color: .green) {
                        onSelect("ocr")
                    }
                    
                    ActionButton(icon: "pin.fill", label: "Pin", color: .orange) {
                        onSelect("sticker")
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 340, height: 80)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(width: 50, height: 48)
            .background(isHovered ? color.opacity(0.7) : Color.white.opacity(0.12))
            .cornerRadius(10)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            isHovered = hover
        }
    }
}

// 3. Capture Mode Overlay Bar (Windows 11 Snipping Tool Style)
class CaptureBarWindowController: NSWindowController {
    static let shared = CaptureBarWindowController()
    
    private var barWindow: NSWindow?
    private var onSelectMode: ((String) -> Void)?
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 50),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = true
        
        super.init(window: window)
        self.barWindow = window
        
        let hostingView = NSHostingView(rootView: CaptureBarView { [weak self] mode in
            self?.selectMode(mode)
        })
        window.contentView = hostingView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(onSelect: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            self.onSelectMode = onSelect
            
            guard let window = self.barWindow else { return }
            
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let windowRect = window.frame
                let newX = screenRect.origin.x + (screenRect.width - windowRect.width) / 2
                // Position 20pt below the menu bar
                let newY = screenRect.origin.y + screenRect.height - windowRect.height - 20
                window.setFrameOrigin(NSPoint(x: newX, y: newY))
            }
            
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().alphaValue = 1.0
            }
        }
    }
    
    private func selectMode(_ mode: String) {
        onSelectMode?(mode)
        hide()
    }
    
    func hide() {
        DispatchQueue.main.async {
            guard let window = self.barWindow, window.isVisible else { return }
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                window.orderOut(nil)
            })
        }
    }
}

struct CaptureBarView: View {
    let onSelect: (String) -> Void
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            HStack(spacing: 8) {
                BarButton(icon: "square.dashed", tooltip: "Rectangular Snip") {
                    onSelect("rectangular")
                }
                
                BarButton(icon: "macwindow", tooltip: "Window Snip") {
                    onSelect("window")
                }
                
                BarButton(icon: "display", tooltip: "Fullscreen Snip") {
                    onSelect("fullscreen")
                }
                
                Divider()
                    .frame(height: 18)
                    .background(Color.white.opacity(0.2))
                
                BarButton(icon: "xmark", tooltip: "Close", isDestructive: true) {
                    onSelect("close")
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(width: 220, height: 50)
    }
}

struct BarButton: View {
    let icon: String
    let tooltip: String
    var isDestructive = false
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isHovered ? (isDestructive ? .red : .blue) : .white)
                .frame(width: 34, height: 34)
                .background(isHovered ? Color.white.opacity(0.15) : Color.clear)
                .cornerRadius(8)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
        .onHover { hover in
            isHovered = hover
        }
    }
}

