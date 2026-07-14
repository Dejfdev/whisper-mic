import Cocoa

// Guard that we got an argument specifying which icon to build
guard CommandLine.arguments.count > 1 else {
    print("Usage: swift generate_icons.swift [whisper|snipflow] [output_directory]")
    exit(1)
}

let mode = CommandLine.arguments[1]
let outputDir = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "."
let isWhisper = (mode == "whisper")

func drawBaseImage() -> NSImage {
    let size = NSSize(width: 512, height: 512)
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // Draw background squircle. Leaving 40px inset for margins and system drop-shadows
    let rect = NSRect(x: 40, y: 40, width: 432, height: 432)
    let path = NSBezierPath(roundedRect: rect, xRadius: 96, yRadius: 96)
    
    NSGraphicsContext.current?.saveGraphicsState()
    path.addClip()
    
    // Setup modern gradient background
    let color1: NSColor
    let color2: NSColor
    if isWhisper {
        // Red to Violet gradient for dictation
        color1 = NSColor(red: 0.88, green: 0.15, blue: 0.35, alpha: 1.0)
        color2 = NSColor(red: 0.32, green: 0.08, blue: 0.58, alpha: 1.0)
    } else {
        // Cyan to Deep Teal gradient for screen crop
        color1 = NSColor(red: 0.08, green: 0.72, blue: 0.82, alpha: 1.0)
        color2 = NSColor(red: 0.04, green: 0.28, blue: 0.48, alpha: 1.0)
    }
    
    let gradient = NSGradient(starting: color1, ending: color2)!
    gradient.draw(in: rect, angle: -45)
    NSGraphicsContext.current?.restoreGraphicsState()
    
    // Draw glyph in white
    NSColor.white.set()
    
    if isWhisper {
        // 1. Microphone Capsule
        let micRect = NSRect(x: 226, y: 200, width: 60, height: 130)
        let micPath = NSBezierPath(roundedRect: micRect, xRadius: 30, yRadius: 30)
        micPath.fill()
        
        // 2. Microphone Ring Bracket
        let ringPath = NSBezierPath()
        ringPath.lineWidth = 14
        ringPath.lineCapStyle = .round
        ringPath.appendArc(withCenter: NSPoint(x: 256, y: 215), radius: 64, startAngle: 180, endAngle: 360)
        ringPath.stroke()
        
        // 3. Microphone Stand Base
        let baseLine = NSBezierPath()
        baseLine.lineWidth = 14
        baseLine.lineCapStyle = .round
        baseLine.move(to: NSPoint(x: 256, y: 151))
        baseLine.line(to: NSPoint(x: 256, y: 105))
        baseLine.move(to: NSPoint(x: 206, y: 105))
        baseLine.line(to: NSPoint(x: 306, y: 105))
        baseLine.stroke()
        
        // 4. Stylized Waveform arches
        let wavePath = NSBezierPath()
        wavePath.lineWidth = 10
        wavePath.lineCapStyle = .round
        // Left wave
        wavePath.appendArc(withCenter: NSPoint(x: 256, y: 265), radius: 105, startAngle: 155, endAngle: 205)
        // Right wave
        wavePath.appendArc(withCenter: NSPoint(x: 256, y: 265), radius: 105, startAngle: 335, endAngle: 25)
        wavePath.stroke()
    } else {
        // 1. Outer Crop corners (Viewfinder)
        let cropPath = NSBezierPath()
        cropPath.lineWidth = 20
        cropPath.lineCapStyle = .round
        cropPath.lineJoinStyle = .round
        
        let size: CGFloat = 80
        let inset: CGFloat = 135
        let minX: CGFloat = inset
        let maxX: CGFloat = 512 - inset
        let minY: CGFloat = inset
        let maxY: CGFloat = 512 - inset
        
        // Top Left corner
        cropPath.move(to: NSPoint(x: minX, y: maxY - size))
        cropPath.line(to: NSPoint(x: minX, y: maxY))
        cropPath.line(to: NSPoint(x: minX + size, y: maxY))
        
        // Top Right corner
        cropPath.move(to: NSPoint(x: maxX - size, y: maxY))
        cropPath.line(to: NSPoint(x: maxX, y: maxY))
        cropPath.line(to: NSPoint(x: maxX, y: maxY - size))
        
        // Bottom Right corner
        cropPath.move(to: NSPoint(x: maxX, y: minY + size))
        cropPath.line(to: NSPoint(x: maxX, y: minY))
        cropPath.line(to: NSPoint(x: maxX - size, y: minY))
        
        // Bottom Left corner
        cropPath.move(to: NSPoint(x: minX + size, y: minY))
        cropPath.line(to: NSPoint(x: minX, y: minY))
        cropPath.line(to: NSPoint(x: minX, y: minY + size))
        
        cropPath.stroke()
        
        // 2. Viewfinder central lens ring
        let lensOuter = NSBezierPath(ovalIn: NSRect(x: 216, y: 216, width: 80, height: 80))
        lensOuter.lineWidth = 10
        lensOuter.stroke()
        
        let lensInner = NSBezierPath(ovalIn: NSRect(x: 236, y: 236, width: 40, height: 40))
        lensInner.fill()
        
        // 3. Status recording dot (top right)
        let dot = NSBezierPath(ovalIn: NSRect(x: 350, y: 350, width: 24, height: 24))
        NSColor(red: 0.95, green: 0.2, blue: 0.2, alpha: 1.0).set()
        dot.fill()
    }
    
    image.unlockFocus()
    return image
}

// Resizes NSImage to standard scale sizes and saves as PNG
func resizeAndSave(image: NSImage, size: NSSize, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    rep.size = size
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    
    image.draw(in: NSRect(origin: .zero, size: size),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy,
               fraction: 1.0)
    
    NSGraphicsContext.restoreGraphicsState()
    
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: url)
    }
}

// Execute Generation
let baseImage = drawBaseImage()
let fileManager = FileManager.default

let iconsetDir = URL(fileURLWithPath: outputDir).appendingPathComponent("AppIcon.iconset")
try? fileManager.removeItem(at: iconsetDir)
try? fileManager.createDirectory(at: iconsetDir, withIntermediateDirectories: true, attributes: nil)

// Array of all required size/multiplier tuples
let sizes: [(CGFloat, String)] = [
    (16, "16x16"),
    (32, "16x16@2x"),
    (32, "32x32"),
    (64, "32x32@2x"),
    (128, "128x128"),
    (256, "128x128@2x"),
    (256, "256x256"),
    (512, "256x256@2x"),
    (512, "512x512"),
    (1024, "512x512@2x")
]

for (pixels, suffix) in sizes {
    let destURL = iconsetDir.appendingPathComponent("icon_\(suffix).png")
    resizeAndSave(image: baseImage, size: NSSize(width: pixels, height: pixels), to: destURL)
}

print("Iconset created at: \(iconsetDir.path)")
