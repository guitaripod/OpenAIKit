// Circuit breaker pattern
import Foundation

actor CircuitBreaker {
    enum State {
        case closed
        case open(until: Date)
        case halfOpen
    }
    
    private var state: State = .closed
    private var failureCount = 0
    private let failureThreshold: Int
    private let timeout: TimeInterval
    private let successThreshold: Int
    private var successCount = 0
    
    init(
        failureThreshold: Int = 5,
        timeout: TimeInterval = 60,
        successThreshold: Int = 2
    ) {
        self.failureThreshold = failureThreshold
        self.timeout = timeout
        self.successThreshold = successThreshold
    }
    
    func canExecute() async -> Bool {
        switch state {
        case .closed:
            return true
            
        case .open(let until):
            if Date() > until {
                state = .halfOpen
                return true
            }
            return false
            
        case .halfOpen:
            return true
        }
    }
    
    func recordSuccess() async {
        switch state {
        case .closed:
            failureCount = 0
            
        case .halfOpen:
            successCount += 1
            if successCount >= successThreshold {
                state = .closed
                failureCount = 0
                successCount = 0
            }
            
        case .open:
            break
        }
    }
    
    func recordFailure() async {
        switch state {
        case .closed:
            failureCount += 1
            if failureCount >= failureThreshold {
                state = .open(until: Date().addingTimeInterval(timeout))
            }
            
        case .halfOpen:
            state = .open(until: Date().addingTimeInterval(timeout))
            successCount = 0
            
        case .open:
            break
        }
    }
    
    func reset() async {
        state = .closed
        failureCount = 0
        successCount = 0
    }
}

// Usage with OpenAI
class ResilientOpenAIClient {
    private let client: OpenAIKit
    private let circuitBreaker = CircuitBreaker()
    
    init(client: OpenAIKit) {
        self.client = client
    }
    
    func completions(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        // Check circuit breaker
        guard await circuitBreaker.canExecute() else {
            throw CircuitBreakerError.circuitOpen
        }
        
        do {
            let response = try await client.chat.completions(request)
            await circuitBreaker.recordSuccess()
            return response
        } catch {
            await circuitBreaker.recordFailure()
            throw error
        }
    }
}

enum CircuitBreakerError: LocalizedError {
    case circuitOpen
    
    var errorDescription: String? {
        "Service temporarily unavailable. Please try again later."
    }
}