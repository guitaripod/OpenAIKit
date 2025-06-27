import Foundation
import OpenAIKit

struct AdvancedTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testAdvancedFeatures(openAI: openAI)
        await testErrorUIFeatures(openAI: openAI)
    }
    
    func testAdvancedFeatures(openAI: OpenAIKit) async {
        output.startTest("🚀 Testing Advanced Features...")
        
        // Test streaming with usage tracking
        print("\n  Testing streaming with usage tracking...")
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "Write 3 sentences about Swift programming")
                ],
                model: Models.Chat.gpt4oMini,
                stream: true,
                streamOptions: StreamOptions(includeUsage: true)
            )
            
            let stream = openAI.chat.completionsStream(request)
            var totalContent = ""
            var finalUsage: Usage?
            
            for try await chunk in stream {
                if let content = chunk.choices.first?.delta.content {
                    totalContent += content
                }
                if let usage = chunk.usage {
                    finalUsage = usage
                }
            }
            
            print("  ✅ Streaming with usage completed")
            print("  Total content length: \(totalContent.count) characters")
            if let usage = finalUsage {
                print("  Total tokens used: \(usage.totalTokens)")
            }
        } catch {
            print("  ❌ Streaming with usage failed: \(error)")
        }
        
        // Test parallel chat requests
        print("\n  Testing parallel chat requests...")
        do {
            async let response1 = performChatRequest(openAI: openAI, message: "What is 2+2?")
            async let response2 = performChatRequest(openAI: openAI, message: "What is the capital of France?")
            async let response3 = performChatRequest(openAI: openAI, message: "Name a color")
            
            let responses = await [try response1, try response2, try response3]
            print("  ✅ Parallel requests completed successfully")
            print("  Received \(responses.count) responses")
        } catch {
            print("  ❌ Parallel requests failed: \(error)")
        }
        
        // Test function calling with multiple tools
        print("\n  Testing multiple function tools...")
        do {
            let weatherTool = Tool(
                type: .function,
                function: Function(
                    name: "get_weather",
                    description: "Get the weather for a location",
                    parameters: [
                        "type": "object",
                        "properties": [
                            "location": ["type": "string", "description": "City name"],
                            "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
                        ],
                        "required": ["location"]
                    ]
                )
            )
            
            let calculatorTool = Tool(
                type: .function,
                function: Function(
                    name: "calculate",
                    description: "Perform basic math calculations",
                    parameters: [
                        "type": "object",
                        "properties": [
                            "expression": ["type": "string", "description": "Math expression"]
                        ],
                        "required": ["expression"]
                    ]
                )
            )
            
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "What's the weather in Paris and what's 15 * 24?")
                ],
                model: Models.Chat.gpt4oMini,
                tools: [weatherTool, calculatorTool]
            )
            
            let response = try await openAI.chat.completions(request)
            let toolCalls = response.choices.first?.message.toolCalls ?? []
            
            print("  ✅ Multiple tools handled successfully")
            print("  Tool calls made: \(toolCalls.count)")
            for toolCall in toolCalls {
                print("  - \(toolCall.function?.name ?? "unknown"): \(toolCall.function?.arguments ?? "")")
            }
        } catch {
            print("  ❌ Multiple tools failed: \(error)")
        }
        
        // Test conversation with context
        print("\n  Testing conversation with context...")
        do {
            var messages = [
                ChatMessage(role: .system, content: "You are a helpful math tutor."),
                ChatMessage(role: .user, content: "I need help with algebra")
            ]
            
            // First response
            let request1 = ChatCompletionRequest(
                messages: messages,
                model: Models.Chat.gpt4oMini,
                maxCompletionTokens: 100
            )
            
            let response1 = try await openAI.chat.completions(request1)
            if let assistantMessage = response1.choices.first?.message {
                messages.append(assistantMessage)
            }
            
            // Follow-up with context
            messages.append(ChatMessage(role: .user, content: "Can you give me a simple equation to solve?"))
            
            let request2 = ChatCompletionRequest(
                messages: messages,
                model: Models.Chat.gpt4oMini,
                maxCompletionTokens: 100
            )
            
            let response2 = try await openAI.chat.completions(request2)
            
            print("  ✅ Conversation with context successful")
            print("  Total messages in conversation: \(messages.count)")
            if let usage = response2.usage {
                print("  Final request tokens: \(usage.totalTokens)")
            }
        } catch {
            print("  ❌ Conversation with context failed: \(error)")
        }
        
        // Test image generation with different parameters
        print("\n  Testing advanced image generation...")
        do {
            // Test DALL-E 3 with style variations
            let requests = [
                ImageGenerationRequest(
                    prompt: "A futuristic city",
                    model: Models.Images.dallE3,
                    quality: "standard",
                    style: "vivid"
                ),
                ImageGenerationRequest(
                    prompt: "A futuristic city",
                    model: Models.Images.dallE3,
                    quality: "standard",
                    style: "natural"
                )
            ]
            
            for (index, request) in requests.enumerated() {
                let response = try await openAI.images.generations(request)
                print("  ✅ Image \(index + 1) generated with style: \(request.style ?? "default")")
                if let revisedPrompt = response.data.first?.revisedPrompt {
                    print("  Revised prompt: \(revisedPrompt)")
                }
            }
        } catch {
            print("  ❌ Advanced image generation failed: \(error)")
        }
    }
    
    func testErrorUIFeatures(openAI: OpenAIKit) async {
        output.startTest("🎨 Testing Error UI Features...")
        
        // Test various error scenarios and their UI properties
        let errorScenarios: [(String, OpenAIError)] = [
            ("Invalid URL", OpenAIError.invalidURL),
            ("Authentication Failed", OpenAIError.authenticationFailed),
            ("Rate Limit", OpenAIError.rateLimitExceeded),
            ("Client Error (400)", OpenAIError.clientError(statusCode: 400)),
            ("Server Error (500)", OpenAIError.serverError(statusCode: 500)),
            ("File Invalid", OpenAIError.invalidFileData),
            ("Streaming Not Supported", OpenAIError.streamingNotSupported),
            ("Decoding Failed", OpenAIError.decodingFailed(NSError(domain: "Test", code: 1, userInfo: nil)))
        ]
        
        print("\n  Error UI Properties:")
        print("  " + String(repeating: "-", count: 80))
        
        for (name, error) in errorScenarios {
            print("\n  \(name):")
            print("    Title: \(error.userFriendlyTitle)")
            print("    Message: \(error.userFriendlyMessage)")
            print("    Icon: \(error.iconName)")
            print("    Severity: \(error.severity)")
            print("    Retryable: \(error.isRetryable)")
            if let delay = error.suggestedRetryDelay {
                print("    Retry Delay: \(delay)s")
            }
            print("    Actions: \(error.suggestedActions.map { $0.buttonTitle }.joined(separator: ", "))")
            if let code = error.errorCode {
                print("    Error Code: \(code)")
            }
            if let param = error.affectedParameter {
                print("    Affected Parameter: \(param)")
            }
        }
        
        // Test retry handler
        print("\n\n  Testing Retry Handler...")
        
        let retryHandler = RetryHandler(configuration: .init(
            maxAttempts: 3,
            baseDelay: 0.5,
            useExponentialBackoff: false
        ))
        
        // Create a stateful closure that tracks attempts
        final class AttemptTracker: @unchecked Sendable {
            var count = 0
        }
        let tracker = AttemptTracker()
        
        do {
            // Simulate a failing request that succeeds on 3rd attempt
            let result = try await retryHandler.perform {
                tracker.count += 1
                print("    Attempt \(tracker.count)...")
                
                if tracker.count < 3 {
                    throw OpenAIError.serverError(statusCode: 503)
                }
                
                return "Success after \(tracker.count) attempts!"
            } onRetry: { attempt, delay in
                print("    Retrying attempt \(attempt) after \(String(format: "%.1f", delay))s delay")
            }
            
            print("  ✅ Retry handler succeeded: \(result)")
        } catch {
            print("  ❌ Retry handler failed: \(error)")
        }
        
        // Test retry with OpenAIKit convenience method
        print("\n  Testing OpenAIKit retry convenience method...")
        
        let testOpenAI = OpenAIKit(apiKey: "test-key") // Invalid key for testing
        
        do {
            _ = try await testOpenAI.withRetry(
                configuration: .init(maxAttempts: 2, baseDelay: 0.5)
            ) {
                // This will fail with auth error
                try await testOpenAI.models.list()
            }
        } catch let error as OpenAIError {
            print("  ✅ Caught error with retry: \(error.userFriendlyTitle)")
            print("    Requires user action: \(error.requiresUserAction)")
        } catch {
            print("  ⚠️  Caught other error: \(error)")
        }
        
        // Test error details struct
        print("\n  Testing Error Details Struct...")
        
        let rateLimitError = OpenAIError.rateLimitExceeded
        
        let details = OpenAIErrorDetails(from: rateLimitError)
        print("    Title: \(details.title)")
        print("    Message: \(details.message)")
        print("    Icon: \(details.iconName)")
        print("    Severity: \(details.severity)")
        print("    Actions: \(details.actions.count) suggested")
        print("    Retryable: \(details.isRetryable)")
        if let technical = details.technicalDetails {
            print("    Technical: \(technical)")
        }
        
        // Test real API error to see enhanced error info
        print("\n  Testing Real API Error Handling...")
        
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "Hello")
                ],
                model: "gpt-4-turbo-preview", // Model that might not be accessible
                maxCompletionTokens: 10
            )
            
            _ = try await openAI.chat.completions(request)
            print("  ✅ Request succeeded (model accessible)")
        } catch let error as OpenAIError {
            print("  ℹ️  Caught expected error:")
            print("    User-friendly: \(error.userFriendlyMessage)")
            print("    Should retry: \(error.isRetryable)")
            print("    Max retries: \(error.maxRetryAttempts)")
            
            // Demonstrate error handling in a UI context
            handleErrorForUI(error)
        } catch {
            print("  ⚠️  Caught other error: \(error)")
        }
    }
    
    // Helper function for parallel requests
    private func performChatRequest(openAI: OpenAIKit, message: String) async throws -> ChatCompletionResponse {
        let request = ChatCompletionRequest(
            messages: [ChatMessage(role: .user, content: message)],
            model: "gpt-4o-mini",
            maxCompletionTokens: 20
        )
        return try await openAI.chat.completions(request)
    }
    
    // Helper function to demonstrate UI error handling
    private func handleErrorForUI(_ error: OpenAIError) {
        print("\n  📱 UI Error Handler Demo:")
        print("    Alert Title: \(error.userFriendlyTitle)")
        print("    Alert Message: \(error.userFriendlyMessage)")
        print("    Alert Icon: \(error.iconName)")
        
        if !error.suggestedActions.isEmpty {
            print("    Alert Actions:")
            for action in error.suggestedActions {
                print("      - \(action.buttonTitle): \(action.description)")
            }
        }
        
        if error.isRetryable {
            print("    ↻ Enable retry button")
            if let delay = error.suggestedRetryDelay {
                print("    ⏱️  Show countdown timer: \(Int(delay))s")
            }
        }
        
        if error.requiresUserAction {
            print("    ⚠️  Highlight settings/configuration needed")
        }
    }
}