import Cocoa
import SwiftUI

class StickerWindowController: NSWindowController, NSWindowDelegate {
    private var stickerWindow: NSWindow?
    
    init(image: NSImage, position: NSPoint) {
        // Calculate initial sticker size, capping dimensions at 500px to prevent screen clutter
        let maxDimension: CGFloat = 500
        var width = image.size.width
        var height = image.size.height
        
        if width > maxDimension || height > maxDimension {
            let ratio = width / height
            if ratio > 1 {
                width = maxDimension
                height = maxDimension / ratio
            } else {
                height = maxDimension
                width = maxDimension * ratio
            }
        }
        
        // Define a borderless, resizable window
        let window = NSWindow(
            contentRect: NSRect(x: position.x - width/2, y: position.y - height/2, width: width, height: height),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        // Float on all spaces (even full-screen workspaces)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        // Guarantee aspect-ratio constraint during resize
        window.contentAspectRatio = NSSize(width: width, height: height)
        
        let hostingView = NSHostingView(rootView: StickerView(image: image, onClose: { [weak window] in
            window?.close()
        }))
        window.contentView = hostingView
        
        super.init(window: window)
        self.stickerWindow = window
        window.delegate = self
        
        window.makeKeyAndOrderFront(nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func windowWillClose(_ notification: Notification) {
        // Clear references
        stickerWindow = nil
    }
}

struct StickerView: View {
    let image: NSImage
    let onClose: () -> Void
    @State private var isHovering = false
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(opacity)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                )
            
            // Hover controls
            if isHovering {
                HStack(spacing: 8) {
                    // Transparency slider
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 11))
                    
                    Slider(value: $opacity, in: 0.15...1.0)
                        .frame(width: 60)
                        .controlSize(.small)
                    
                    Divider()
                        .frame(height: 12)
                    
                    // Close button
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).cornerRadius(16))
                .transition(.opacity)
                .padding(8)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        // Double-click shortcut to close the sticker quickly
        .gesture(
            TapGesture(count: 2).onEnded {
                onClose()
            }
        )
    }
}

// Simple visual effect wrapper for SwiftUI (matching FloatingHUD's helper)
#if !DEBUG
struct VisualEffectViewHelper: NSViewRepresentable {
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
#endif
