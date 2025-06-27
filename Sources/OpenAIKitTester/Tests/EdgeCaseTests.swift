import Foundation
import OpenAIKit

struct EdgeCaseTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testEdgeCases(openAI: openAI)
        await testErrorHandling(openAI: openAI)
    }
    
    func testEdgeCases(openAI: OpenAIKit) async {
        output.startTest("🔍 Testing Edge Cases...")
        
        // Test empty messages
        print("\n  Testing empty user message...")
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "")
                ],
                model: "gpt-4o-mini"
            )
            
            let response = try await openAI.chat.completions(request)
            print("  ✅ Empty message handled: \(response.choices.first?.message.content != nil)")
        } catch {
            print("  ❌ Empty message failed: \(error)")
        }
        
        // Test very long prompt (near token limit)
        print("\n  Testing very long prompt...")
        do {
            let longText = String(repeating: "This is a test sentence. ", count: 500)
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: longText)
                ],
                model: Models.Chat.gpt4oMini,
                maxCompletionTokens: 10
            )
            
            let response = try await openAI.chat.completions(request)
            print("  ✅ Long prompt handled successfully")
            if let usage = response.usage {
                print("  Prompt tokens: \(usage.promptTokens)")
            }
        } catch {
            print("  ❌ Long prompt failed: \(error)")
        }
        
        // Test special characters in prompt
        print("\n  Testing special characters...")
        do {
            let specialCharsText = "Test with émojis 🎉 and unicode: αβγδ and symbols: <>&\"'"
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: specialCharsText)
                ],
                model: Models.Chat.gpt4oMini,
                maxCompletionTokens: 50
            )
            
            _ = try await openAI.chat.completions(request)
            print("  ✅ Special characters handled successfully")
        } catch {
            print("  ❌ Special characters failed: \(error)")
        }
        
        // Test multiple system messages
        print("\n  Testing multiple system messages...")
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .system, content: "You are a helpful assistant."),
                    ChatMessage(role: .system, content: "You always respond in haiku."),
                    ChatMessage(role: .user, content: "What is the weather?")
                ],
                model: Models.Chat.gpt4oMini,
                maxCompletionTokens: 50
            )
            
            _ = try await openAI.chat.completions(request)
            print("  ✅ Multiple system messages handled")
        } catch {
            print("  ❌ Multiple system messages failed: \(error)")
        }
        
        // Test streaming with immediate stop
        print("\n  Testing streaming with immediate stop...")
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "Count to 100 slowly")
                ],
                model: Models.Chat.gpt4oMini,
                maxCompletionTokens: 5,
                stream: true
            )
            
            let stream = openAI.chat.completionsStream(request)
            var chunkCount = 0
            
            for try await _ in stream {
                chunkCount += 1
                if chunkCount > 3 {
                    break  // Stop early
                }
            }
            print("  ✅ Stream stopped early after \(chunkCount) chunks")
        } catch {
            print("  ❌ Stream early stop failed: \(error)")
        }
        
        // Test embeddings with empty string
        print("\n  Testing embeddings with empty input...")
        do {
            let request = EmbeddingRequest(
                input: "",
                model: Models.Embeddings.textEmbedding3Small
            )
            
            _ = try await openAI.embeddings.create(request)
            print("  ✅ Empty embedding handled")
        } catch {
            print("  ⚠️  Empty embedding expected to fail: \(error)")
        }
        
        // Test embeddings with very long input
        print("\n  Testing embeddings with very long input...")
        do {
            let longText = String(repeating: "This is a long text for embedding. ", count: 1000)
            let request = EmbeddingRequest(
                input: longText,
                model: Models.Embeddings.textEmbedding3Small
            )
            
            let response = try await openAI.embeddings.create(request)
            print("  ✅ Long embedding handled, tokens used: \(response.usage.totalTokens)")
        } catch {
            print("  ❌ Long embedding failed: \(error)")
        }
        
        // Test moderation with edge content
        print("\n  Testing moderation with edge cases...")
        do {
            let request = ModerationRequest(
                input: "2 + 2 = 5",  // False but not harmful
                model: Models.Moderation.omniModerationLatest
            )
            
            let response = try await openAI.moderations.create(request)
            print("  ✅ Edge moderation case handled, flagged: \(response.results.first?.flagged ?? false)")
        } catch {
            print("  ❌ Edge moderation failed: \(error)")
        }
    }
    
    func testErrorHandling(openAI: OpenAIKit) async {
        output.startTest("🚨 Testing Error Handling...")
        
        // Test invalid model name
        print("\n  Testing invalid model name...")
        do {
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "Hello")
                ],
                model: "invalid-model-xyz"
            )
            
            _ = try await openAI.chat.completions(request)
            print("  ❌ Invalid model should have failed")
        } catch {
            print("  ✅ Invalid model correctly failed: \(error)")
        }
        
        // Test rate limiting simulation (too many messages)
        print("\n  Testing rapid requests...")
        do {
            var successCount = 0
            for i in 0..<5 {
                let request = ChatCompletionRequest(
                    messages: [
                        ChatMessage(role: .user, content: "Test \(i)")
                    ],
                    model: Models.Chat.gpt4oMini,
                    maxCompletionTokens: 5
                )
                
                do {
                    _ = try await openAI.chat.completions(request)
                    successCount += 1
                } catch {
                    print("  Request \(i) failed (expected for rate limiting): \(error)")
                }
                
                // Small delay to avoid actual rate limits
                try await Task.sleep(for: .milliseconds(100))
            }
            print("  ✅ Completed \(successCount)/5 rapid requests")
        } catch {
            print("  ❌ Rapid request test failed: \(error)")
        }
        
        // Test file upload with invalid purpose
        print("\n  Testing file upload with empty data...")
        do {
            let emptyData = Data()
            let request = FileRequest(
                file: emptyData,
                fileName: "empty.txt",
                purpose: .assistants
            )
            
            _ = try await openAI.files.upload(request)
            print("  ❌ Empty file upload should have failed")
        } catch {
            print("  ✅ Empty file correctly failed: \(error)")
        }
        
        // Test non-existent file deletion
        print("\n  Testing non-existent file deletion...")
        do {
            _ = try await openAI.files.delete(fileId: "file-nonexistent123xyz")
            print("  ❌ Non-existent file deletion should have failed")
        } catch {
            print("  ✅ Non-existent file deletion correctly failed: \(error)")
        }
        
        // Test transcription with invalid audio format
        print("\n  Testing transcription with invalid data...")
        do {
            let invalidAudioData = "This is not audio data".data(using: .utf8)!
            let request = TranscriptionRequest(
                file: invalidAudioData,
                fileName: "not_audio.txt",
                model: Models.Audio.whisper1
            )
            
            _ = try await openAI.audio.transcriptions(request)
            print("  ❌ Invalid audio should have failed")
        } catch {
            print("  ✅ Invalid audio correctly failed: \(error)")
        }
        
        // Test image generation with invalid size
        print("\n  Testing image generation with invalid parameters...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A test image",
                model: Models.Images.dallE2,
                size: "999x999"  // Invalid size
            )
            
            _ = try await openAI.images.generations(request)
            print("  ❌ Invalid image size should have failed")
        } catch {
            print("  ✅ Invalid image size correctly failed: \(error)")
        }
        
        // Test null content in function calling response
        print("\n  Testing function calling with null content (already fixed)...")
        do {
            let weatherFunction = Tool(
                type: .function,
                function: Function(
                    name: "get_weather",
                    description: "Get weather",
                    parameters: [
                        "type": "object",
                        "properties": [
                            "location": ["type": "string"]
                        ],
                        "required": ["location"]
                    ]
                )
            )
            
            let request = ChatCompletionRequest(
                messages: [
                    ChatMessage(role: .user, content: "What's the weather in NYC?")
                ],
                model: Models.Chat.gpt4oMini,
                toolChoice: .required,
                tools: [weatherFunction]
            )
            
            let response = try await openAI.chat.completions(request)
            let message = response.choices.first?.message
            print("  ✅ Function call with null content handled correctly")
            print("  Content is nil: \(message?.content == nil)")
            print("  Has tool calls: \(message?.toolCalls?.isEmpty == false)")
        } catch {
            print("  ❌ Function calling failed: \(error)")
        }
    }
}