import Foundation

/// A request to the OpenAI Moderation API.
///
/// The moderation endpoint helps you identify potentially harmful content in text and images.
/// It's useful for content filtering, community guidelines enforcement, and ensuring safe AI interactions.
///
/// ## Example
///
/// ```swift
/// // Simple text moderation
/// let request = ModerationRequest(input: "I want to hurt someone")
/// let response = try await client.moderations.create(request)
/// 
/// if response.results.first?.flagged == true {
///     print("Content flagged as potentially harmful")
/// }
/// 
/// // Batch text moderation
/// let batchRequest = ModerationRequest(
///     input: ["Text 1", "Text 2", "Text 3"],
///     model: "text-moderation-latest"
/// )
/// ```
///
/// ## Topics
///
/// ### Creating Requests
/// - ``init(input:model:)``
/// - ``init(input:model:)-5jyjo``
/// - ``init(input:model:)-7fbnw``
///
/// ### Request Properties
/// - ``input``
/// - ``model``
public struct ModerationRequest: Codable, Sendable {
    /// The input content to classify.
    ///
    /// Can be a single string, an array of strings, or multimodal content
    /// containing both text and images.
    public let input: ModerationInput
    
    /// The model to use for moderation.
    ///
    /// Available models:
    /// - `text-moderation-latest` (default): Most capable moderation model
    /// - `text-moderation-stable`: Stable version with consistent behavior
    /// - `omni-moderation-latest`: Multimodal model for text and images
    public let model: String?
    
    /// Creates a moderation request with flexible input types.
    ///
    /// - Parameters:
    ///   - input: The content to moderate as a ``ModerationInput``.
    ///   - model: The model to use. Defaults to nil (uses API default).
    public init(input: ModerationInput, model: String? = nil) {
        self.input = input
        self.model = model
    }
    
    /// Creates a moderation request for a single text string.
    ///
    /// - Parameters:
    ///   - input: The text content to moderate.
    ///   - model: The model to use. Defaults to nil (uses API default).
    public init(input: String, model: String? = nil) {
        self.init(input: .string(input), model: model)
    }
    
    /// Creates a moderation request for multiple text strings.
    ///
    /// - Parameters:
    ///   - input: An array of text content to moderate.
    ///   - model: The model to use. Defaults to nil (uses API default).
    public init(input: [String], model: String? = nil) {
        self.init(input: .array(input), model: model)
    }
}

/// Represents different types of input for moderation.
///
/// The moderation API accepts single strings, arrays of strings, or multimodal content
/// containing both text and images.
///
/// ## Example
///
/// ```swift
/// // Single string
/// let input1 = ModerationInput.string("Check this text")
/// 
/// // Multiple strings
/// let input2 = ModerationInput.array(["Text 1", "Text 2"])
/// 
/// // Multimodal content
/// let input3 = ModerationInput.multimodal([
///     ModerationContent(type: .text, text: "Describe this image"),
///     ModerationContent(type: .imageUrl, imageUrl: ImageURL(url: "https://example.com/image.jpg"))
/// ])
/// ```
public enum ModerationInput: Codable, Sendable {
    /// A single text string to moderate.
    case string(String)
    
    /// An array of text strings to moderate in batch.
    case array([String])
    
    /// Multimodal content containing text and/or images.
    case multimodal([ModerationContent])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else if let multimodal = try? container.decode([ModerationContent].self) {
            self = .multimodal(multimodal)
        } else {
            throw DecodingError.typeMismatch(
                ModerationInput.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String, [String], or [ModerationContent]")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .multimodal(let multimodal):
            try container.encode(multimodal)
        }
    }
}

/// Represents a piece of content for multimodal moderation.
///
/// Used when moderating content that contains both text and images.
/// Each content item must specify its type and provide the appropriate content.
///
/// ## Example
///
/// ```swift
/// // Text content
/// let textContent = ModerationContent(type: .text, text: "Check this text")
/// 
/// // Image content
/// let imageContent = ModerationContent(
///     type: .imageUrl,
///     imageUrl: ImageURL(url: "https://example.com/image.jpg")
/// )
/// ```
public struct ModerationContent: Codable, Sendable {
    /// The type of content (text or image).
    public let type: ModerationContentType
    
    /// The text content, required when type is `.text`.
    public let text: String?
    
    /// The image URL, required when type is `.imageUrl`.
    public let imageUrl: ImageURL?
    
    /// Creates a moderation content item.
    ///
    /// - Parameters:
    ///   - type: The type of content.
    ///   - text: The text content (required for text type).
    ///   - imageUrl: The image URL (required for image type).
    public init(type: ModerationContentType, text: String? = nil, imageUrl: ImageURL? = nil) {
        self.type = type
        self.text = text
        self.imageUrl = imageUrl
    }
}

/// The type of content in a moderation request.
///
/// Specifies whether the content is text or an image URL.
public enum ModerationContentType: String, Codable, Sendable {
    /// Text content to be moderated.
    case text
    
    /// Image content specified by URL.
    case imageUrl = "image_url"
}

/// The response from the Moderation API.
///
/// Contains the moderation results for each input provided in the request.
/// Each result indicates whether content was flagged and provides detailed
/// category scores.
///
/// ## Example
///
/// ```swift
/// let response = try await client.moderations.create(request)
/// 
/// for (index, result) in response.results.enumerated() {
///     if result.flagged {
///         print("Input \(index) was flagged")
///         
///         // Check specific categories
///         if result.categories.violence {
///             print("Violence detected with score: \(result.categoryScores.violence)")
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Response Properties
/// - ``id``
/// - ``model``
/// - ``results``
public struct ModerationResponse: Codable, Sendable {
    /// Unique identifier for the moderation request.
    public let id: String
    
    /// The model used for moderation.
    public let model: String
    
    /// Array of moderation results, one for each input.
    public let results: [ModerationResult]
}

/// The moderation result for a single input.
///
/// Contains whether the content was flagged as potentially harmful,
/// along with detailed category classifications and confidence scores.
///
/// ## Topics
///
/// ### Result Properties
/// - ``flagged``
/// - ``categories``
/// - ``categoryScores``
/// - ``categoryAppliedInputTypes``
public struct ModerationResult: Codable, Sendable {
    /// Whether the content was flagged as potentially violating OpenAI's usage policies.
    ///
    /// If true, at least one moderation category was triggered.
    public let flagged: Bool
    
    /// Boolean flags for each moderation category.
    ///
    /// Each property indicates whether the content violates that specific category.
    public let categories: ModerationCategories
    
    /// Confidence scores for each moderation category.
    ///
    /// Scores range from 0.0 to 1.0, with higher values indicating
    /// higher confidence that the content violates the category.
    public let categoryScores: ModerationCategoryScores
    
    /// For multimodal inputs, indicates which input types triggered each category.
    ///
    /// Only present when using multimodal moderation models.
    public let categoryAppliedInputTypes: ModerationAppliedInputTypes?
}

/// Boolean flags indicating which moderation categories were triggered.
///
/// Each property represents a specific type of potentially harmful content.
/// A value of `true` indicates the content was flagged for that category.
///
/// ## Categories
///
/// - **Harassment**: Content that expresses, incites, or promotes harassing language towards any target.
/// - **Hate**: Content that expresses, incites, or promotes hate based on identity.
/// - **Illicit**: Content that includes instructions or advice related to illegal activities.
/// - **Self-harm**: Content that promotes, encourages, or depicts acts of self-harm.
/// - **Sexual**: Content meant to arouse sexual excitement or promote sexual services.
/// - **Violence**: Content that depicts death, violence, or physical injury.
///
/// ## Example
///
/// ```swift
/// if result.categories.harassment || result.categories.harassmentThreatening {
///     print("Content contains harassment")
/// }
/// ```
public struct ModerationCategories: Codable, Sendable {
    /// Content that expresses, incites, or promotes harassing language.
    public let harassment: Bool
    
    /// Harassment content that includes violence or serious harm.
    public let harassmentThreatening: Bool
    
    /// Content that expresses, incites, or promotes hate based on identity.
    public let hate: Bool
    
    /// Hateful content that includes violence or serious harm.
    public let hateThreatening: Bool
    
    /// Content that includes instructions for illegal activities.
    public let illicit: Bool
    
    /// Illicit content that includes violence or serious harm.
    public let illicitViolent: Bool
    
    /// Content that promotes, encourages, or depicts acts of self-harm.
    public let selfHarm: Bool
    
    /// Content where the speaker expresses intent to engage in self-harm.
    public let selfHarmIntent: Bool
    
    /// Content that provides instructions for self-harm activities.
    public let selfHarmInstructions: Bool
    
    /// Content meant to arouse sexual excitement or promote sexual services.
    public let sexual: Bool
    
    /// Sexual content involving individuals under 18 years old.
    public let sexualMinors: Bool
    
    /// Content that depicts death, violence, or physical injury.
    public let violence: Bool
    
    /// Violent content that depicts death, gore, or extreme injury in graphic detail.
    public let violenceGraphic: Bool
    
    private enum CodingKeys: String, CodingKey {
        case harassment
        case harassmentThreatening = "harassment/threatening"
        case hate
        case hateThreatening = "hate/threatening"
        case illicit
        case illicitViolent = "illicit/violent"
        case selfHarm = "self-harm"
        case selfHarmIntent = "self-harm/intent"
        case selfHarmInstructions = "self-harm/instructions"
        case sexual
        case sexualMinors = "sexual/minors"
        case violence
        case violenceGraphic = "violence/graphic"
    }
}

/// Confidence scores for each moderation category.
///
/// Scores range from 0.0 to 1.0, where higher values indicate greater confidence
/// that the content violates the category. The threshold for flagging content
/// varies by category.
///
/// ## Example
///
/// ```swift
/// // Check if content has high violence score
/// if result.categoryScores.violence > 0.8 {
///     print("High confidence of violent content")
/// }
/// 
/// // Find the highest scoring category
/// let scores = [
///     ("harassment", result.categoryScores.harassment),
///     ("hate", result.categoryScores.hate),
///     ("violence", result.categoryScores.violence)
///     // ... other categories
/// ]
/// 
/// if let highest = scores.max(by: { $0.1 < $1.1 }) {
///     print("Highest risk category: \(highest.0) with score \(highest.1)")
/// }
/// ```
public struct ModerationCategoryScores: Codable, Sendable {
    /// Confidence score for harassment content (0.0-1.0).
    public let harassment: Double
    
    /// Confidence score for threatening harassment (0.0-1.0).
    public let harassmentThreatening: Double
    
    /// Confidence score for hate content (0.0-1.0).
    public let hate: Double
    
    /// Confidence score for threatening hate content (0.0-1.0).
    public let hateThreatening: Double
    
    /// Confidence score for illicit content (0.0-1.0).
    public let illicit: Double
    
    /// Confidence score for violent illicit content (0.0-1.0).
    public let illicitViolent: Double
    
    /// Confidence score for self-harm content (0.0-1.0).
    public let selfHarm: Double
    
    /// Confidence score for self-harm intent (0.0-1.0).
    public let selfHarmIntent: Double
    
    /// Confidence score for self-harm instructions (0.0-1.0).
    public let selfHarmInstructions: Double
    
    /// Confidence score for sexual content (0.0-1.0).
    public let sexual: Double
    
    /// Confidence score for sexual content involving minors (0.0-1.0).
    public let sexualMinors: Double
    
    /// Confidence score for violent content (0.0-1.0).
    public let violence: Double
    
    /// Confidence score for graphic violence (0.0-1.0).
    public let violenceGraphic: Double
    
    private enum CodingKeys: String, CodingKey {
        case harassment
        case harassmentThreatening = "harassment/threatening"
        case hate
        case hateThreatening = "hate/threatening"
        case illicit
        case illicitViolent = "illicit/violent"
        case selfHarm = "self-harm"
        case selfHarmIntent = "self-harm/intent"
        case selfHarmInstructions = "self-harm/instructions"
        case sexual
        case sexualMinors = "sexual/minors"
        case violence
        case violenceGraphic = "violence/graphic"
    }
}

/// For multimodal moderation, indicates which input types triggered each category.
///
/// When moderating multimodal content (text and images), this structure shows
/// which types of input ("text" or "image") contributed to flagging each category.
///
/// ## Example
///
/// ```swift
/// if let appliedTypes = result.categoryAppliedInputTypes {
///     if appliedTypes.violence.contains("image") {
///         print("Violence detected in image content")
///     }
///     if appliedTypes.harassment.contains("text") {
///         print("Harassment detected in text content")
///     }
/// }
/// ```
public struct ModerationAppliedInputTypes: Codable, Sendable {
    /// Input types that triggered harassment category.
    public let harassment: [String]
    
    /// Input types that triggered threatening harassment.
    public let harassmentThreatening: [String]
    
    /// Input types that triggered hate category.
    public let hate: [String]
    
    /// Input types that triggered threatening hate.
    public let hateThreatening: [String]
    
    /// Input types that triggered illicit category.
    public let illicit: [String]
    
    /// Input types that triggered violent illicit content.
    public let illicitViolent: [String]
    
    /// Input types that triggered self-harm category.
    public let selfHarm: [String]
    
    /// Input types that triggered self-harm intent.
    public let selfHarmIntent: [String]
    
    /// Input types that triggered self-harm instructions.
    public let selfHarmInstructions: [String]
    
    /// Input types that triggered sexual category.
    public let sexual: [String]
    
    /// Input types that triggered sexual minors category.
    public let sexualMinors: [String]
    
    /// Input types that triggered violence category.
    public let violence: [String]
    
    /// Input types that triggered graphic violence.
    public let violenceGraphic: [String]
    
    private enum CodingKeys: String, CodingKey {
        case harassment
        case harassmentThreatening = "harassment/threatening"
        case hate
        case hateThreatening = "hate/threatening"
        case illicit
        case illicitViolent = "illicit/violent"
        case selfHarm = "self-harm"
        case selfHarmIntent = "self-harm/intent"
        case selfHarmInstructions = "self-harm/instructions"
        case sexual
        case sexualMinors = "sexual/minors"
        case violence
        case violenceGraphic = "violence/graphic"
    }
}