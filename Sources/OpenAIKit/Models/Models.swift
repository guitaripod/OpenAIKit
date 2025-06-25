import Foundation

/// Represents an OpenAI model with its metadata.
///
/// The `Model` struct contains information about a specific model available in the OpenAI API,
/// including its identifier, creation timestamp, and ownership details.
///
/// ## Topics
///
/// ### Model Information
/// - ``id``
/// - ``object``
/// - ``created``
/// - ``ownedBy``
public struct Model: Codable, Sendable {
    /// The unique identifier for the model.
    ///
    /// Common model IDs include:
    /// - `gpt-4-turbo-preview`
    /// - `gpt-4`
    /// - `gpt-3.5-turbo`
    /// - `text-embedding-ada-002`
    /// - `whisper-1`
    /// - `dall-e-3`
    public let id: String
    
    /// The object type, which is always "model".
    public let object: String
    
    /// The Unix timestamp (in seconds) when the model was created.
    public let created: Int
    
    /// The organization that owns the model.
    ///
    /// Typically "openai" for OpenAI models, "system" for built-in models,
    /// or a custom organization ID for fine-tuned models.
    public let ownedBy: String
}

/// Represents the response from the models list endpoint.
///
/// This response contains an array of available models along with metadata about the response.
///
/// ## Example
///
/// ```swift
/// let client = OpenAI(apiKey: "your-api-key")
/// let response = try await client.models.list()
/// 
/// for model in response.data {
///     print("Model: \(model.id), owned by: \(model.ownedBy)")
/// }
/// ```
///
/// ## Topics
///
/// ### Response Properties
/// - ``object``
/// - ``data``
public struct ModelsResponse: Codable, Sendable {
    /// The object type, which is always "list".
    public let object: String
    
    /// The list of available models.
    ///
    /// Each model in the array contains information about its capabilities,
    /// ownership, and creation date.
    public let data: [Model]
}