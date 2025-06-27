import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OpenAIKit

struct ChatTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testChatCompletion(openAI: openAI)
        await testStreamingChat(openAI: openAI)
        await testFunctionCalling(openAI: openAI)
    }
    
    func testChatCompletion(openAI: OpenAIKit) async {
        output.startTest("📝 Testing Chat Completions...")
        
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .system, content: "You are a helpful assistant."),
                    ChatMessage(role: .user, content: "Say 'Hello, OpenAIKit is working!' if you can read this.")
                ],
                model: Models.Chat.gpt4oMini,
                maxCompletionTokens: 50,
                temperature: 0.7
            )
            
            let response = try await openAI.chat.completions(request)
            
            output.success("Chat completion successful!")
            output.info("Model: \(response.model)")
            if let content = response.choices.first?.message.content,
               case .string(let text) = content {
                output.info("Response: \(text)")
            } else {
                output.info("Response: No response")
            }
            output.info("Usage: \(response.usage?.totalTokens ?? 0) tokens")
        } catch {
            output.failure("Chat completion failed", error: error)
        }
    }
    
    func testStreamingChat(openAI: OpenAIKit) async {
        output.startTest("📡 Testing Streaming Chat...")
        
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "Count from 1 to 5 slowly.")
                ],
                model: Models.Chat.gpt4oMini,
                stream: true,
                streamOptions: StreamOptions(includeUsage: true)
            )
            
            let stream = openAI.chat.completionsStream(request)
            
            output.success("Stream started successfully!")
            print("Response: ", terminator: "")
            
            for try await chunk in stream {
                if let content = chunk.choices.first?.delta.content {
                    print(content, terminator: "")
                    fflush(stdout)
                }
            }
            print("\n✅ Streaming completed!")
        } catch {
            output.failure("Streaming failed", error: error)
        }
    }
    
    func testFunctionCalling(openAI: OpenAIKit) async {
        output.startTest("🔧 Testing Function Calling...")
        
        do {
            let weatherFunction = Tool(
                type: .function,
                function: Function(
                    name: "get_weather",
                    description: "Get the current weather in a given location",
                    parameters: [
                        "type": "object",
                        "properties": [
                            "location": [
                                "type": "string",
                                "description": "The city and state, e.g. San Francisco, CA"
                            ],
                            "unit": [
                                "type": "string",
                                "description": "Temperature unit",
                                "enum": ["celsius", "fahrenheit"]
                            ]
                        ],
                        "required": ["location"]
                    ]
                )
            )
            
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "What's the weather in New York?")
                ],
                model: Models.Chat.gpt4oMini,
                toolChoice: .auto,
                tools: [weatherFunction]
            )
            
            let response = try await openAI.chat.completions(request)
            
            if let toolCall = response.choices.first?.message.toolCalls?.first {
                output.success("Function calling successful!")
                output.info("Function: \(toolCall.function?.name ?? "Unknown")")
                output.info("Arguments: \(toolCall.function?.arguments ?? "No arguments")")
            } else {
                output.warning("No function call in response")
            }
        } catch {
            output.failure("Function calling failed", error: error)
        }
    }
}