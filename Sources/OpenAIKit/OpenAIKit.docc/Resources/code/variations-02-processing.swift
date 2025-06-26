import OpenAIKit
import UIKit
import CoreImage

// MARK: - Image Processing for Variations

class ImageProcessor {
    private let context = CIContext()
    
    // Prepare image for variation request
    func prepareImage(_ image: UIImage, maxSize: CGSize = CGSize(width: 1024, height: 1024)) -> Data? {
        // Resize if needed
        let resized = resizeImage(image, to: maxSize)
        
        // Convert to square format (required by OpenAI)
        let squared = makeSquare(resized)
        
        // Convert to PNG data
        return squared.pngData()
    }
    
    // Resize image maintaining aspect ratio
    private func resizeImage(_ image: UIImage, to maxSize: CGSize) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        var newSize = maxSize
        
        if aspectRatio > 1 {
            // Landscape
            newSize.height = maxSize.width / aspectRatio
        } else {
            // Portrait
            newSize.width = maxSize.height * aspectRatio
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resized
    }
    
    // Make image square by adding padding
    private func makeSquare(_ image: UIImage) -> UIImage {
        let size = max(image.size.width, image.size.height)
        let squareSize = CGSize(width: size, height: size)
        
        UIGraphicsBeginImageContextWithOptions(squareSize, true, 1.0)
        
        // Fill with white background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: squareSize))
        
        // Center the image
        let x = (size - image.size.width) / 2
        let y = (size - image.size.height) / 2
        image.draw(at: CGPoint(x: x, y: y))
        
        let squared = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return squared
    }
    
    // Apply filters before creating variations
    func applyPreprocessing(_ image: UIImage, brightness: Float = 0, contrast: Float = 1) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Batch Processing

class VariationBatchProcessor {
    let processor = ImageProcessor()
    let openAI: OpenAIKit
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    func processMultipleImages(_ images: [UIImage]) async throws -> [URL] {
        var allVariations: [URL] = []
        
        for image in images {
            // Prepare image
            guard let imageData = processor.prepareImage(image) else {
                continue
            }
            
            // Create variations
            let request = ImageVariationRequest(
                image: imageData,
                n: 1,
                size: .size512x512  // Smaller size for batch processing
            )
            
            do {
                let response = try await openAI.createImageVariation(request: request)
                
                if case .url(let urlString) = response.data.first,
                   let url = URL(string: urlString) {
                    allVariations.append(url)
                }
            } catch {
                // Continue with next image if one fails
                print("Failed to create variation: \(error)")
            }
            
            // Add delay to respect rate limits
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        return allVariations
    }
}