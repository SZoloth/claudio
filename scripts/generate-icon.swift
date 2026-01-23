#!/usr/bin/env swift

import Cocoa
import CoreGraphics

// Icon design: Rounded square with gradient, speech bubble with waveform
func generateIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background rounded rect with gradient
    let cornerRadius = size * 0.22
    let path = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                            xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient: Orange to deep orange (matching app theme)
    let gradient = NSGradient(colors: [
        NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0),  // Bright orange
        NSColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0)   // Deep orange
    ])!
    gradient.draw(in: path, angle: -45)

    // Subtle shadow/depth
    context.saveGState()
    let shadowPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04),
                                   xRadius: cornerRadius * 0.9, yRadius: cornerRadius * 0.9)
    NSColor(white: 0, alpha: 0.1).setFill()
    shadowPath.fill()
    context.restoreGState()

    // Inner content area
    let innerRect = rect.insetBy(dx: size * 0.15, dy: size * 0.15)

    // Speech bubble shape
    let bubbleRect = CGRect(x: innerRect.minX,
                            y: innerRect.minY + size * 0.1,
                            width: innerRect.width,
                            height: innerRect.height * 0.75)

    let bubblePath = NSBezierPath(roundedRect: bubbleRect,
                                   xRadius: size * 0.12, yRadius: size * 0.12)

    // Bubble tail
    let tailPath = NSBezierPath()
    tailPath.move(to: NSPoint(x: bubbleRect.minX + size * 0.15, y: bubbleRect.minY))
    tailPath.line(to: NSPoint(x: bubbleRect.minX + size * 0.08, y: bubbleRect.minY - size * 0.1))
    tailPath.line(to: NSPoint(x: bubbleRect.minX + size * 0.25, y: bubbleRect.minY))
    tailPath.close()

    // Draw bubble with white fill
    NSColor.white.setFill()
    bubblePath.fill()
    tailPath.fill()

    // Draw waveform inside bubble
    let waveformY = bubbleRect.midY
    let waveformStartX = bubbleRect.minX + size * 0.08
    let waveformWidth = bubbleRect.width - size * 0.16
    let barWidth = size * 0.04
    let barSpacing = size * 0.06
    let barCount = 5

    // Waveform bar heights (relative to max height)
    let heights: [CGFloat] = [0.3, 0.7, 1.0, 0.6, 0.4]
    let maxHeight = bubbleRect.height * 0.5

    NSColor(red: 0.9, green: 0.45, blue: 0.15, alpha: 1.0).setFill()  // Orange bars

    for i in 0..<barCount {
        let x = waveformStartX + CGFloat(i) * (barWidth + barSpacing) + (waveformWidth - CGFloat(barCount) * (barWidth + barSpacing) + barSpacing) / 2
        let height = maxHeight * heights[i]
        let barRect = CGRect(x: x, y: waveformY - height / 2, width: barWidth, height: height)
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
        barPath.fill()
    }

    image.unlockFocus()
    return image
}

func saveIcon(_ image: NSImage, to path: String, size: Int) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for size \(size)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Created: \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

// Generate all required sizes
let outputDir = "Claudio/Assets.xcassets/AppIcon.appiconset"
let sizes: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

print("Generating Claudio app icons...")

for (name, size) in sizes {
    let icon = generateIcon(size: CGFloat(size))
    let path = "\(outputDir)/\(name)"
    saveIcon(icon, to: path, size: size)
}

print("Done!")
