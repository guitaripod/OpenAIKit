// AdvancedFeatures.swift
import Foundation
import OpenAIKit

extension AdvancedImageGenerator {
    
    /// Generate images with optimized compression settings
    func generateCompressedImage(
        prompt: String,
        compressionLevel: CompressionLevel = .balanced,
        targetSizeKB: Int? = nil
    ) async throws -> CompressedImageResult {
        
        // Calculate compression value (0-100)
        let compressionValue = compressionLevel.value
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            model: Models.Images.gptImage1,
            outputCompression: compressionValue,
            outputFormat: compressionLevel.recommendedFormat,
            quality: compressionLevel.quality,
            responseFormat: .b64Json,
            size: compressionLevel.recommendedSize
        )
        
        let response = try await openAI.images.generations(request)
        
        guard let imageData = response.data.first,
              let base64 = imageData.b64Json else {
            throw AdvancedImageError.generationFailed
        }
        
        let originalSize = calculateBase64Size(base64)
        
        // If target size specified, may need additional compression
        var finalBase64 = base64
        var finalSize = originalSize
        
        if let target = targetSizeKB, originalSize > target {
            finalBase64 = try await recompressToTarget(
                base64: base64,
                targetKB: target,
                format: compressionLevel.recommendedFormat
            )
            finalSize = calculateBase64Size(finalBase64)
        }
        
        return CompressedImageResult(
            base64Data: finalBase64,
            originalSizeKB: originalSize,
            compressedSizeKB: finalSize,
            compressionRatio: Double(originalSize) / Double(finalSize),
            format: compressionLevel.recommendedFormat,
            usage: response.usage
        )
    }
    
    /// Compression levels with recommended settings
    enum CompressionLevel {
        case maximum      // Smallest file size, lower quality
        case high        // Good compression, acceptable quality
        case balanced    // Balance between size and quality
        case low         // Minimal compression, high quality
        case lossless    // No quality loss (PNG)
        
        var value: Int {
            switch self {
            case .maximum: return 20
            case .high: return 40
            case .balanced: return 60
            case .low: return 80
            case .lossless: return 100
            }
        }
        
        var recommendedFormat: String {
            switch self {
            case .maximum, .high: return "jpeg"
            case .balanced: return "webp"
            case .low: return "jpeg"
            case .lossless: return "png"
            }
        }
        
        var quality: String {
            switch self {
            case .maximum, .high: return "standard"
            case .balanced, .low, .lossless: return "hd"
            }
        }
        
        var recommendedSize: String {
            switch self {
            case .maximum: return "512x512"
            case .high, .balanced: return "1024x1024"
            case .low, .lossless: return "2048x2048"
            }
        }
    }
    
    /// Calculate size of base64 data in KB
    private func calculateBase64Size(_ base64: String) -> Int {
        let sizeInBytes = base64.count * 3 / 4 // Approximate decoded size
        return sizeInBytes / 1024
    }
    
    /// Recompress image to meet target size
    private func recompressToTarget(
        base64: String,
        targetKB: Int,
        format: String
    ) async throws -> String {
        
        guard let imageData = Data(base64Encoded: base64) else {
            throw AdvancedImageError.invalidImageData
        }
        
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData) else {
            throw AdvancedImageError.invalidImageData
        }
        
        // Binary search for optimal compression
        var low: CGFloat = 0.1
        var high: CGFloat = 1.0
        var bestData: Data?
        
        while high - low > 0.05 {
            let mid = (low + high) / 2
            
            let compressedData: Data?
            if format == "jpeg" {
                compressedData = image.jpegData(compressionQuality: mid)
            } else {
                compressedData = image.pngData() // PNG doesn't support quality
            }
            
            guard let data = compressedData else { continue }
            
            let sizeKB = data.count / 1024
            
            if sizeKB <= targetKB {
                bestData = data
                low = mid
            } else {
                high = mid
            }
        }
        
        guard let finalData = bestData else {
            return base64 // Return original if compression failed
        }
        
        return finalData.base64EncodedString()
        #else
        // For non-UIKit platforms, return original
        // In production, implement platform-specific compression
        return base64
        #endif
    }
    
    /// Batch generate images with bandwidth optimization
    func generateBandwidthOptimizedBatch(
        prompts: [String],
        maxTotalSizeMB: Int = 10
    ) async throws -> BatchCompressionResult {
        
        var results: [CompressedImageResult] = []
        var totalSizeKB = 0
        let maxSizeKB = maxTotalSizeMB * 1024
        
        for (index, prompt) in prompts.enumerated() {
            // Calculate remaining budget
            let remainingKB = maxSizeKB - totalSizeKB
            let remainingPrompts = prompts.count - index
            let targetSizePerImage = remainingKB / remainingPrompts
            
            // Determine compression level based on budget
            let compressionLevel: CompressionLevel
            if targetSizePerImage < 50 {
                compressionLevel = .maximum
            } else if targetSizePerImage < 100 {
                compressionLevel = .high
            } else if targetSizePerImage < 200 {
                compressionLevel = .balanced
            } else {
                compressionLevel = .low
            }
            
            let result = try await generateCompressedImage(
                prompt: prompt,
                compressionLevel: compressionLevel,
                targetSizeKB: targetSizePerImage
            )
            
            results.append(result)
            totalSizeKB += result.compressedSizeKB
            
            // Stop if we're approaching the limit
            if totalSizeKB > maxSizeKB * 95 / 100 {
                break
            }
        }
        
        return BatchCompressionResult(
            images: results,
            totalSizeKB: totalSizeKB,
            averageCompressionRatio: results.map { $0.compressionRatio }.reduce(0, +) / Double(results.count),
            imagesGenerated: results.count,
            imagesSkipped: prompts.count - results.count
        )
    }
}

/// Result of compressed image generation
struct CompressedImageResult {
    let base64Data: String
    let originalSizeKB: Int
    let compressedSizeKB: Int
    let compressionRatio: Double
    let format: String
    let usage: ImageUsage?
    
    var compressionPercentage: Double {
        (1.0 - (Double(compressedSizeKB) / Double(originalSizeKB))) * 100
    }
    
    var formattedStats: String {
        """
        Original: \(originalSizeKB) KB
        Compressed: \(compressedSizeKB) KB
        Reduction: \(String(format: "%.1f", compressionPercentage))%
        Format: \(format)
        """
    }
}

/// Result of batch compression
struct BatchCompressionResult {
    let images: [CompressedImageResult]
    let totalSizeKB: Int
    let averageCompressionRatio: Double
    let imagesGenerated: Int
    let imagesSkipped: Int
    
    var totalSizeMB: Double {
        Double(totalSizeKB) / 1024.0
    }
    
    var summary: String {
        """
        Generated: \(imagesGenerated) images
        Skipped: \(imagesSkipped) images
        Total Size: \(String(format: "%.2f", totalSizeMB)) MB
        Avg Compression: \(String(format: "%.1fx", averageCompressionRatio))
        """
    }
}