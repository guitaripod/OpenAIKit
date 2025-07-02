import Foundation

/// A request to generate one or more images from a text prompt.
///
/// `ImageGenerationRequest` enables you to create original, high-quality images using OpenAI's DALL·E models.
/// From photorealistic scenes to artistic interpretations, you can generate images for any creative need.
///
/// ## Overview
///
/// Image generation uses advanced AI to transform text descriptions into visual content. The quality
/// and accuracy of generated images depend on prompt clarity, model selection, and parameter tuning.
///
/// ## Basic Example
///
/// ```swift
/// // Simple generation
/// let request = ImageGenerationRequest(
///     prompt: "A serene landscape with mountains and a lake at sunset",
///     model: Models.Images.dallE3
/// )
///
/// // With full customization
/// let request = ImageGenerationRequest(
///     prompt: "A futuristic city with flying cars, neon lights, cyberpunk style",
///     model: Models.Images.dallE3,
///     size: "1792x1024",     // Wide aspect ratio
///     quality: "hd",         // High definition
///     style: "vivid",        // Dramatic rendering
///     n: 1                   // Number of variations
/// )
/// ```
///
/// ## Prompt Engineering
///
/// Better prompts produce better images:
///
/// ```swift
/// // ❌ Vague prompt
/// "A dog"
///
/// // ✅ Detailed prompt
/// "A golden retriever puppy playing in a sunlit meadow with butterflies,
///  soft focus background, warm afternoon light, photorealistic style"
///
/// // ✅ Artistic prompt
/// "Abstract representation of time, swirling cosmic colors, Salvador Dali inspired,
///  surrealist style, dramatic lighting, oil painting texture"
/// ```
///
/// ## Model Comparison
///
/// - **DALL·E 3**: Latest model with best quality, prompt adherence, and creative control
/// - **DALL·E 2**: Previous generation, faster and cheaper, good for simple images
///
/// - Important: Prompts are automatically enhanced by DALL·E 3 for better results
public struct ImageGenerationRequest: Codable, Sendable {
    /// The text prompt describing the desired image(s).
    ///
    /// The prompt is the most important parameter - it determines what will be generated.
    /// DALL·E 3 automatically enhances prompts for better results, while DALL·E 2 uses them as-is.
    ///
    /// ## Prompt Tips
    ///
    /// **Structure**: Subject + Style + Details + Lighting + Mood
    ///
    /// **Good Prompts Include**:
    /// - Clear subject description
    /// - Art style or medium
    /// - Color palette
    /// - Lighting conditions  
    /// - Camera angle/perspective
    /// - Mood or atmosphere
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Photorealistic
    /// "A majestic snow leopard resting on a rocky outcrop, Himalayan mountains
    ///  in background, golden hour lighting, National Geographic photography style"
    ///
    /// // Artistic
    /// "Art nouveau poster of a woman with flowing hair intertwined with flowers,
    ///  gold and emerald color scheme, decorative border, Alphonse Mucha style"
    ///
    /// // Technical/Diagram
    /// "Technical cutaway diagram of a spacecraft engine, labeled components,
    ///  clean white background, engineering blueprint style, high detail"
    ///
    /// // Fantasy/Gaming
    /// "Epic fantasy battle scene with dragon breathing fire over castle,
    ///  dramatic storm clouds, cinematic lighting, concept art style"
    /// ```
    ///
    /// - Note: Maximum 1000 characters for DALL·E 2, 4000 for DALL·E 3
    public let prompt: String
    
    /// The background setting for the generated image.
    ///
    /// Controls the background context or environment of the generated image.
    public let background: String?
    
    /// The model to use for image generation.
    ///
    /// Choose based on your quality, speed, and budget requirements.
    ///
    /// ## Available Models
    ///
    /// **DALL·E 3** (`dall-e-3`)
    /// - Latest generation with best quality
    /// - Superior prompt understanding
    /// - Automatic prompt enhancement
    /// - Supports HD quality and style options
    /// - More expensive but worth it for quality
    ///
    /// **DALL·E 2** (`dall-e-2`)
    /// - Previous generation model
    /// - Faster generation time
    /// - Lower cost per image
    /// - Good for simple images
    /// - Limited to 1024x1024 maximum
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // For best quality
    /// model: Models.Images.dallE3
    ///
    /// // For budget/speed
    /// model: Models.Images.dallE2
    /// ```
    ///
    /// - Default: `dall-e-2` if not specified
    /// - Tip: Always use DALL·E 3 for production applications
    public let model: String?
    
    /// Content moderation level for the generated images.
    ///
    /// Controls the strictness of content filtering applied to the output.
    public let moderation: String?
    
    /// The number of images to generate.
    ///
    /// Generate multiple variations of your prompt in a single request.
    ///
    /// ## Model Limits
    ///
    /// - **DALL·E 2**: 1-10 images per request
    /// - **DALL·E 3**: Only 1 image per request
    ///
    /// ## Cost Considerations
    ///
    /// You're charged for each image generated:
    /// - Generating n=4 images costs 4x a single image
    /// - Consider generating one and iterating on the prompt
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Generate variations (DALL·E 2 only)
    /// let request = ImageGenerationRequest(
    ///     prompt: "Abstract geometric patterns",
    ///     model: Models.Images.dallE2,
    ///     n: 4  // Get 4 different interpretations
    /// )
    /// ```
    ///
    /// - Default: 1
    /// - Note: Each image may interpret the prompt differently
    public let n: Int?
    
    /// The compression level for the output image.
    ///
    /// Higher values result in smaller file sizes but lower quality.
    /// Range typically from 0 to 100.
    public let outputCompression: Int?
    
    /// The output image format.
    ///
    /// Supported formats include "png", "jpg", "webp".
    public let outputFormat: String?
    
    /// The quality of the generated image.
    ///
    /// Controls the detail level and rendering quality of generated images.
    ///
    /// ## Options
    ///
    /// **Standard Quality** (`"standard"`)
    /// - Faster generation (5-10 seconds)
    /// - Good for drafts and iterations
    /// - Lower computational cost
    /// - Sufficient for most use cases
    ///
    /// **HD Quality** (`"hd"`) - DALL·E 3 only
    /// - Higher detail and clarity
    /// - Better for fine details and text
    /// - Slower generation (10-20 seconds)
    /// - 2x the cost of standard
    ///
    /// ## When to Use HD
    ///
    /// ```swift
    /// // HD for detailed work
    /// quality: "hd"  // When you need:
    ///               // - Text in images
    ///               // - Fine details
    ///               // - Print quality
    ///               // - Professional use
    ///
    /// // Standard for iterations
    /// quality: "standard"  // When you need:
    ///                    // - Quick drafts
    ///                    // - Concept exploration
    ///                    // - Budget consciousness
    /// ```
    ///
    /// - Default: `"standard"`
    public let quality: String?
    
    /// The format in which the generated images are returned.
    ///
    /// - SeeAlso: ``ImageResponseFormat``
    public let responseFormat: ImageResponseFormat?
    
    /// The size of the generated images.
    ///
    /// Different sizes suit different use cases and aspect ratios.
    ///
    /// ## DALL·E 2 Sizes
    ///
    /// - `"256x256"`: Thumbnails, avatars (cheapest)
    /// - `"512x512"`: Medium size, web graphics
    /// - `"1024x1024"`: Full size, detailed images (default)
    ///
    /// ## DALL·E 3 Sizes
    ///
    /// - `"1024x1024"`: Square format (default)
    ///   - Instagram posts
    ///   - Profile pictures
    ///   - App icons
    ///
    /// - `"1792x1024"`: Landscape format (16:9 approx)
    ///   - Desktop wallpapers
    ///   - Website headers
    ///   - Presentation slides
    ///
    /// - `"1024x1792"`: Portrait format (9:16 approx)
    ///   - Mobile wallpapers
    ///   - Story posts
    ///   - Book covers
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Desktop wallpaper
    /// size: "1792x1024"
    ///
    /// // Mobile wallpaper
    /// size: "1024x1792"
    ///
    /// // Social media post
    /// size: "1024x1024"
    /// ```
    ///
    /// - Note: Larger sizes cost more and take longer
    public let size: String?
    
    /// The style of the generated images.
    ///
    /// Controls the artistic interpretation and rendering style (DALL·E 3 only).
    ///
    /// ## Style Options
    ///
    /// **Vivid** (`"vivid"`)
    /// - Hyper-real and dramatic
    /// - Enhanced colors and contrast
    /// - More artistic interpretation
    /// - Great for:
    ///   - Fantasy art
    ///   - Concept designs
    ///   - Eye-catching visuals
    ///   - Marketing materials
    ///
    /// **Natural** (`"natural"`) - Default
    /// - Realistic and balanced
    /// - True-to-life colors
    /// - Photographic quality
    /// - Great for:
    ///   - Product images
    ///   - Portraits
    ///   - Documentary style
    ///   - Educational content
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Dramatic fantasy art
    /// style: "vivid"
    ///
    /// // Realistic product shot
    /// style: "natural"
    /// ```
    ///
    /// - Note: Only available for DALL·E 3
    /// - Default: `"vivid"` for DALL·E 3
    public let style: String?
    
    /// A unique identifier representing your end-user.
    ///
    /// This can help OpenAI monitor and detect abuse.
    public let user: String?
    
    /// Creates a new image generation request.
    ///
    /// Most parameters have sensible defaults, so you can start with just a prompt.
    ///
    /// ## Common Patterns
    ///
    /// ```swift
    /// // Simple generation
    /// ImageGenerationRequest(prompt: "A beautiful sunset")
    ///
    /// // High quality portrait
    /// ImageGenerationRequest(
    ///     prompt: "Professional headshot of a scientist",
    ///     model: Models.Images.dallE3,
    ///     size: "1024x1792",
    ///     quality: "hd",
    ///     style: "natural"
    /// )
    ///
    /// // Multiple variations (DALL·E 2)
    /// ImageGenerationRequest(
    ///     prompt: "Abstract geometric patterns",
    ///     model: Models.Images.dallE2,
    ///     n: 4,
    ///     size: "512x512"
    /// )
    ///
    /// // For immediate use (base64)
    /// ImageGenerationRequest(
    ///     prompt: "App icon with rocket",
    ///     responseFormat: .b64Json
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - prompt: Text description of the desired image(s)
    ///   - background: Background setting for the image
    ///   - model: Model to use (defaults to dall-e-2)
    ///   - moderation: Content moderation level
    ///   - n: Number of images (1-10 for DALL·E 2, 1 for DALL·E 3)
    ///   - outputCompression: Compression level (0-100)
    ///   - outputFormat: Image format (png, jpg, webp)
    ///   - quality: Quality level (standard or hd)
    ///   - responseFormat: Response format (url or b64_json)
    ///   - size: Image dimensions
    ///   - style: Artistic style (vivid or natural)
    ///   - user: End-user identifier for abuse monitoring
    public init(
        prompt: String,
        background: String? = nil,
        model: String? = nil,
        moderation: String? = nil,
        n: Int? = nil,
        outputCompression: Int? = nil,
        outputFormat: String? = nil,
        quality: String? = nil,
        responseFormat: ImageResponseFormat? = nil,
        size: String? = nil,
        style: String? = nil,
        user: String? = nil
    ) {
        self.prompt = prompt
        self.background = background
        self.model = model
        self.moderation = moderation
        self.n = n
        self.outputCompression = outputCompression
        self.outputFormat = outputFormat
        self.quality = quality
        self.responseFormat = responseFormat
        self.size = size
        self.style = style
        self.user = user
    }
    
    private enum CodingKeys: String, CodingKey {
        case prompt
        case background
        case model
        case moderation
        case n
        case outputCompression = "output_compression"
        case outputFormat = "output_format"
        case quality
        case responseFormat = "response_format"
        case size
        case style
        case user
    }
    
    /// Custom encoding to handle gpt-image-1 specific requirements
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(prompt, forKey: .prompt)
        try container.encodeIfPresent(model, forKey: .model)
        try container.encodeIfPresent(n, forKey: .n)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(user, forKey: .user)
        
        // Model-specific parameter handling
        if model == "gpt-image-1" {
            // gpt-image-1 specific parameters
            try container.encodeIfPresent(background, forKey: .background)
            try container.encodeIfPresent(moderation, forKey: .moderation)
            try container.encodeIfPresent(outputCompression, forKey: .outputCompression)
            try container.encodeIfPresent(outputFormat, forKey: .outputFormat)
            try container.encodeIfPresent(quality, forKey: .quality)
        } else {
            // DALL-E parameters
            if model != "dall-e-2" {
                // Quality is not supported for DALL-E 2
                try container.encodeIfPresent(quality, forKey: .quality)
            }
            
            // response_format is only for DALL-E models
            try container.encodeIfPresent(responseFormat, forKey: .responseFormat)
            
            // Only DALL-E 3 supports style
            if model == "dall-e-3" {
                try container.encodeIfPresent(style, forKey: .style)
            }
        }
    }
}

/// The format in which generated images are returned.
///
/// Choose between temporary URLs or embedded base64 data based on your application's needs.
///
/// ## Format Comparison
///
/// **URL Format** (`.url`)
/// - Returns temporary hosted URLs
/// - Smaller response size
/// - Requires additional HTTP request to download
/// - URLs expire after ~1 hour
/// - Best for: Web display, deferred downloading
///
/// **Base64 Format** (`.b64Json`)
/// - Returns image data in response
/// - Larger response size (~33% overhead)
/// - Immediate access to image data
/// - No expiration concerns
/// - Best for: Direct processing, storage, offline use
///
/// ## Usage Examples
///
/// ```swift
/// // For web display
/// responseFormat: .url
/// // Response: {"url": "https://..."}
///
/// // For immediate processing
/// responseFormat: .b64Json  
/// // Response: {"b64_json": "iVBORw0KGgo..."}
///
/// // Convert base64 to Data
/// if case .b64Json = responseFormat,
///    let b64String = response.data.first?.b64Json {
///     let imageData = Data(base64Encoded: b64String)!
///     let image = UIImage(data: imageData)
/// }
/// ```
public enum ImageResponseFormat: String, Codable, Sendable {
    /// Return images as temporary URLs.
    ///
    /// The URLs are hosted by OpenAI and will expire after a short period.
    /// This is the most common format for web applications.
    case url
    
    /// Return images as base64-encoded JSON strings.
    ///
    /// The entire image data is embedded in the response.
    /// Useful when you need immediate access to the image data without additional HTTP requests.
    case b64Json = "b64_json"
}

/// A request to edit an existing image based on a text prompt.
///
/// `ImageEditRequest` enables AI-powered image editing by replacing masked regions with new content
/// generated from your text description. Perfect for removing objects, changing backgrounds, or
/// adding new elements to existing images.
///
/// ## Overview
///
/// Image editing works by:
/// 1. Providing an original image
/// 2. Specifying areas to edit (via mask)
/// 3. Describing desired changes (via prompt)
/// 4. AI generates new content for masked areas
///
/// ## Basic Example
///
/// ```swift
/// let imageData = try Data(contentsOf: imageURL)
/// let maskData = try Data(contentsOf: maskURL)
/// 
/// let request = ImageEditRequest(
///     image: imageData,
///     imageName: "photo.png",
///     prompt: "Replace with a sunny beach",
///     mask: maskData,
///     maskName: "mask.png"
/// )
/// ```
///
/// ## Mask Creation
///
/// The mask is a PNG image that defines editable areas:
///
/// - **Transparent pixels** (alpha = 0): Areas to edit/replace
/// - **Opaque pixels** (alpha = 255): Areas to preserve
/// - **Semi-transparent**: Partial editing (not recommended)
///
/// ### Creating Masks Programmatically
///
/// ```swift
/// // Example: Create a circular mask
/// func createCircularMask(size: CGSize, center: CGPoint, radius: CGFloat) -> Data? {
///     UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
///     defer { UIGraphicsEndImageContext() }
///     
///     let context = UIGraphicsGetCurrentContext()
///     
///     // Fill with black (preserve)
///     context?.setFillColor(UIColor.black.cgColor)
///     context?.fill(CGRect(origin: .zero, size: size))
///     
///     // Cut out circle (edit area)
///     context?.setBlendMode(.clear)
///     context?.fillEllipse(in: CGRect(
///         x: center.x - radius,
///         y: center.y - radius,
///         width: radius * 2,
///         height: radius * 2
///     ))
///     
///     return UIGraphicsGetImageFromCurrentImageContext()?.pngData()
/// }
/// ```
///
/// ## Common Use Cases
///
/// ```swift
/// // Remove object
/// prompt: "seamless background"
///
/// // Replace sky
/// prompt: "dramatic sunset with clouds"
///
/// // Add object
/// prompt: "modern glass coffee table"
///
/// // Change clothing
/// prompt: "red business suit"
/// ```
///
/// ## Best Practices
///
/// - **Mask precision**: Clean masks produce better results
/// - **Prompt clarity**: Describe what should appear, not what to remove
/// - **Context**: Include surrounding context in prompts
/// - **Size match**: Image and mask must have identical dimensions
///
/// - Important: Only available for DALL·E 2
/// - Note: Only PNG images are supported for both image and mask.
public struct ImageEditRequest: Sendable {
    /// The image data to edit.
    ///
    /// Must be a valid PNG image with dimensions that match the mask (if provided).
    /// Maximum file size is 4MB.
    public let image: Data
    
    /// The filename for the image.
    ///
    /// Should include the .png extension, e.g., "image.png".
    public let imageName: String
    
    /// A text description of the desired edits.
    ///
    /// Be specific about what changes you want to make to the image.
    ///
    /// - Example: "Replace the car with a bicycle"
    /// - Example: "Change the sky to a sunset with orange and pink colors"
    public let prompt: String
    
    /// An optional mask image data.
    ///
    /// The mask specifies which areas of the image to edit.
    /// Transparent pixels (alpha = 0) will be edited, opaque pixels will be preserved.
    /// Must be a PNG image with the same dimensions as the main image.
    public let mask: Data?
    
    /// The filename for the mask image.
    ///
    /// Should include the .png extension, e.g., "mask.png".
    /// Required if mask data is provided.
    public let maskName: String?
    
    /// The model to use for image editing.
    ///
    /// Currently only supports "dall-e-2".
    public let model: String?
    
    /// The number of edited images to generate.
    ///
    /// Must be between 1 and 10. Defaults to 1.
    public let n: Int?
    
    /// The size of the edited images.
    ///
    /// Must be one of: `"256x256"`, `"512x512"`, or `"1024x1024"`.
    /// Defaults to the size of the input image.
    public let size: String?
    
    /// The format in which the edited images are returned.
    ///
    /// - SeeAlso: ``ImageResponseFormat``
    public let responseFormat: ImageResponseFormat?
    
    /// A unique identifier representing your end-user.
    ///
    /// This can help OpenAI monitor and detect abuse.
    public let user: String?
    
    /// Creates a new image edit request.
    ///
    /// - Parameters:
    ///   - image: The PNG image data to edit (max 4MB)
    ///   - imageName: Filename for the image (e.g., "image.png")
    ///   - prompt: Text description of the desired edits
    ///   - mask: Optional PNG mask data indicating areas to edit
    ///   - maskName: Filename for the mask (required if mask is provided)
    ///   - model: The model to use (currently only "dall-e-2")
    ///   - n: Number of edited images to generate (1-10)
    ///   - size: Size of the output images
    ///   - responseFormat: Format for the response (URL or base64)
    ///   - user: Unique identifier for the end-user
    ///
    /// - Throws: The endpoint may throw errors for:
    ///   - Invalid image format (only PNG supported)
    ///   - Image size exceeding 4MB
    ///   - Mismatched image and mask dimensions
    ///   - Invalid size specifications
    public init(
        image: Data,
        imageName: String,
        prompt: String,
        mask: Data? = nil,
        maskName: String? = nil,
        model: String? = nil,
        n: Int? = nil,
        size: String? = nil,
        responseFormat: ImageResponseFormat? = nil,
        user: String? = nil
    ) {
        self.image = image
        self.imageName = imageName
        self.prompt = prompt
        self.mask = mask
        self.maskName = maskName
        self.model = model
        self.n = n
        self.size = size
        self.responseFormat = responseFormat
        self.user = user
    }
}

/// A request to create variations of an existing image.
///
/// Image variations generate new images that maintain the same general composition
/// and style as the input image but with creative differences.
///
/// ## Example
/// ```swift
/// let imageData = try Data(contentsOf: imageURL)
/// 
/// let request = ImageVariationRequest(
///     image: imageData,
///     imageName: "original.png",
///     n: 3,
///     size: "512x512"
/// )
/// ```
///
/// - Note: This endpoint is useful for exploring different artistic interpretations
/// of an existing image while maintaining its core elements.
public struct ImageVariationRequest: Sendable {
    /// The source image data to create variations from.
    ///
    /// Must be a valid PNG image. The variations will maintain the general
    /// style and composition of this image.
    /// Maximum file size is 4MB.
    public let image: Data
    
    /// The filename for the image.
    ///
    /// Should include the .png extension, e.g., "source.png".
    public let imageName: String
    
    /// The model to use for creating variations.
    ///
    /// Currently only supports "dall-e-2".
    public let model: String?
    
    /// The number of image variations to generate.
    ///
    /// Must be between 1 and 10. Defaults to 1.
    /// Each variation will be a unique interpretation of the original.
    public let n: Int?
    
    /// The format in which the generated variations are returned.
    ///
    /// - SeeAlso: ``ImageResponseFormat``
    public let responseFormat: ImageResponseFormat?
    
    /// The size of the generated variations.
    ///
    /// Must be one of: `"256x256"`, `"512x512"`, or `"1024x1024"`.
    /// Defaults to the size of the input image.
    public let size: String?
    
    /// A unique identifier representing your end-user.
    ///
    /// This can help OpenAI monitor and detect abuse.
    public let user: String?
    
    /// Creates a new image variation request.
    ///
    /// - Parameters:
    ///   - image: The PNG image data to create variations from (max 4MB)
    ///   - imageName: Filename for the image (e.g., "original.png")
    ///   - model: The model to use (currently only "dall-e-2")
    ///   - n: Number of variations to generate (1-10)
    ///   - responseFormat: Format for the response (URL or base64)
    ///   - size: Size of the output images
    ///   - user: Unique identifier for the end-user
    ///
    /// - Throws: The endpoint may throw errors for:
    ///   - Invalid image format (only PNG supported)
    ///   - Image size exceeding 4MB
    ///   - Invalid size specifications
    public init(
        image: Data,
        imageName: String,
        model: String? = nil,
        n: Int? = nil,
        responseFormat: ImageResponseFormat? = nil,
        size: String? = nil,
        user: String? = nil
    ) {
        self.image = image
        self.imageName = imageName
        self.model = model
        self.n = n
        self.responseFormat = responseFormat
        self.size = size
        self.user = user
    }
}

/// The response from any image generation, edit, or variation request.
///
/// Contains an array of generated images along with metadata about the request.
///
/// ## Example
/// ```swift
/// let response = try await openAI.images.generations(request)
/// 
/// for image in response.data {
///     if let url = image.url {
///         // Download image from URL
///         let imageData = try await URLSession.shared.data(from: URL(string: url)!).0
///     } else if let base64 = image.b64Json {
///         // Decode base64 image
///         let imageData = Data(base64Encoded: base64)!
///     }
/// }
/// ```
public struct ImageResponse: Codable, Sendable {
    /// Unix timestamp (in seconds) when the images were created.
    public let created: Int
    
    /// Array of generated image objects.
    ///
    /// Each object contains either a URL or base64-encoded image data,
    /// depending on the requested response format.
    public let data: [ImageObject]
    
    /// Token usage information for the request.
    ///
    /// Only present for certain models that track token usage.
    public let usage: ImageUsage?
    
    // MARK: - gpt-image-1 specific fields
    
    /// Background setting used for the image (gpt-image-1 only).
    public let background: String?
    
    /// Output format of the generated image (gpt-image-1 only).
    public let outputFormat: String?
    
    /// Quality level used for generation (gpt-image-1 only).
    public let quality: String?
    
    /// Size of the generated image (gpt-image-1 only).
    public let size: String?
    
    private enum CodingKeys: String, CodingKey {
        case created
        case data
        case usage
        case background
        case outputFormat = "output_format"
        case quality
        case size
    }
}

/// Represents a single generated, edited, or varied image.
///
/// Contains either a URL to the image or the image data as a base64-encoded string,
/// depending on the requested response format.
///
/// ## Accessing Image Data
/// ```swift
/// if let url = imageObject.url {
///     // Image is available at this temporary URL
///     let imageURL = URL(string: url)!
/// } else if let base64String = imageObject.b64Json {
///     // Image is embedded as base64
///     let imageData = Data(base64Encoded: base64String)!
/// }
/// ```
public struct ImageObject: Codable, Sendable {
    /// URL of the generated image.
    ///
    /// Present when response format is `.url`.
    /// These URLs are temporary and typically expire after 1 hour.
    public let url: String?
    
    /// Base64-encoded JSON string of the image.
    ///
    /// Present when response format is `.b64Json`.
    /// Decode this string to get the raw image data.
    public let b64Json: String?
    
    /// The revised prompt used to generate the image.
    ///
    /// DALL·E 3 may revise prompts for safety or clarity.
    /// This field shows the actual prompt used if it was modified.
    public let revisedPrompt: String?
    
    private enum CodingKeys: String, CodingKey {
        case url
        case b64Json = "b64_json"
        case revisedPrompt = "revised_prompt"
    }
}

/// Token usage information for image generation requests.
///
/// Tracks the number of tokens used in processing the text prompt.
/// This is primarily relevant for models that perform token-based billing.
public struct ImageUsage: Codable, Sendable {
    /// Total number of tokens used.
    public let totalTokens: Int?
    
    /// The number of tokens used for the input.
    public let inputTokens: Int?
    
    /// The number of tokens used for the output.
    public let outputTokens: Int?
    
    /// Detailed breakdown of input tokens.
    public let inputTokensDetails: InputTokensDetails?
    
    /// The number of tokens used to process the prompt (legacy field).
    ///
    /// This helps track usage for billing and rate limiting purposes.
    public let promptTokens: Int?
    
    /// Detailed breakdown of input token usage.
    public struct InputTokensDetails: Codable, Sendable {
        /// Tokens used for text input.
        public let textTokens: Int?
        
        /// Tokens used for image input.
        public let imageTokens: Int?
        
        private enum CodingKeys: String, CodingKey {
            case textTokens = "text_tokens"
            case imageTokens = "image_tokens"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case inputTokensDetails = "input_tokens_details"
        case promptTokens = "prompt_tokens"
    }
}