// Automatic error recovery strategies
import Foundation

class ErrorRecoveryManager {
    static let shared = ErrorRecoveryManager()
    
    func recoveryStrategy(for error: Error, context: ErrorContext) -> ErrorRecovery? {
        let details = ErrorAnalyzer.analyze(error)
        
        switch details.type {
        case .api:
            return apiRecoveryStrategy(details: details, context: context)
        case .network:
            return networkRecoveryStrategy(details: details, context: context)
        case .unknown:
            return nil
        }
    }
    
    private func apiRecoveryStrategy(details: ErrorDetails, context: ErrorContext) -> ErrorRecovery? {
        switch details.code {
        case "rate_limit_exceeded":
            return DelayedRetryRecovery(delay: 60) {
                // Retry the operation after delay
                try await retryOperation(context)
            }
            
        case "invalid_api_key":
            return ConfigurationRecovery {
                // Open settings
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            
        case "context_length_exceeded":
            return MessageTruncationRecovery(context: context)
            
        default:
            if details.isRetryable {
                return RetryRecovery {
                    try await retryOperation(context)
                }
            }
            return nil
        }
    }
    
    private func networkRecoveryStrategy(details: ErrorDetails, context: ErrorContext) -> ErrorRecovery? {
        return NetworkRecovery {
            // Wait for network
            await waitForNetwork()
            try await retryOperation(context)
        }
    }
    
    private func retryOperation(_ context: ErrorContext) async throws {
        // Re-execute the original operation based on context
        switch context.operation {
        case "chat":
            if let message = context.context["message"] as? String {
                _ = try await sendChatMessage(message)
            }
        default:
            break
        }
    }
    
    private func waitForNetwork() async {
        // Implement network monitoring
        // For now, just wait
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}

struct DelayedRetryRecovery: ErrorRecovery {
    let delay: TimeInterval
    let action: () async throws -> Void
    
    func attemptRecovery() async -> Bool {
        do {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            try await action()
            return true
        } catch {
            return false
        }
    }
}

struct MessageTruncationRecovery: ErrorRecovery {
    let context: ErrorContext
    
    func attemptRecovery() async -> Bool {
        guard let message = context.context["message"] as? String else {
            return false
        }
        
        // Truncate message to fit context limit
        let truncated = String(message.prefix(2000)) + "..."
        
        do {
            _ = try await sendChatMessage(truncated)
            return true
        } catch {
            return false
        }
    }
}

struct NetworkRecovery: ErrorRecovery {
    let action: () async throws -> Void
    
    func attemptRecovery() async -> Bool {
        // Check network availability first
        // This is simplified - in real app use NWPathMonitor
        do {
            try await action()
            return true
        } catch {
            return false
        }
    }
}