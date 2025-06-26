// ErrorHandling.swift - Handling specific errors
import Foundation
import OpenAIKit

func sendChatMessage(_ message: String) async -> Result<String, ChatError> {
    guard let openAI = OpenAIManager.shared.client else {
        return .failure(.clientNotInitialized)
    }
    
    let request = ChatCompletionRequest(
        messages: [ChatMessage(role: .user, content: message)],
        model: "gpt-4o-mini"
    )
    
    do {
        let response = try await openAI.chat.completions(request)
        guard let content = response.choices.first?.message.content else {
            return .failure(.noContent)
        }
        return .success(content)
    } catch let error as APIError {
        // Handle API errors
        return .failure(.apiError(error))
    } catch {
        // Handle other errors
        return .failure(.networkError(error))
    }
}

enum ChatError: LocalizedError {
    case clientNotInitialized
    case noContent
    case apiError(APIError)
    case networkError(Error)
    case rateLimitExceeded
    case invalidRequest(String)
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "OpenAI client is not initialized"
        case .noContent:
            return "No content in response"
        case .apiError(let error):
            return "API Error: \(error.error.message)"
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        }
    }
}