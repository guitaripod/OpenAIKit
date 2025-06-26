import Foundation

/// A request to generate one or more images from a text prompt.
///
/// The image generation endpoint allows you to create original images based on text descriptions.
/// You can control various aspects of the generated images including size, style, quality, and format.
///
/// ## Example
/// ```swift
/// let request = ImageGenerationRequest(
///     prompt: "A serene landscape with mountains and a lake at sunset",
///     model: "dall-e-3",
///     size: "1024x1024",
///     quality: "hd",
///     style: "natural"
/// )
/// ```
///
/// - Important: The `prompt` parameter is required and should be descriptive.
/// Longer, more detailed prompts generally produce better results.
public struct ImageGenerationRequest: Codable, Sendable {
    /// The text prompt describing the desired image(s).
    ///
    /// This is the primary input that guides the image generation.
    /// Be specific and descriptive for best results.
    ///
    /// - Example: "A futuristic city skyline at night with flying cars"
    public let prompt: String
    
    /// The background setting for the generated image.
    ///
    /// Controls the background context or environment of the generated image.
    public let background: String?
    
    /// The model to use for image generation.
    ///
    /// Available models:
    /// - `"dall-e-2"`: Standard DALL·E 2 model
    /// - `"dall-e-3"`: Latest DALL·E 3 model with improved quality and coherence
    ///
    /// Defaults to `"dall-e-2"` if not specified.
    public let model: String?
    
    /// Content moderation level for the generated images.
    ///
    /// Controls the strictness of content filtering applied to the output.
    public let moderation: String?
    
    /// The number of images to generate.
    ///
    /// - For DALL·E 2: Must be between 1 and 10
    /// - For DALL·E 3: Only 1 is supported
    ///
    /// Defaults to 1 if not specified.
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
    /// Available options:
    /// - `"standard"`: Standard quality (faster)
    /// - `"hd"`: High definition quality (slower, DALL·E 3 only)
    ///
    /// Defaults to `"standard"` if not specified.
    public let quality: String?
    
    /// The format in which the generated images are returned.
    ///
    /// - SeeAlso: ``ImageResponseFormat``
    public let responseFormat: ImageResponseFormat?
    
    /// The size of the generated images.
    ///
    /// Available sizes:
    /// - DALL·E 2: `"256x256"`, `"512x512"`, `"1024x1024"`
    /// - DALL·E 3: `"1024x1024"`, `"1792x1024"`, `"1024x1792"`
    ///
    /// Defaults to `"1024x1024"` if not specified.
    public let size: String?
    
    /// The style of the generated images.
    ///
    /// Available styles for DALL·E 3:
    /// - `"vivid"`: More hyper-real and dramatic images
    /// - `"natural"`: More natural, less hyper-real looking images
    ///
    /// This parameter is only supported for DALL·E 3.
    public let style: String?
    
    /// A unique identifier representing your end-user.
    ///
    /// This can help OpenAI monitor and detect abuse.
    public let user: String?
    
    /// Creates a new image generation request.
    ///
    /// - Parameters:
    ///   - prompt: The text description of the desired image(s)
    ///   - background: Optional background setting for the image
    ///   - model: The model to use (e.g., "dall-e-2", "dall-e-3")
    ///   - moderation: Content moderation level
    ///   - n: Number of images to generate (1-10 for DALL·E 2, only 1 for DALL·E 3)
    ///   - outputCompression: Compression level for output images
    ///   - outputFormat: Output image format (e.g., "png", "jpg")
    ///   - quality: Image quality ("standard" or "hd")
    ///   - responseFormat: Format for the response (URL or base64)
    ///   - size: Size of generated images
    ///   - style: Style preset ("vivid" or "natural", DALL·E 3 only)
    ///   - user: Unique identifier for the end-user
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
}

/// The format in which generated images are returned.
///
/// This enum determines whether images are returned as URLs or as base64-encoded JSON strings.
///
/// ## Usage Considerations
/// - Use `.url` when you want to download images separately or display them directly in web contexts
/// - Use `.b64Json` when you need the image data immediately embedded in the response
///
/// - Note: URLs are temporary and will expire after a short period (typically 1 hour)
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
/// Image editing allows you to modify specific parts of an image by providing
/// a text description of the desired changes. You can optionally provide a mask
/// to specify which areas of the image should be edited.
///
/// ## Example
/// ```swift
/// let imageData = try Data(contentsOf: imageURL)
/// let maskData = try Data(contentsOf: maskURL)
/// 
/// let request = ImageEditRequest(
///     image: imageData,
///     imageName: "landscape.png",
///     prompt: "Add a rainbow in the sky",
///     mask: maskData,
///     maskName: "sky-mask.png",
///     size: "1024x1024"
/// )
/// ```
///
/// ## Mask Usage
/// The mask should be a PNG image where:
/// - Fully transparent areas (alpha = 0) indicate regions to edit
/// - Opaque areas (alpha = 1) indicate regions to preserve
///
/// - Important: Both the image and mask must have the same dimensions.
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
    }
}