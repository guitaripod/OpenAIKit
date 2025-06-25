import Foundation

/// Provides access to OpenAI's Moderation API endpoint.
///
/// The `ModerationsEndpoint` class enables content moderation to identify potentially harmful
/// content in text and images. Use this endpoint to ensure your applications comply with
/// content policies and maintain safe user experiences.
///
/// ## Overview
///
/// The moderation endpoint helps detect content that may violate OpenAI's usage policies
/// across various categories including:
/// - Harassment and hate speech
/// - Violence and graphic content
/// - Self-harm content
/// - Sexual content
/// - Illegal activities
///
/// ## Example
///
/// ```swift
/// let client = OpenAI(apiKey: "your-api-key")
/// 
/// // Simple text moderation
/// let request = ModerationRequest(input: "Some text to check")
/// let response = try await client.moderations.create(request)
/// 
/// if response.results.first?.flagged == true {
///     print("Content was flagged")
///     
///     // Check specific categories
///     let categories = response.results.first?.categories
///     if categories?.violence == true {
///         print("Violence detected")
///     }
/// }
/// 
/// // Batch moderation
/// let batchRequest = ModerationRequest(
///     input: ["Text 1", "Text 2", "Text 3"],
///     model: "text-moderation-latest"
/// )
/// let batchResponse = try await client.moderations.create(batchRequest)
/// 
/// // Multimodal moderation
/// let multimodalRequest = ModerationRequest(
///     input: .multimodal([
///         ModerationContent(type: .text, text: "Check this text"),
///         ModerationContent(type: .imageUrl, imageUrl: ImageURL(url: "https://example.com/image.jpg"))
///     ]),
///     model: "omni-moderation-latest"
/// )
/// ```
///
/// ## Topics
///
/// ### Creating Moderations
/// - ``create(_:)``
public final class ModerationsEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Classifies content for potential policy violations.
    ///
    /// This method analyzes the provided content and returns detailed information about
    /// any potential violations across multiple categories. Each category includes both
    /// a boolean flag and a confidence score.
    ///
    /// - Parameter request: A ``ModerationRequest`` containing the content to moderate.
    /// - Returns: A ``ModerationResponse`` with moderation results for each input.
    /// - Throws: An error if the request fails or if there are authentication issues.
    ///
    /// ## Usage Guidelines
    ///
    /// - The moderation endpoint is free to use
    /// - Results include both binary flags and confidence scores
    /// - Different thresholds are used for different categories
    /// - For production use, consider caching results for identical inputs
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Create a moderation request
    /// let request = ModerationRequest(
    ///     input: "User-generated content to check",
    ///     model: "text-moderation-latest"
    /// )
    /// 
    /// // Get moderation results
    /// let response = try await client.moderations.create(request)
    /// 
    /// // Process results
    /// for result in response.results {
    ///     if result.flagged {
    ///         // Handle flagged content
    ///         print("Content flagged in categories:")
    ///         
    ///         let scores = result.categoryScores
    ///         if result.categories.harassment {
    ///             print("- Harassment (score: \(scores.harassment))")
    ///         }
    ///         if result.categories.violence {
    ///             print("- Violence (score: \(scores.violence))")
    ///         }
    ///     }
    /// }
    /// ```
    public func create(_ request: ModerationRequest) async throws -> ModerationResponse {
        let apiRequest = ModerationAPIRequest(request: request)
        return try await networkClient.execute(apiRequest)
    }
}

private struct ModerationAPIRequest: Request {
    typealias Body = ModerationRequest
    typealias Response = ModerationResponse
    
    let path = "moderations"
    let method: HTTPMethod = .post
    let body: ModerationRequest?
    
    init(request: ModerationRequest) {
        self.body = request
    }
}