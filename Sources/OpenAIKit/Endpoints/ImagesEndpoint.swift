import Foundation

/// Provides access to OpenAI's image generation, editing, and variation endpoints.
///
/// The `ImagesEndpoint` class offers methods to:
/// - Generate new images from text descriptions
/// - Edit existing images based on text prompts
/// - Create variations of existing images
///
/// All methods are asynchronous and can throw errors for network issues,
/// API errors, or invalid parameters.
///
/// ## Overview
/// This endpoint interfaces with OpenAI's DALL·E models to create, modify,
/// and vary images. It supports both DALL·E 2 and DALL·E 3 models, each with
/// different capabilities and constraints.
///
/// ## Error Handling
/// Common errors include:
/// - Invalid image format (only PNG supported)
/// - Image size exceeding limits (4MB)
/// - Invalid size specifications
/// - Rate limiting
/// - Content policy violations
///
/// - SeeAlso: ``ImageGenerationRequest``, ``ImageEditRequest``, ``ImageVariationRequest``
public final class ImagesEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Generates one or more images from a text prompt.
    ///
    /// This method creates original images based on your text description using
    /// OpenAI's DALL·E models. You can control various aspects of the generation
    /// including size, style, quality, and the number of images.
    ///
    /// ## Example
    /// ```swift
    /// // Basic image generation
    /// let request = ImageGenerationRequest(
    ///     prompt: "A cozy coffee shop on a rainy day, warm lighting, watercolor style"
    /// )
    /// let response = try await openAI.images.generations(request)
    /// 
    /// // Advanced generation with DALL·E 3
    /// let hdRequest = ImageGenerationRequest(
    ///     prompt: "A majestic eagle soaring over mountain peaks at sunrise",
    ///     model: "dall-e-3",
    ///     size: "1792x1024",
    ///     quality: "hd",
    ///     style: "vivid",
    ///     n: 1
    /// )
    /// let hdResponse = try await openAI.images.generations(hdRequest)
    /// ```
    ///
    /// ## Model Differences
    /// - **DALL·E 2**: Faster, supports multiple images (n=1-10), standard quality
    /// - **DALL·E 3**: Higher quality, better prompt adherence, only single image generation
    ///
    /// - Parameter request: The image generation request containing prompt and options
    /// - Returns: An ``ImageResponse`` containing the generated image(s)
    /// - Throws: An error if the request fails, including:
    ///   - Network errors
    ///   - Invalid parameters (e.g., unsupported size for model)
    ///   - Content policy violations
    ///   - Rate limiting errors
    ///
    /// - Important: DALL·E 3 may revise your prompt for safety or clarity.
    /// Check the `revisedPrompt` field in the response to see any modifications.
    public func generations(_ request: ImageGenerationRequest) async throws -> ImageResponse {
        let apiRequest = ImageGenerationAPIRequest(request: request)
        return try await networkClient.execute(apiRequest)
    }
    
    /// Edits an existing image based on a text prompt.
    ///
    /// This method allows you to modify specific parts of an image by providing
    /// a text description of the desired changes. You can optionally provide a mask
    /// to specify exactly which areas should be edited.
    ///
    /// ## Example Without Mask
    /// ```swift
    /// // Edit entire image based on prompt
    /// let imageData = try Data(contentsOf: imageURL)
    /// let request = ImageEditRequest(
    ///     image: imageData,
    ///     imageName: "photo.png",
    ///     prompt: "Add a sunset in the background"
    /// )
    /// let response = try await openAI.images.edits(request)
    /// ```
    ///
    /// ## Example With Mask
    /// ```swift
    /// // Edit only masked areas
    /// let imageData = try Data(contentsOf: imageURL)
    /// let maskData = try Data(contentsOf: maskURL)  // Transparent areas will be edited
    /// 
    /// let request = ImageEditRequest(
    ///     image: imageData,
    ///     imageName: "portrait.png",
    ///     prompt: "Replace with a blue formal shirt",
    ///     mask: maskData,
    ///     maskName: "shirt-mask.png",
    ///     size: "512x512"
    /// )
    /// let response = try await openAI.images.edits(request)
    /// ```
    ///
    /// ## Mask Requirements
    /// - Must be PNG format with alpha channel
    /// - Same dimensions as the source image
    /// - Transparent pixels (alpha = 0) mark areas to edit
    /// - Opaque pixels (alpha = 255) preserve original content
    ///
    /// - Parameter request: The image edit request containing the image, prompt, and optional mask
    /// - Returns: An ``ImageResponse`` containing the edited image(s)
    /// - Throws: An error if the request fails, including:
    ///   - Invalid image format (only PNG supported)
    ///   - Image size exceeding 4MB
    ///   - Mismatched dimensions between image and mask
    ///   - Network or API errors
    ///
    /// - Note: Currently only supports DALL·E 2 model
    /// - Important: The edit quality depends on prompt clarity and mask precision
    public func edits(_ request: ImageEditRequest) async throws -> ImageResponse {
        let apiRequest = ImageEditAPIRequest(request: request)
        return try await networkClient.upload(apiRequest)
    }
    
    /// Creates variations of an existing image.
    ///
    /// This method generates new images that maintain the same general style,
    /// composition, and subject matter as the input image, but with creative
    /// differences. It's useful for exploring different artistic interpretations
    /// of a concept.
    ///
    /// ## Example
    /// ```swift
    /// // Generate multiple variations
    /// let originalImage = try Data(contentsOf: artworkURL)
    /// let request = ImageVariationRequest(
    ///     image: originalImage,
    ///     imageName: "artwork.png",
    ///     n: 4,  // Generate 4 variations
    ///     size: "512x512"
    /// )
    /// let response = try await openAI.images.variations(request)
    /// 
    /// // Each variation will be a unique interpretation
    /// for (index, imageObject) in response.data.enumerated() {
    ///     print("Variation \(index + 1): \(imageObject.url ?? "No URL")")
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - Creating multiple versions of logos or designs
    /// - Exploring different artistic styles for the same subject
    /// - Generating variety in game assets or illustrations
    /// - A/B testing different visual approaches
    ///
    /// - Parameter request: The image variation request containing the source image
    /// - Returns: An ``ImageResponse`` containing the generated variation(s)
    /// - Throws: An error if the request fails, including:
    ///   - Invalid image format (only PNG supported)
    ///   - Image size exceeding 4MB
    ///   - Invalid size specifications
    ///   - Network or API errors
    ///
    /// - Note: Currently only supports DALL·E 2 model
    /// - Tip: The variations maintain the core elements of the original but can
    /// differ significantly in details, colors, and artistic interpretation
    public func variations(_ request: ImageVariationRequest) async throws -> ImageResponse {
        let apiRequest = ImageVariationAPIRequest(request: request)
        return try await networkClient.upload(apiRequest)
    }
}

private struct ImageGenerationAPIRequest: Request {
    typealias Body = ImageGenerationRequest
    typealias Response = ImageResponse
    
    let path = "images/generations"
    let method: HTTPMethod = .post
    let body: ImageGenerationRequest?
    
    init(request: ImageGenerationRequest) {
        self.body = request
    }
}

private struct ImageEditAPIRequest: UploadRequest {
    typealias Response = ImageResponse
    
    let path = "images/edits"
    private let request: ImageEditRequest
    
    init(request: ImageEditRequest) {
        self.request = request
    }
    
    func multipartData(boundary: String) async throws -> Data {
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(request.imageName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(request.image)
        data.append("\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(request.prompt)\r\n".data(using: .utf8)!)
        
        if let mask = request.mask, let maskName = request.maskName {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"mask\"; filename=\"\(maskName)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            data.append(mask)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        if let model = request.model {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(model)\r\n".data(using: .utf8)!)
        }
        
        if let n = request.n {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"n\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(n)\r\n".data(using: .utf8)!)
        }
        
        if let size = request.size {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(size)\r\n".data(using: .utf8)!)
        }
        
        if let responseFormat = request.responseFormat {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(responseFormat.rawValue)\r\n".data(using: .utf8)!)
        }
        
        if let user = request.user {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"user\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(user)\r\n".data(using: .utf8)!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
}

private struct ImageVariationAPIRequest: UploadRequest {
    typealias Response = ImageResponse
    
    let path = "images/variations"
    private let request: ImageVariationRequest
    
    init(request: ImageVariationRequest) {
        self.request = request
    }
    
    func multipartData(boundary: String) async throws -> Data {
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(request.imageName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(request.image)
        data.append("\r\n".data(using: .utf8)!)
        
        if let model = request.model {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(model)\r\n".data(using: .utf8)!)
        }
        
        if let n = request.n {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"n\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(n)\r\n".data(using: .utf8)!)
        }
        
        if let responseFormat = request.responseFormat {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(responseFormat.rawValue)\r\n".data(using: .utf8)!)
        }
        
        if let size = request.size {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(size)\r\n".data(using: .utf8)!)
        }
        
        if let user = request.user {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"user\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(user)\r\n".data(using: .utf8)!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
}