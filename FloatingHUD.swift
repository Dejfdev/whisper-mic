import SwiftUI
import AppKit

enum HUDState {
    case recording(duration: TimeInterval)
    case transcribing
    case pasting
    case success
    case error(message: String)
}

class HUDWindowController: NSWindowController {
    static let shared = HUDWindowController()
    
    private var hudWindow: NSWindow?
    private var stateBinding: Binding<HUDState>?
    
    // Published state container
    class HUDViewModel: ObservableObject {
        @Published var state: HUDState = .recording(duration: 0)
    }
    
    private var viewModel = HUDViewModel()
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 180),
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
            
            // Center the window on the main screen
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let windowRect = window.frame
                let newX = screenRect.origin.x + (screenRect.width - windowRect.width) / 2
                let newY = screenRect.origin.y + (screenRect.height - windowRect.height) / 4 // Slightly lower than center
                window.setFrameOrigin(NSPoint(x: newX, y: newY))
            }
            
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                window.animator().alphaValue = 1.0
            }
        }
    }
    
    func hide(delay: TimeInterval = 0.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let window = self.hudWindow, window.isVisible else { return }
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                window.orderOut(nil)
            })
        }
    }
}

// SwiftUI Frosted Glass Background
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

// SwiftUI Content View
struct HUDView: View {
    @ObservedObject var viewModel: HUDWindowController.HUDViewModel
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(24)
            
            VStack(spacing: 16) {
                switch viewModel.state {
                case .recording(let duration):
                    VStack(spacing: 12) {
                        AnimatedWaveformView()
                        
                        Text(formatDuration(duration))
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Recording...")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                case .transcribing:
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.3)
                        
                        Text("Transcribing...")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                case .pasting:
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Pasting...")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                case .success:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.green)
                        
                        Text("Done")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                case .error(let message):
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(message)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .lineLimit(2)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 280, height: 180)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Animated Microphone Waves View
struct AnimatedWaveformView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(0..<7) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.red)
                    .frame(
                        width: 5,
                        height: isAnimating ? CGFloat.random(in: 20...50) : 12
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 0.2...0.45))
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .frame(height: 60)
        .onAppear {
            isAnimating = true
        }
    }
}
