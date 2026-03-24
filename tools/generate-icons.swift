#!/usr/bin/env swift
//
// generate-icons.swift
// Run from repo root: swift tools/generate-icons.swift
//
// Renders AppIconView at each required iOS icon size and saves PNG files
// into daily/Assets.xcassets/AppIcon.appiconset/.
//
// Requirements: macOS 13+ (Ventura), Xcode command-line tools installed.
//

import Foundation
import SwiftUI
import AppKit

// MARK: - Icon Design (mirrors AppIconView.swift)

struct AppIconView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.55, blue: 0.0),
                    Color(red: 0.9, green: 0.3, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .scaleEffect(0.85)

            Image(systemName: "figure.run")
                .font(.system(size: 420, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                .offset(x: 20)
        }
    }
}

// MARK: - Export

let sizes: [(Int, String)] = [
    (1024, "AppIcon-1024.png"),
    (180,  "AppIcon-180.png"),
    (120,  "AppIcon-120.png"),
    (87,   "AppIcon-87.png"),
    (80,   "AppIcon-80.png"),
    (58,   "AppIcon-58.png")
]

let outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("daily/Assets.xcassets/AppIcon.appiconset")

@MainActor
func generateIcons() {
    for (size, filename) in sizes {
        let cgSize = CGFloat(size)
        let renderer = ImageRenderer(content: AppIconView().frame(width: cgSize, height: cgSize))
        renderer.scale = 1.0

        guard let nsImage = renderer.nsImage else {
            print("❌ Failed to render \(filename)")
            continue
        }

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ Failed to encode \(filename)")
            continue
        }

        let outputURL = outputDir.appendingPathComponent(filename)
        do {
            try pngData.write(to: outputURL)
            print("✅ Saved \(filename) (\(size)×\(size)px)")
        } catch {
            print("❌ Error saving \(filename): \(error)")
        }
    }
    print("\nDone. Run ⌘B in Xcode to verify no icon warnings.")
}

// Run on main actor
Task { @MainActor in
    generateIcons()
    exit(0)
}

RunLoop.main.run()
