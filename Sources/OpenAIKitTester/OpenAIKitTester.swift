import Foundation
import OpenAIKit

@main
struct OpenAIKitTester {
    // Set your API key via environment variable: export OPENAI_API_KEY=your-key-here
    static let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_API_KEY_HERE"
    
    static func main() async {
        print("🚀 OpenAIKit Test Suite")
        print("====================")
        
        let openAI = OpenAIKit(apiKey: apiKey)
        
        if CommandLine.arguments.count < 2 {
            printUsage()
            return
        }
        
        let command = CommandLine.arguments[1]
        
        switch command {
            case "chat":
                await testChatCompletion(openAI: openAI)
            case "stream":
                await testStreamingChat(openAI: openAI)
            case "functions":
                await testFunctionCalling(openAI: openAI)
            case "embeddings":
                await testEmbeddings(openAI: openAI)
            case "audio-transcribe":
                await testAudioTranscription(openAI: openAI)
            case "audio-tts":
                await testTextToSpeech(openAI: openAI)
            case "moderation":
                await testModeration(openAI: openAI)
            case "models":
                await testListModels(openAI: openAI)
            case "files":
                await testFiles(openAI: openAI)
            case "images":
                await testImageGeneration(openAI: openAI)
            case "edge-cases":
                await testEdgeCases(openAI: openAI)
            case "error-handling":
                await testErrorHandling(openAI: openAI)
            case "advanced":
                await testAdvancedFeatures(openAI: openAI)
            case "error-ui":
                await testErrorUIFeatures(openAI: openAI)
            case "batch":
                await testBatchAPI(openAI: openAI)
            case "batch-edge":
                await testBatchEdgeCases(openAI: openAI)
            case "all":
                await runAllTests(openAI: openAI)
            default:
                print("❌ Unknown command: \(command)")
                printUsage()
            }
    }
    
    static func printUsage() {
        print("""
        Usage: swift run OpenAIKitTester <command>
        
        Commands:
          chat             Test basic chat completions
          stream           Test streaming chat completions
          functions        Test function calling
          embeddings       Test embeddings generation
          audio-transcribe Test audio transcription
          audio-tts        Test text-to-speech
          moderation       Test content moderation
          models           Test listing models
          files            Test files API
          images           Test image generation
          edge-cases       Test edge cases and corner scenarios
          error-handling   Test error handling
          advanced         Test advanced features
          error-ui         Test error UI features
          batch            Test batch API
          batch-edge       Test batch API edge cases
          all              Run all tests
        """)
    }
    
    // MARK: - Chat Tests
    
    static func testChatCompletion(openAI: OpenAIKit) async {
        print("\n📝 Testing Chat Completions...")
        
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
            
            print("✅ Chat completion successful!")
            print("Model: \(response.model)")
            if let content = response.choices.first?.message.content,
               case .string(let text) = content {
                print("Response: \(text)")
            } else {
                print("Response: No response")
            }
            print("Usage: \(response.usage?.totalTokens ?? 0) tokens")
        } catch {
            print("❌ Chat completion failed: \(error)")
            if let openAIError = error as? OpenAIError {
                print("Error details: \(openAIError)")
            }
        }
    }
    
    static func testStreamingChat(openAI: OpenAIKit) async {
        print("\n📡 Testing Streaming Chat...")
        
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
            
            print("✅ Stream started successfully!")
            print("Response: ", terminator: "")
            
            for try await chunk in stream {
                if let content = chunk.choices.first?.delta.content {
                    print(content, terminator: "")
                    fflush(stdout)
                }
            }
            print("\n✅ Streaming completed!")
        } catch {
            print("❌ Streaming failed: \(error)")
        }
    }
    
    static func testFunctionCalling(openAI: OpenAIKit) async {
        print("\n🔧 Testing Function Calling...")
        
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
                print("✅ Function calling successful!")
                print("Function: \(toolCall.function?.name ?? "Unknown")")
                print("Arguments: \(toolCall.function?.arguments ?? "No arguments")")
            } else {
                print("⚠️  No function call in response")
            }
        } catch {
            print("❌ Function calling failed: \(error)")
        }
    }
    
    // MARK: - Embeddings Test
    
    static func testEmbeddings(openAI: OpenAIKit) async {
        print("\n🔢 Testing Embeddings...")
        
        do {
            let request = EmbeddingRequest(
                input: "The quick brown fox jumps over the lazy dog",
                model: Models.Embeddings.textEmbedding3Small
            )
            
            let response = try await openAI.embeddings.create(request)
            
            print("✅ Embeddings successful!")
            print("Model: \(response.model)")
            print("Embedding dimensions: \(response.data.first?.embedding.floatValues?.count ?? 0)")
            print("Usage: \(response.usage.totalTokens) tokens")
        } catch {
            print("❌ Embeddings failed: \(error)")
        }
    }
    
    // MARK: - Audio Tests
    
    static func testAudioTranscription(openAI: OpenAIKit) async {
        print("\n🎤 Testing Audio Transcription...")
        
        do {
            // Create a simple test audio file if it doesn't exist
            let audioURL = URL(fileURLWithPath: "test_audio.wav")
            
            if !FileManager.default.fileExists(atPath: audioURL.path) {
                // Create a simple sine wave audio file using the shell
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/ffmpeg")
                process.arguments = [
                    "-f", "lavfi",
                    "-i", "sine=frequency=440:duration=2",
                    "-ac", "1",
                    "-ar", "16000",
                    audioURL.path
                ]
                try process.run()
                process.waitUntilExit()
            }
            
            let audioData = try Data(contentsOf: audioURL)
            
            let request = TranscriptionRequest(
                file: audioData,
                fileName: "test_audio.wav",
                model: Models.Audio.whisper1
            )
            
            let response = try await openAI.audio.transcriptions(request)
            
            print("✅ Audio transcription successful!")
            print("Text: \(response.text)")
            if let language = response.language {
                print("Detected language: \(language)")
            }
            if let duration = response.duration {
                print("Duration: \(duration) seconds")
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: audioURL)
        } catch {
            print("❌ Audio transcription failed: \(error)")
        }
    }
    
    static func testTextToSpeech(openAI: OpenAIKit) async {
        print("\n🔊 Testing Text-to-Speech...")
        
        do {
            let request = SpeechRequest(
                input: "Hello, this is a test of OpenAIKit text to speech.",
                model: Models.Audio.tts1,
                voice: .alloy,
                responseFormat: .mp3,
                speed: 1.0
            )
            
            let audioData = try await openAI.audio.speech(request)
            
            print("✅ TTS successful!")
            print("Audio data size: \(audioData.count) bytes")
            
            // Save to file for verification
            let url = URL(fileURLWithPath: "test_speech.mp3")
            try audioData.write(to: url)
            print("Audio saved to: test_speech.mp3")
        } catch {
            print("❌ TTS failed: \(error)")
        }
    }
    
    // MARK: - Moderation Test
    
    static func testModeration(openAI: OpenAIKit) async {
        print("\n🛡️ Testing Moderation...")
        
        do {
            let request = ModerationRequest(
                input: "This is a completely safe and appropriate message.",
                model: Models.Moderation.omniModerationLatest
            )
            
            let response = try await openAI.moderations.create(request)
            
            print("✅ Moderation successful!")
            print("Model: \(response.model)")
            if let result = response.results.first {
                print("Flagged: \(result.flagged)")
                print("Categories: harassment=\(result.categories.harassment), violence=\(result.categories.violence)")
            }
        } catch {
            print("❌ Moderation failed: \(error)")
        }
    }
    
    // MARK: - Models Test
    
    static func testListModels(openAI: OpenAIKit) async {
        print("\n📋 Testing List Models...")
        
        do {
            let response = try await openAI.models.list()
            
            print("✅ List models successful!")
            print("Found \(response.data.count) models")
            
            // Show first 5 models
            for model in response.data.prefix(5) {
                print("  - \(model.id) (owned by: \(model.ownedBy))")
            }
            
            if response.data.count > 5 {
                print("  ... and \(response.data.count - 5) more")
            }
        } catch {
            print("❌ List models failed: \(error)")
        }
    }
    
    // MARK: - Files Test
    
    static func testFiles(openAI: OpenAIKit) async {
        print("\n📁 Testing Files...")
        
        do {
            // Create a test file
            let testContent = "This is a test file for OpenAIKit".data(using: .utf8)!
            let fileName = "test.txt"
            
            // Create temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try testContent.write(to: tempURL)
            
            // Upload file
            let uploadRequest = FileRequest(
                file: testContent,
                fileName: fileName,
                purpose: .assistants
            )
            
            let file = try await openAI.files.upload(uploadRequest)
            print("✅ File uploaded: \(file.id)")
            print("File size: \(file.bytes) bytes")
            
            // List files
            let listResponse = try await openAI.files.list()
            print("Found \(listResponse.data.count) files")
            
            // Delete file
            let deleteResponse = try await openAI.files.delete(fileId: file.id)
            print("✅ File deleted: \(deleteResponse.deleted)")
            
            // Clean up temp file
            try FileManager.default.removeItem(at: tempURL)
        } catch {
            print("❌ Files test failed: \(error)")
        }
    }
    
    // MARK: - Images Test
    
    static func testImageGeneration(openAI: OpenAIKit) async {
        print("\n🎨 Testing Image Generation...")
        
        // Test DALL-E 2
        print("\n  Testing DALL-E 2...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A simple red circle on white background",
                model: Models.Images.dallE2,
                n: 2,  // Test multiple images
                responseFormat: .url,
                size: "256x256"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ DALL-E 2 generation successful!")
            print("  Created: \(response.created)")
            print("  Generated \(response.data.count) images")
            
            for (index, image) in response.data.enumerated() {
                if let url = image.url {
                    print("  Image \(index + 1) URL: \(url.prefix(80))...")
                }
            }
        } catch {
            print("  ❌ DALL-E 2 generation failed: \(error)")
        }
        
        // Test DALL-E 3
        print("\n  Testing DALL-E 3...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A photorealistic golden retriever puppy playing in a field of flowers",
                model: Models.Images.dallE3,
                n: 1,  // DALL-E 3 only supports n=1
                quality: "standard",
                responseFormat: .url,
                size: "1024x1024",
                style: "vivid"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ DALL-E 3 generation successful!")
            print("  Created: \(response.created)")
            
            for image in response.data {
                if let url = image.url {
                    print("  Image URL: \(url.prefix(80))...")
                }
                if let revisedPrompt = image.revisedPrompt {
                    print("  Revised prompt: \(revisedPrompt)")
                }
            }
        } catch {
            print("  ❌ DALL-E 3 generation failed: \(error)")
        }
        
        // Test DALL-E 3 HD quality
        print("\n  Testing DALL-E 3 HD quality...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A serene Japanese garden with cherry blossoms, highly detailed",
                model: Models.Images.dallE3,
                n: 1,
                quality: "hd",
                responseFormat: .url,
                size: "1792x1024",  // Wide format
                style: "natural"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ DALL-E 3 HD generation successful!")
            print("  Created: \(response.created)")
            
            for image in response.data {
                if let url = image.url {
                    print("  Image URL: \(url.prefix(80))...")
                }
            }
        } catch {
            print("  ❌ DALL-E 3 HD generation failed: \(error)")
        }
        
        // Test base64 response format with DALL-E 2
        print("\n  Testing base64 response format (DALL-E 2)...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A small blue square",
                model: Models.Images.dallE2,
                n: 1,
                responseFormat: .b64Json,
                size: "256x256"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ Base64 generation successful!")
            
            for image in response.data {
                if let b64 = image.b64Json {
                    print("  Base64 data length: \(b64.count) characters")
                    print("  Base64 prefix: \(b64.prefix(50))...")
                }
            }
        } catch {
            print("  ❌ Base64 generation failed: \(error)")
        }
        
        // Test gpt-image-1 model
        print("\n  Testing gpt-image-1 model...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A simple geometric pattern with triangles",
                model: Models.Images.gptImage1,
                n: 1,
                outputCompression: 90,
                outputFormat: "jpeg",
                quality: "medium",
                size: "1024x1024"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ gpt-image-1 generation successful!")
            print("  Created: \(response.created)")
            
            // gpt-image-1 always returns base64
            for image in response.data {
                if let b64 = image.b64Json {
                    print("  Base64 data length: \(b64.count) characters")
                }
            }
            
            // Check if usage is returned
            if let usage = response.usage {
                print("  Usage - Total tokens: \(usage.totalTokens ?? 0)")
                if let inputTokens = usage.inputTokens {
                    print("  Input tokens: \(inputTokens)")
                }
            }
        } catch {
            print("  ❌ gpt-image-1 generation failed: \(error)")
        }
        
        // Test gpt-image-1 with transparent background
        print("\n  Testing gpt-image-1 with transparent background...")
        do {
            let request = ImageGenerationRequest(
                prompt: "A red heart shape",
                background: "transparent",
                model: Models.Images.gptImage1,
                n: 1,
                outputFormat: "png",
                quality: "high",
                size: "auto"
            )
            
            let response = try await openAI.images.generations(request)
            
            print("  ✅ gpt-image-1 transparent generation successful!")
            
            for image in response.data {
                if let b64 = image.b64Json {
                    print("  Base64 data length: \(b64.count) characters")
                }
            }
        } catch {
            print("  ❌ gpt-image-1 transparent generation failed: \(error)")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    static func testEdgeCases(openAI: OpenAIKit) async {
        print("\n🔍 Testing Edge Cases...")
        
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
    
    // MARK: - Error Handling Tests
    
    static func testErrorHandling(openAI: OpenAIKit) async {
        print("\n🚨 Testing Error Handling...")
        
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
    
    // MARK: - Advanced Features Tests
    
    static func testAdvancedFeatures(openAI: OpenAIKit) async {
        print("\n🚀 Testing Advanced Features...")
        
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
        
        // Test embeddings with multiple inputs
        print("\n  Testing embeddings with multiple inputs...")
        do {
            let inputs = [
                "First text for embedding",
                "Second text for embedding", 
                "Third text for embedding"
            ]
            let request = EmbeddingRequest(
                input: inputs,
                model: Models.Embeddings.textEmbedding3Small,
                dimensions: 512  // Reduced dimensions
            )
            
            let response = try await openAI.embeddings.create(request)
            print("  ✅ Multiple embeddings successful")
            print("  Generated \(response.data.count) embeddings")
            print("  Dimensions per embedding: \(response.data.first?.embedding.floatValues?.count ?? 0)")
            print("  Total tokens used: \(response.usage.totalTokens)")
        } catch {
            print("  ❌ Multiple embeddings failed: \(error)")
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
        
        // Test file upload and retrieval
        print("\n  Testing file operations with metadata...")
        do {
            let testData = "Line 1\\nLine 2\\nLine 3\\nLine 4\\nLine 5".data(using: .utf8)!
            let uploadRequest = FileRequest(
                file: testData,
                fileName: "test_metadata.txt",
                purpose: .assistants
            )
            
            let uploadedFile = try await openAI.files.upload(uploadRequest)
            print("  ✅ File uploaded with ID: \(uploadedFile.id)")
            
            // Retrieve the file
            let retrievedFile = try await openAI.files.retrieve(fileId: uploadedFile.id)
            print("  ✅ File retrieved successfully")
            print("  File name: \(retrievedFile.filename)")
            print("  File size: \(retrievedFile.bytes) bytes")
            
            // Clean up
            _ = try await openAI.files.delete(fileId: uploadedFile.id)
            print("  ✅ File cleaned up")
        } catch {
            print("  ❌ File operations failed: \(error)")
        }
    }
    
    // Helper function for parallel requests
    static func performChatRequest(openAI: OpenAIKit, message: String) async throws -> ChatCompletionResponse {
        let request = ChatCompletionRequest(
            messages: [ChatMessage(role: .user, content: message)],
            model: "gpt-4o-mini",
            maxCompletionTokens: 20
        )
        return try await openAI.chat.completions(request)
    }
    
    // MARK: - Error UI Features Tests
    
    static func testErrorUIFeatures(openAI: OpenAIKit) async {
        print("\n🎨 Testing Error UI Features...")
        
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
        class AttemptTracker {
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
    
    // Helper function to demonstrate UI error handling
    static func handleErrorForUI(_ error: OpenAIError) {
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
    
    // MARK: - Run All Tests
    
    static func runAllTests(openAI: OpenAIKit) async {
        print("\n🏃 Running all tests...")
        
        await testChatCompletion(openAI: openAI)
        await testStreamingChat(openAI: openAI)
        await testFunctionCalling(openAI: openAI)
        await testEmbeddings(openAI: openAI)
        await testAudioTranscription(openAI: openAI)
        await testTextToSpeech(openAI: openAI)
        await testModeration(openAI: openAI)
        await testListModels(openAI: openAI)
        await testFiles(openAI: openAI)
        await testImageGeneration(openAI: openAI)
        await testEdgeCases(openAI: openAI)
        await testErrorHandling(openAI: openAI)
        await testAdvancedFeatures(openAI: openAI)
        
        print("\n✅ All tests completed!")
    }
}