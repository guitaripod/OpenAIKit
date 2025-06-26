// ImageGenerator.swift
import Foundation
import OpenAIKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension ImageGenerator {
    
    /// Download and convert images from various formats
    func downloadImage(from processed: ProcessedImage) async throws -> ImageData {
        guard let location = processed.metadata.location else {
            throw ImageGenerationError.noImageLocation
        }
        
        switch location {
        case .url(let urlString):
            return try await downloadFromURL(urlString)
            
        case .base64(let base64String):
            return try decodeBase64Image(base64String)
        }
    }
    
    /// Download image from URL with retry logic
    private func downloadFromURL(_ urlString: String) async throws -> ImageData {
        guard let url = URL(string: urlString) else {
            throw ImageGenerationError.invalidURL(urlString)
        }
        
        var lastError: Error?
        
        // Retry up to 3 times for network issues
        for attempt in 1...3 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw ImageGenerationError.downloadFailed(
                        statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0
                    )
                }
                
                return ImageData(
                    data: data,
                    format: detectImageFormat(from: data),
                    size: data.count
                )
            } catch {
                lastError = error
                if attempt < 3 {
                    // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? ImageGenerationError.downloadFailed(statusCode: 0)
    }
    
    /// Decode base64 image data
    private func decodeBase64Image(_ base64String: String) throws -> ImageData {
        // Remove data URL prefix if present
        let base64Data = base64String
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/webp;base64,", with: "")
        
        guard let data = Data(base64Encoded: base64Data) else {
            throw ImageGenerationError.invalidBase64
        }
        
        return ImageData(
            data: data,
            format: detectImageFormat(from: data),
            size: data.count
        )
    }
    
    /// Detect image format from data
    private func detectImageFormat(from data: Data) -> ImageFormat {
        guard data.count > 4 else { return .unknown }
        
        let header = data.prefix(4)
        
        if header.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .jpeg
        } else if header.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return .png
        } else if header.starts(with: [0x52, 0x49, 0x46, 0x46]) {
            return .webp
        } else {
            return .unknown
        }
    }
    
    /// Convert image data to platform-specific image
    func createPlatformImage(from imageData: ImageData) throws -> Any {
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData.data) else {
            throw ImageGenerationError.invalidImageData
        }
        return image
        #elseif canImport(AppKit)
        guard let image = NSImage(data: imageData.data) else {
            throw ImageGenerationError.invalidImageData
        }
        return image
        #else
        // Return raw data for non-Apple platforms
        return imageData.data
        #endif
    }
    
    /// Save image to file with format conversion
    func saveImage(
        _ imageData: ImageData,
        to url: URL,
        format: ImageFormat? = nil,
        compressionQuality: Double = 0.9
    ) throws {
        
        let targetFormat = format ?? imageData.format
        var dataToSave = imageData.data
        
        #if canImport(UIKit)
        if let image = UIImage(data: imageData.data) {
            switch targetFormat {
            case .jpeg:
                dataToSave = image.jpegData(compressionQuality: compressionQuality) ?? imageData.data
            case .png:
                dataToSave = image.pngData() ?? imageData.data
            default:
                break
            }
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: imageData.data),
           let tiffData = image.tiffRepresentation,
           let imageRep = NSBitmapImageRep(data: tiffData) {
            switch targetFormat {
            case .jpeg:
                dataToSave = imageRep.representation(
                    using: .jpeg,
                    properties: [.compressionFactor: compressionQuality]
                ) ?? imageData.data
            case .png:
                dataToSave = imageRep.representation(
                    using: .png,
                    properties: [:]
                ) ?? imageData.data
            default:
                break
            }
        }
        #endif
        
        try dataToSave.write(to: url)
    }
}

/// Container for downloaded image data
struct ImageData {
    let data: Data
    let format: ImageFormat
    let size: Int
    
    var sizeInMB: Double {
        Double(size) / 1024.0 / 1024.0
    }
}

/// Supported image formats
enum ImageFormat: String {
    case png = "png"
    case jpeg = "jpeg"
    case webp = "webp"
    case unknown = "unknown"
    
    var mimeType: String {
        switch self {
        case .png: return "image/png"
        case .jpeg: return "image/jpeg"
        case .webp: return "image/webp"
        case .unknown: return "application/octet-stream"
        }
    }
}

extension ImageGenerationError {
    static let noImageLocation = ImageGenerationError.custom("No image location available")
    static func invalidURL(_ url: String) -> ImageGenerationError {
        .custom("Invalid URL: \(url)")
    }
    static func downloadFailed(statusCode: Int) -> ImageGenerationError {
        .custom("Download failed with status code: \(statusCode)")
    }
    static let invalidBase64 = ImageGenerationError.custom("Invalid base64 image data")
    static let invalidImageData = ImageGenerationError.custom("Could not create image from data")
    
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