import Foundation

/// Provides access to OpenAI's Models API endpoints.
///
/// The `ModelsEndpoint` class offers methods to list available models, retrieve specific model details,
/// and delete fine-tuned models. This endpoint is essential for discovering which models are available
/// for use with various OpenAI services.
///
/// ## Overview
///
/// Use the models endpoint to:
/// - List all available models in your organization
/// - Get detailed information about a specific model
/// - Delete fine-tuned models you no longer need
///
/// ## Example
///
/// ```swift
/// let client = OpenAI(apiKey: "your-api-key")
/// 
/// // List all available models
/// let models = try await client.models.list()
/// for model in models.data {
///     print("Available model: \(model.id)")
/// }
/// 
/// // Get details about a specific model
/// let gpt4 = try await client.models.retrieve(model: "gpt-4")
/// print("GPT-4 created at: \(gpt4.created)")
/// 
/// // Delete a fine-tuned model
/// let deletion = try await client.models.delete(model: "ft:gpt-3.5-turbo:my-org:custom:id")
/// print("Deleted: \(deletion.deleted)")
/// ```
///
/// ## Topics
///
/// ### Listing Models
/// - ``list()``
///
/// ### Retrieving Model Details
/// - ``retrieve(model:)``
///
/// ### Managing Fine-Tuned Models
/// - ``delete(model:)``
public final class ModelsEndpoint: Sendable {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Lists all models available to your organization.
    ///
    /// This method returns a list of all models that your API key has access to,
    /// including both OpenAI's base models and any fine-tuned models created by your organization.
    ///
    /// - Returns: A ``ModelsResponse`` containing an array of available models.
    /// - Throws: An error if the request fails or if there are authentication issues.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let response = try await client.models.list()
    /// let gptModels = response.data.filter { $0.id.contains("gpt") }
    /// print("Found \(gptModels.count) GPT models")
    /// ```
    public func list() async throws -> ModelsResponse {
        let request = ListModelsRequest()
        return try await networkClient.execute(request)
    }
    
    /// Retrieves detailed information about a specific model.
    ///
    /// Use this method to get comprehensive details about a model, including its creation date,
    /// ownership, and other metadata.
    ///
    /// - Parameter model: The ID of the model to retrieve (e.g., "gpt-4", "gpt-3.5-turbo").
    /// - Returns: A ``Model`` object containing the model's details.
    /// - Throws: An error if the model doesn't exist or if there are authentication issues.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let modelInfo = try await client.models.retrieve(model: "text-davinci-003")
    /// print("Model owned by: \(modelInfo.ownedBy)")
    /// print("Created: \(Date(timeIntervalSince1970: TimeInterval(modelInfo.created)))")
    /// ```
    public func retrieve(model: String) async throws -> Model {
        let request = RetrieveModelRequest(model: model)
        return try await networkClient.execute(request)
    }
    
    /// Deletes a fine-tuned model.
    ///
    /// This method allows you to delete fine-tuned models that belong to your organization.
    /// You cannot delete OpenAI's base models.
    ///
    /// - Parameter model: The ID of the fine-tuned model to delete.
    /// - Returns: A ``DeletionResponse`` confirming the deletion.
    /// - Throws: An error if the model cannot be deleted or doesn't exist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = try await client.models.delete(model: "ft:gpt-3.5-turbo:my-org:classifier:abc123")
    /// if result.deleted {
    ///     print("Successfully deleted model: \(result.id)")
    /// }
    /// ```
    ///
    /// - Important: Only fine-tuned models can be deleted. Attempting to delete a base model
    ///   will result in an error.
    public func delete(model: String) async throws -> DeletionResponse {
        let request = DeleteModelRequest(model: model)
        return try await networkClient.execute(request)
    }
}

private struct ListModelsRequest: Request {
    typealias Body = EmptyBody
    typealias Response = ModelsResponse
    
    let path = "models"
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
}

private struct RetrieveModelRequest: Request {
    typealias Body = EmptyBody
    typealias Response = Model
    
    let path: String
    let method: HTTPMethod = .get
    let body: EmptyBody? = nil
    
    init(model: String) {
        self.path = "models/\(model)"
    }
}

private struct DeleteModelRequest: Request {
    typealias Body = EmptyBody
    typealias Response = DeletionResponse
    
    let path: String
    let method: HTTPMethod = .delete
    let body: EmptyBody? = nil
    
    init(model: String) {
        self.path = "models/\(model)"
    }
}