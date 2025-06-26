// AdvancedFeatures.swift
import Foundation
import OpenAIKit

extension AdvancedImageGenerator {
    
    /// Generate images in specific formats with optimization
    func generateInFormat(
        prompt: String,
        format: OutputFormat,
        optimization: FormatOptimization = .balanced
    ) async throws -> FormattedImageResult {
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: Models.Images.gptImage1,
            outputCompression: optimization.compressionForFormat(format),
            outputFormat: format.rawValue,
            quality: optimization.quality,
            responseFormat: .b64Json,
            size: format.recommendedSize
        )
        
        let response = try await openAI.images.generations(request)
        
        guard let imageData = response.data.first,
              let base64 = imageData.b64Json else {
            throw AdvancedImageError.generationFailed
        }
        
        // Analyze format characteristics
        let characteristics = try analyzeImageFormat(base64: base64, format: format)
        
        return FormattedImageResult(
            base64Data: base64,
            format: format,
            characteristics: characteristics,
            usage: response.usage
        )
    }
    
    /// Supported output formats with characteristics
    enum OutputFormat: String, CaseIterable {
        case png = "png"
        case jpeg = "jpeg"
        case webp = "webp"
        
        var features: FormatFeatures {
            switch self {
            case .png:
                return FormatFeatures(
                    supportsTransparency: true,
                    compressionType: .lossless,
                    bestFor: ["Icons", "Logos", "Screenshots", "Text-heavy images"],
                    colorDepth: 24,
                    maxColors: 16_777_216,
                    typicalCompression: "10-30%"
                )
            case .jpeg:
                return FormatFeatures(
                    supportsTransparency: false,
                    compressionType: .lossy,
                    bestFor: ["Photographs", "Complex scenes", "Web images"],
                    colorDepth: 24,
                    maxColors: 16_777_216,
                    typicalCompression: "80-95%"
                )
            case .webp:
                return FormatFeatures(
                    supportsTransparency: true,
                    compressionType: .both,
                    bestFor: ["Web optimization", "Modern browsers", "Mixed content"],
                    colorDepth: 24,
                    maxColors: 16_777_216,
                    typicalCompression: "25-35% better than JPEG/PNG"
                )
            }
        }
        
        var recommendedSize: String {
            switch self {
            case .png: return "2048x2048"  // Lossless benefits from higher res
            case .jpeg: return "1024x1024" // Good balance for photos
            case .webp: return "1024x1024" // Efficient at any size
            }
        }
    }
    
    /// Format optimization strategies
    enum FormatOptimization {
        case fileSize      // Minimize file size
        case quality       // Maximize quality
        case balanced      // Balance size and quality
        case webOptimized  // Optimize for web delivery
        
        var quality: String {
            switch self {
            case .fileSize: return "standard"
            case .quality: return "hd"
            case .balanced, .webOptimized: return "hd"
            }
        }
        
        func compressionForFormat(_ format: OutputFormat) -> Int {
            switch (self, format) {
            case (.fileSize, .jpeg): return 75
            case (.fileSize, .webp): return 80
            case (.fileSize, .png): return 100  // PNG uses lossless
            
            case (.quality, .jpeg): return 95
            case (.quality, .webp): return 95
            case (.quality, .png): return 100
            
            case (.balanced, .jpeg): return 85
            case (.balanced, .webp): return 90
            case (.balanced, .png): return 100
            
            case (.webOptimized, .jpeg): return 80
            case (.webOptimized, .webp): return 85
            case (.webOptimized, .png): return 100
            }
        }
    }
    
    /// Analyze image format characteristics
    private func analyzeImageFormat(
        base64: String,
        format: OutputFormat
    ) throws -> FormatCharacteristics {
        
        guard let data = Data(base64Encoded: base64) else {
            throw AdvancedImageError.invalidImageData
        }
        
        let sizeKB = data.count / 1024
        let hasAlpha = try detectAlphaChannel(data: data, format: format)
        let colorProfile = try detectColorProfile(data: data)
        
        return FormatCharacteristics(
            actualFormat: format,
            fileSizeKB: sizeKB,
            hasAlphaChannel: hasAlpha,
            colorProfile: colorProfile,
            estimatedColors: estimateColorCount(data: data),
            metadata: extractMetadata(data: data)
        )
    }
    
    /// Convert between formats with optimization
    func convertFormat(
        base64Image: String,
        from currentFormat: OutputFormat,
        to targetFormat: OutputFormat,
        optimization: FormatOptimization = .balanced
    ) async throws -> FormattedImageResult {
        
        guard let imageData = Data(base64Encoded: base64Image) else {
            throw AdvancedImageError.invalidImageData
        }
        
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData) else {
            throw AdvancedImageError.invalidImageData
        }
        
        let convertedData: Data?
        
        switch targetFormat {
        case .png:
            convertedData = image.pngData()
            
        case .jpeg:
            let quality = CGFloat(optimization.compressionForFormat(.jpeg)) / 100.0
            convertedData = image.jpegData(compressionQuality: quality)
            
        case .webp:
            // WebP conversion would require additional libraries
            // For this example, we'll return the original
            convertedData = imageData
        }
        
        guard let finalData = convertedData else {
            throw AdvancedImageError.conversionFailed
        }
        
        let base64Result = finalData.base64EncodedString()
        let characteristics = try analyzeImageFormat(
            base64: base64Result,
            format: targetFormat
        )
        
        return FormattedImageResult(
            base64Data: base64Result,
            format: targetFormat,
            characteristics: characteristics,
            usage: nil
        )
        #else
        throw AdvancedImageError.conversionNotSupported
        #endif
    }
    
    /// Detect if image has alpha channel
    private func detectAlphaChannel(data: Data, format: OutputFormat) throws -> Bool {
        switch format {
        case .png:
            // Check PNG color type for alpha
            return try verifyTransparency(base64Data: data.base64EncodedString())
        case .jpeg:
            return false // JPEG doesn't support alpha
        case .webp:
            // WebP alpha detection would require parsing VP8L/VP8X chunks
            return false // Simplified for example
        }
    }
    
    /// Detect color profile
    private func detectColorProfile(data: Data) throws -> String {
        // Simplified detection - in production, parse image metadata
        if data.count > 1000 {
            return "sRGB" // Most common
        }
        return "Unknown"
    }
    
    /// Estimate number of unique colors
    private func estimateColorCount(data: Data) -> Int {
        // Simplified estimation based on file size and format
        // In production, would sample pixels
        let sizeKB = data.count / 1024
        if sizeKB < 50 {
            return 1000 // Small images typically have fewer colors
        } else if sizeKB < 200 {
            return 10000
        } else {
            return 100000
        }
    }
    
    /// Extract metadata from image
    private func extractMetadata(data: Data) -> [String: String] {
        var metadata: [String: String] = [:]
        
        // Basic metadata
        metadata["fileSize"] = "\(data.count) bytes"
        metadata["generated"] = ISO8601DateFormatter().string(from: Date())
        metadata["generator"] = "OpenAI gpt-image-1"
        
        return metadata
    }
}

/// Format-specific features
struct FormatFeatures {
    let supportsTransparency: Bool
    let compressionType: CompressionType
    let bestFor: [String]
    let colorDepth: Int
    let maxColors: Int
    let typicalCompression: String
    
    enum CompressionType {
        case lossy, lossless, both
    }
}

/// Analyzed format characteristics
struct FormatCharacteristics {
    let actualFormat: AdvancedImageGenerator.OutputFormat
    let fileSizeKB: Int
    let hasAlphaChannel: Bool
    let colorProfile: String
    let estimatedColors: Int
    let metadata: [String: String]
}

/// Result of formatted image generation
struct FormattedImageResult {
    let base64Data: String
    let format: AdvancedImageGenerator.OutputFormat
    let characteristics: FormatCharacteristics
    let usage: ImageUsage?
    
    var summary: String {
        """
        Format: \(format.rawValue.uppercased())
        Size: \(characteristics.fileSizeKB) KB
        Alpha Channel: \(characteristics.hasAlphaChannel ? "Yes" : "No")
        Color Profile: \(characteristics.colorProfile)
        Estimated Colors: \(characteristics.estimatedColors)
        Best For: \(format.features.bestFor.joined(separator: ", "))
        """
    }
}

extension AdvancedImageError {
    static let conversionFailed = AdvancedImageError.custom("Format conversion failed")
    static let conversionNotSupported = AdvancedImageError.custom("Format conversion not supported on this platform")
    
    enum custom: LocalizedError {
        case custom(String)
        
        var errorDescription: String? {
            switch self {
            case .custom(let message):
                return message
            }
        }
    }
}