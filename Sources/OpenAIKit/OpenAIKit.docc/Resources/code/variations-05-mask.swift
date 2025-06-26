import OpenAIKit
import UIKit
import CoreGraphics

// MARK: - Image Masking for Variations

class ImageMaskGenerator {
    
    // Create a mask for selective image variations
    func createMask(
        for image: UIImage,
        maskRegion: MaskRegion
    ) -> UIImage? {
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Fill with black (masked area)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw white (unmasked area) based on region
        context.setFillColor(UIColor.white.cgColor)
        
        switch maskRegion {
        case .rectangle(let rect):
            context.fill(rect)
            
        case .ellipse(let rect):
            context.fillEllipse(in: rect)
            
        case .polygon(let points):
            guard points.count >= 3 else { return nil }
            context.move(to: points[0])
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            context.closePath()
            context.fillPath()
            
        case .freeform(let path):
            context.addPath(path)
            context.fillPath()
            
        case .inverse(let innerRegion):
            // First fill everything white
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            
            // Then fill the inner region black
            context.setFillColor(UIColor.black.cgColor)
            drawRegion(innerRegion, in: context)
        }
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return maskImage
    }
    
    private func drawRegion(_ region: MaskRegion, in context: CGContext) {
        switch region {
        case .rectangle(let rect):
            context.fill(rect)
        case .ellipse(let rect):
            context.fillEllipse(in: rect)
        case .polygon(let points):
            guard points.count >= 3 else { return }
            context.move(to: points[0])
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            context.closePath()
            context.fillPath()
        case .freeform(let path):
            context.addPath(path)
            context.fillPath()
        case .inverse:
            break // Not applicable in this context
        }
    }
}

// MARK: - Mask Region Types

enum MaskRegion {
    case rectangle(CGRect)
    case ellipse(CGRect)
    case polygon([CGPoint])
    case freeform(CGPath)
    case inverse(MaskRegion)
}

// MARK: - Masked Variation Generator

class MaskedVariationGenerator {
    let openAI: OpenAIKit
    let maskGenerator = ImageMaskGenerator()
    
    init(apiKey: String) {
        self.openAI = OpenAIKit(apiKey: apiKey)
    }
    
    func generateMaskedVariation(
        image: UIImage,
        mask: UIImage,
        prompt: String? = nil
    ) async throws -> MaskedVariationResult {
        // Prepare image data
        guard let imageData = image.pngData(),
              let maskData = mask.pngData() else {
            throw ImageError.invalidImageData
        }
        
        // Create edit request with mask
        let editRequest = ImageEditRequest(
            image: imageData,
            mask: maskData,
            prompt: prompt ?? "Create a variation of the masked area",
            n: 1,
            size: .size1024x1024
        )
        
        let startTime = Date()
        let response = try await openAI.createImageEdit(request: editRequest)
        let processingTime = Date().timeIntervalSince(startTime)
        
        guard case .url(let urlString) = response.data.first,
              let url = URL(string: urlString) else {
            throw ImageError.processingFailed
        }
        
        return MaskedVariationResult(
            originalImage: image,
            mask: mask,
            resultURL: url,
            prompt: prompt,
            processingTime: processingTime
        )
    }
    
    // Generate multiple variations with different masks
    func generateBatchMaskedVariations(
        image: UIImage,
        maskRegions: [MaskRegion],
        prompts: [String]? = nil
    ) async throws -> [MaskedVariationResult] {
        var results: [MaskedVariationResult] = []
        
        for (index, region) in maskRegions.enumerated() {
            guard let mask = maskGenerator.createMask(for: image, maskRegion: region) else {
                continue
            }
            
            let prompt = prompts?[safe: index]
            
            do {
                let result = try await generateMaskedVariation(
                    image: image,
                    mask: mask,
                    prompt: prompt
                )
                results.append(result)
            } catch {
                print("Failed to generate masked variation \(index): \(error)")
            }
            
            // Rate limiting
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        return results
    }
}

// MARK: - Interactive Mask Editor

class InteractiveMaskEditor: ObservableObject {
    @Published var currentPath = CGMutablePath()
    @Published var paths: [CGPath] = []
    @Published var maskMode: MaskMode = .draw
    @Published var brushSize: CGFloat = 20
    
    enum MaskMode {
        case draw
        case erase
        case rectangle
        case ellipse
    }
    
    func startDrawing(at point: CGPoint) {
        currentPath = CGMutablePath()
        currentPath.move(to: point)
    }
    
    func continueDrawing(to point: CGPoint) {
        currentPath.addLine(to: point)
    }
    
    func finishDrawing() {
        paths.append(currentPath)
        currentPath = CGMutablePath()
    }
    
    func generateMask(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Start with black background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw white paths
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(brushSize)
        context.setLineCap(.round)
        
        for path in paths {
            context.addPath(path)
            context.strokePath()
        }
        
        let mask = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return mask
    }
    
    func clear() {
        paths.removeAll()
        currentPath = CGMutablePath()
    }
    
    func undo() {
        _ = paths.popLast()
    }
}

// MARK: - Models

struct MaskedVariationResult {
    let originalImage: UIImage
    let mask: UIImage
    let resultURL: URL
    let prompt: String?
    let processingTime: TimeInterval
}

// MARK: - Helpers

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Mask Templates

struct MaskTemplate {
    let name: String
    let description: String
    let regionGenerator: (CGSize) -> MaskRegion
    
    static let templates = [
        MaskTemplate(
            name: "Center Focus",
            description: "Masks the center of the image",
            regionGenerator: { size in
                let inset = min(size.width, size.height) * 0.2
                return .ellipse(CGRect(
                    x: inset,
                    y: inset,
                    width: size.width - inset * 2,
                    height: size.height - inset * 2
                ))
            }
        ),
        MaskTemplate(
            name: "Border",
            description: "Masks the borders of the image",
            regionGenerator: { size in
                let inset = min(size.width, size.height) * 0.1
                return .inverse(.rectangle(CGRect(
                    x: inset,
                    y: inset,
                    width: size.width - inset * 2,
                    height: size.height - inset * 2
                )))
            }
        ),
        MaskTemplate(
            name: "Corner",
            description: "Masks a corner of the image",
            regionGenerator: { size in
                .rectangle(CGRect(
                    x: 0,
                    y: 0,
                    width: size.width * 0.4,
                    height: size.height * 0.4
                ))
            }
        )
    ]
}