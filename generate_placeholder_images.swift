#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO

#if canImport(AppKit)
import AppKit
#endif

// Script to generate placeholder images for DocC tutorials
// Run with: swift generate_placeholder_images.swift

let resourcesPath = "Sources/OpenAIKit/OpenAIKit.docc/Resources"

// List of all images needed for tutorials
let images = [
    // General
    "openaikit-hero.png",
    "chapter1-hero.png",
    "chapter2-hero.png",
    "chapter3-hero.png",
    
    // Tutorial 1
    "setup-intro.png",
    "spm-install.png",
    "setup-step2.png",
    "api-key-section.png",
    "openai-platform.png",
    "api-keys-nav.png",
    "create-key.png",
    "copy-key.png",
    "configure-intro.png",
    "env-vars.png",
    "edit-scheme.png",
    "scheme-arguments.png",
    "add-env-var.png",
    
    // Tutorial 2
    "first-chat-intro.png",
    "chat-request.png",
    "message-roles.png",
    "parameters.png",
    "chat-interface.png",
    
    // Tutorial 3
    "functions-intro.png",
    "function-flow.png",
    "weather-api.png",
    "function-execution.png",
    "weather-assistant-ui.png",
    "advanced-functions.png",
    
    // Tutorial 4
    "error-handling-intro.png",
    "error-types.png",
    "retry-logic.png",
    "user-errors.png",
    "error-handler.png",
    
    // Tutorial 5
    "conversations-intro.png",
    "context-management.png",
    "conversation-memory.png",
    "personas.png",
    "advanced-patterns.png",
    "complete-chatbot.png",
    
    // Tutorial 6
    "streaming-intro.png",
    "streaming-flow.png",
    "streaming-ui.png",
    "stream-errors.png",
    "advanced-streaming.png",
    "cross-platform.png",
    
    // Tutorial 7
    "image-generation-intro.png",
    "dalle-basic.png",
    "image-options.png",
    "image-ui.png",
    "image-variations.png",
    "prompt-engineering.png",
    
    // Tutorial 8
    "audio-transcription-intro.png",
    "whisper-basics.png",
    "transcription-options.png",
    "audio-translation.png",
    "voice-notes-app.png",
    "large-audio.png",
    
    // Tutorial 9
    "semantic-search-intro.png",
    "embeddings-explained.png",
    "vector-similarity.png",
    "vector-database.png",
    "search-engine.png",
    "knowledge-base-app.png",
    "advanced-embeddings.png"
]

#if canImport(AppKit)
func createPlaceholderImage(width: Int, height: Int, text: String) -> NSImage? {
    let image = NSImage(size: NSSize(width: width, height: height))
    
    image.lockFocus()
    
    // Background
    NSColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Text
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 36, weight: .medium),
        .foregroundColor: NSColor.white
    ]
    
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    let textSize = attributedString.size()
    let textRect = NSRect(
        x: (CGFloat(width) - textSize.width) / 2,
        y: (CGFloat(height) - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )
    
    attributedString.draw(in: textRect)
    
    image.unlockFocus()
    
    return image
}

func saveImage(_ image: NSImage, to path: String) throws {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PNG data"])
    }
    
    try pngData.write(to: URL(fileURLWithPath: path))
}

// Create resources directory if needed
try FileManager.default.createDirectory(atPath: resourcesPath, withIntermediateDirectories: true)

// Generate placeholder images
for imageName in images {
    let isHero = imageName.contains("hero")
    let width = isHero ? 1920 : 1280
    let height = isHero ? 1080 : 720
    
    let displayName = imageName
        .replacingOccurrences(of: ".png", with: "")
        .replacingOccurrences(of: "-", with: " ")
        .capitalized
    
    if let image = createPlaceholderImage(width: width, height: height, text: displayName) {
        let path = "\(resourcesPath)/\(imageName)"
        do {
            try saveImage(image, to: path)
            print("✅ Created: \(imageName)")
        } catch {
            print("❌ Failed to save \(imageName): \(error)")
        }
    }
}

print("\nPlaceholder images generated successfully!")
print("These are temporary placeholders - replace with actual screenshots and diagrams.")

#else
print("This script requires AppKit (macOS) to generate images.")
print("On Linux, you'll need to create the placeholder images manually or use a different tool.")
#endif