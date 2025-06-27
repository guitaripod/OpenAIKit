import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OpenAIKit

struct DeepResearchTests {
    let output = ConsoleOutput()
    let config = TestConfiguration.fromEnvironment()
    
    func runAll(openAI: OpenAIKit) async {
        await testDeepResearch(openAI: openAI)
    }
    
    func testDeepResearchStreamQuick() async {
        output.startTest("🔬 Testing DeepResearch Streaming (Quick)...")
        
        // Create a simple test request
        let request = ResponseRequest(
            input: "Hello, respond with: Hi there!",
            model: Models.DeepResearch.o4MiniDeepResearch,
            tools: [.webSearchPreview(WebSearchPreviewTool())],
            maxOutputTokens: 1000  // Testing with lower limit
        )
        
        let config = Configuration(
            apiKey: self.config.apiKey,
            timeoutInterval: 30  // 30 seconds timeout
        )
        let client = OpenAIKit(configuration: config)
        
        print("  Streaming simple query...")
        var eventCount = 0
        var hasContent = false
        
        do {
            for try await chunk in client.responses.createStream(request) {
                eventCount += 1
                
                if eventCount == 1 {
                    print("  ✅ First chunk received!")
                }
                
                if let eventType = chunk.type {
                    print("  Event #\(eventCount): \(eventType)")
                    
                    switch eventType {
                    case "response.created":
                        print("    - Response ID: \(chunk.response?.id ?? "unknown")")
                        
                    case "response.output_item.done":
                        if let item = chunk.item, item.type == "message" {
                            if let content = item.content {
                                print("    - Content: \(content)")
                                hasContent = true
                            }
                        }
                        
                    case "response.done":
                        print("    - Stream completed")
                        if let usage = chunk.response?.usage {
                            print("    - Tokens used: \(usage.totalTokens ?? 0)")
                        }
                        break
                        
                    default:
                        // Other events
                        break
                    }
                }
                
                // Limit to first 20 events for quick test
                if eventCount >= 20 {
                    print("\n  ⚠️  Stopping after 20 events for quick test")
                    break
                }
            }
            
            print("\n  ✅ Summary: Received \(eventCount) events, content: \(hasContent ? "Yes" : "No")")
            
        } catch {
            print("  ❌ Streaming test failed: \(error)")
            if let openAIError = error as? OpenAIError {
                print("  Details: \(openAIError.userFriendlyMessage)")
            }
        }
    }
    
    func testDeepResearch(openAI: OpenAIKit) async {
        output.startTest("🔬 Testing DeepResearch...")
        
        do {
            // Note: DeepResearch can take tens of minutes to complete.
            // For testing purposes, we'll use the o4-mini-deep-research model
            // which is faster, and a simpler query.
            print("\n  ⚠️  Note: DeepResearch models can take tens of minutes to complete.")
            print("  Using o4-mini-deep-research for faster testing...")
            
            // Test with a simple, focused query using the faster model
            // Note: DeepResearch models require very high token limits (10,000+) to complete
            // For testing, we'll use a lower limit and expect incomplete status
            let request = ResponseRequest(
                input: "What is the capital of France? Just answer: Paris.",
                model: Models.DeepResearch.o4MiniDeepResearch,
                tools: [
                    .webSearchPreview(WebSearchPreviewTool())
                ],
                maxOutputTokens: 1000  // Lower limit for testing - real usage needs 10,000+
            )
            
            print("\n  Starting DeepResearch query...")
            print("  Model: \(Models.DeepResearch.o4MiniDeepResearch)")
            print("  Query: Simple geography question (for quick testing)")
            print("\n  ⚠️  Important: DeepResearch models are designed for extensive research tasks.")
            print("  They perform multiple web searches and reasoning steps.")
            print("  For complete responses, use:")
            print("    - max_output_tokens: 10,000+ (minimum 16)")
            print("    - background mode for long-running tasks")
            print("    - Expect 'incomplete' status with lower token limits")
            print("\n  🔍 Research in progress...")
            print("  " + String(repeating: "-", count: 60))
            
            // For testing, we'll use a non-streaming request with explicit timeout handling
            do {
                // Create a custom OpenAIKit instance with extended timeout for DeepResearch
                let deepResearchConfig = Configuration(
                    apiKey: config.apiKey,
                    timeoutInterval: 1800  // 30 minutes timeout for DeepResearch
                )
                let deepResearchClient = OpenAIKit(configuration: deepResearchConfig)
                
                let startTime = Date()
                let response = try await deepResearchClient.responses.create(request)
                let elapsedTime = Date().timeIntervalSince(startTime)
                
                print("\n  " + String(repeating: "-", count: 60))
                print("\n  ✅ DeepResearch completed successfully!")
                print("  Time taken: \(String(format: "%.1f", elapsedTime)) seconds")
                print("  Status: \(response.status ?? "unknown")")
                print("  Model: \(response.model)")
                
                // Extract content from output items
                var messageContent = ""
                if let output = response.output {
                    print("\n  Output items: \(output.count)")
                    for item in output {
                        print("    - Type: \(item.type), ID: \(item.id)")
                        if let content = item.content {
                            messageContent += content
                        }
                    }
                }
                
                if !messageContent.isEmpty {
                    print("\n  Response content: \(messageContent)")
                } else if response.status == "incomplete" {
                    print("\n  ⚠️  Response incomplete - DeepResearch hit token limit before generating message.")
                    print("  This is expected behavior with limited tokens.")
                    if let outputItems = response.output {
                        let searchCount = outputItems.filter { $0.type == "web_search_call" }.count
                        let reasoningCount = outputItems.filter { $0.type == "reasoning" }.count
                        print("  DeepResearch performed \(searchCount) web searches and \(reasoningCount) reasoning steps.")
                    }
                }
                
                if let usage = response.usage {
                    print("\n  Token usage:")
                    print("    - Input tokens: \(usage.inputTokens ?? 0)")
                    print("    - Output tokens: \(usage.outputTokens ?? 0)")
                    print("    - Total tokens: \(usage.totalTokens ?? 0)")
                }
                
            } catch {
                if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorTimedOut {
                    print("\n  ⏱️  Request timed out. This is expected for complex DeepResearch queries.")
                    print("  DeepResearch can take tens of minutes to complete.")
                    print("  Consider using background mode or webhooks for production use.")
                } else {
                    throw error
                }
            }
            
            // Optional: Test streaming (commented out by default due to long duration)
            print("\n  💡 Tip: For production use with DeepResearch:")
            print("     - Use background mode for long-running research")
            print("     - Implement webhooks for completion notifications")
            print("     - Consider using o4-mini-deep-research for faster results")
            print("     - Set appropriate timeouts (30+ minutes)")
            
        } catch {
            print("\n  ❌ DeepResearch failed: \(error)")
            if let openAIError = error as? OpenAIError {
                print("  Error details: \(openAIError.userFriendlyMessage)")
                print("  Error type: \(openAIError)")
            }
            
            // Test with a simpler configuration to see if the models are available
            print("\n  Testing with minimal configuration...")
            do {
                let minimalRequest = ResponseRequest(
                    input: "What is 2+2?",
                    model: Models.DeepResearch.o3DeepResearch,
                    tools: [.webSearchPreview(WebSearchPreviewTool())]  // Tools are required
                )
                
                let response = try await openAI.responses.create(minimalRequest)
                print("  ✅ Minimal request succeeded!")
                if let output = response.output?.first {
                    print("  Response type: \(output.type)")
                    if let content = output.content {
                        print("  Content: \(content.prefix(100))...")
                    }
                }
            } catch {
                print("  ❌ Minimal request also failed: \(error)")
                
                // Try with the fast model
                print("\n  Testing with o4-mini-deep-research...")
                do {
                    let fastRequest = ResponseRequest(
                        input: "What is the capital of France?",
                        model: Models.DeepResearch.o4MiniDeepResearch,
                        tools: [.webSearchPreview(WebSearchPreviewTool())]  // Tools are required
                    )
                    
                    let response = try await openAI.responses.create(fastRequest)
                    print("  ✅ Fast model request succeeded!")
                    if let output = response.output?.first {
                        print("  Response type: \(output.type)")
                        if let content = output.content {
                            print("  Content: \(content.prefix(100))...")
                        }
                    }
                } catch {
                    print("  ❌ Fast model also failed: \(error)")
                }
            }
        }
    }
    
    func testDeepResearchLong(openAI: OpenAIKit) async {
        output.startTest("🔬 Testing DeepResearch (Long Running)...")
        print("\n  ⚠️  WARNING: This test performs actual research and may take 5-30 minutes to complete.")
        print("  The test will research recent AI developments and demonstrate DeepResearch capabilities.")
        print("  Press Ctrl+C to cancel if needed.\n")
        
        // Wait for user confirmation
        print("  Press Enter to continue or Ctrl+C to cancel...")
        _ = readLine()
        
        // First do a quick raw API test to check for errors
        print("\n  Running quick API validation...")
        await testRawDeepResearchLong()
        
        do {
            // Create a comprehensive research request
            let researchQuery = """
            What are the three most significant AI model releases in the past month? 
            For each model, provide:
            - The model name and who released it
            - Key capabilities and improvements
            - Practical applications
            
            Include citations and links to official announcements.
            """
            
            // Create request with extended configuration for real research
            let request = ResponseRequest(
                input: researchQuery,
                model: Models.DeepResearch.o4MiniDeepResearch,  // Use the faster/cheaper model
                tools: [
                    .webSearchPreview(WebSearchPreviewTool())
                    // Note: Code interpreter might not be available with initial DeepResearch release
                ],
                // Note: temperature is not supported with DeepResearch models
                maxOutputTokens: 4000  // Allow comprehensive response
            )
            
            // Create a client with very long timeout for DeepResearch
            let deepResearchConfig = Configuration(
                apiKey: config.apiKey,
                timeoutInterval: 3600  // 1 hour timeout
            )
            let deepResearchClient = OpenAIKit(configuration: deepResearchConfig)
            
            print("  🔍 Starting comprehensive AI research...")
            print("  Model: \(Models.DeepResearch.o4MiniDeepResearch)")
            print("  " + String(repeating: "═", count: 70))
            
            let startTime = Date()
            var lastProgressTime = Date()
            
            // Try streaming request
            print("\n  📡 Streaming research progress...\n")
            
            let stream = deepResearchClient.responses.createStream(request)
            
            var fullContent = ""
            var outputItems: [ResponseOutputItem] = []
            var chunkCount = 0
            var toolCallCount = 0
            var messageCount = 0
            
            for try await chunk in stream {
                chunkCount += 1
                
                // Show progress indicator every 5 seconds
                if Date().timeIntervalSince(lastProgressTime) > 5 {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("\n  ⏱️  Progress: \(String(format: "%.1f", elapsed)) seconds elapsed, \(chunkCount) chunks received...")
                    lastProgressTime = Date()
                }
                
                // Process events based on type
                if let eventType = chunk.type {
                    switch eventType {
                    case "response.created":
                        if let response = chunk.response {
                            print("\n  📝 Response created: \(response.id)")
                            print("  Status: \(response.status ?? "unknown")")
                        }
                        
                    case "response.output_item.added":
                        if let item = chunk.item {
                            outputItems.append(item)
                            
                            switch item.type {
                            case "tool_call":
                                toolCallCount += 1
                                if let toolCall = item.toolCall {
                                    print("\n  🔧 Tool call #\(toolCallCount): \(toolCall.type ?? "unknown")")
                                    if toolCall.type == "web_search_preview" {
                                        if let args = toolCall.arguments {
                                            print("     Search query: \(describeJSONValue(args))")
                                        }
                                    }
                                }
                                
                            case "reasoning":
                                // Reasoning traces
                                if let summary = item.summary, !summary.isEmpty {
                                    print("\n  🧠 Reasoning: \(summary.joined(separator: " "))")
                                }
                                
                            default:
                                // Other output types
                                break
                            }
                        }
                        
                    case "response.output_item.done":
                        if let item = chunk.item {
                            if item.type == "message" {
                                messageCount += 1
                                if let content = item.content {
                                    fullContent += content
                                    // Print content as it arrives
                                    print(content, terminator: "")
                                    fflush(stdout)
                                }
                            }
                        }
                        
                    case "response.done":
                        if let response = chunk.response {
                            print("\n\n  " + String(repeating: "═", count: 70))
                            print("\n  ✅ Research completed!")
                            print("  Status: \(response.status ?? "unknown")")
                            
                            // Usage might be in the response object for done events
                            if let usage = response.usage {
                                print("\n  💰 Token Usage:")
                                print("     - Input tokens: \(usage.inputTokens ?? 0)")
                                if let inputDetails = usage.inputTokensDetails {
                                    print("       - Cached: \(inputDetails.cachedTokens ?? 0)")
                                }
                                print("     - Output tokens: \(usage.outputTokens ?? 0)")
                                if let outputDetails = usage.outputTokensDetails {
                                    print("       - Reasoning: \(outputDetails.reasoningTokens ?? 0)")
                                }
                                print("     - Total tokens: \(usage.totalTokens ?? 0)")
                            }
                        }
                        
                    default:
                        // Other event types
                        break
                    }
                }
                
            }
            
            // Print final statistics if not already shown
            print("\n  📊 Final Statistics:")
            print("     - Total time: \(String(format: "%.1f", Date().timeIntervalSince(startTime))) seconds")
            print("     - Chunks received: \(chunkCount)")
            print("     - Tool calls made: \(toolCallCount)")
            print("     - Message outputs: \(messageCount)")
            print("     - Content length: \(fullContent.count) characters")
            
            // Save the research results
            let resultsPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("deepresearch_results_\(Date().timeIntervalSince1970).md")
            
            let resultsContent = """
            # DeepResearch Results
            
            **Query**: \(researchQuery)
            
            **Model**: \(Models.DeepResearch.o4MiniDeepResearch)
            
            **Date**: \(Date())
            
            **Duration**: \(String(format: "%.1f", Date().timeIntervalSince(startTime))) seconds
            
            **Tool Calls**: \(toolCallCount)
            
            ---
            
            ## Research Findings
            
            \(fullContent)
            
            ---
            
            ## Metadata
            
            - Total chunks: \(chunkCount)
            - Output items: \(outputItems.count)
            - Content length: \(fullContent.count) characters
            """
            
            try resultsContent.write(to: resultsPath, atomically: true, encoding: .utf8)
            print("\n  💾 Results saved to: \(resultsPath.path)")
            
        } catch {
            print("\n  ❌ DeepResearch long test failed: \(error)")
            
            if let openAIError = error as? OpenAIError {
                print("  Error details: \(openAIError.userFriendlyMessage)")
                
                // Print full error for debugging
                switch openAIError {
                case .apiError(let apiError):
                    print("  API Error:")
                    print("    - Message: \(apiError.error.message)")
                    print("    - Type: \(apiError.error.type ?? "unknown")")
                    print("    - Param: \(apiError.error.param ?? "none")")
                    print("    - Code: \(apiError.error.code ?? "none")")
                default:
                    print("  Full error: \(openAIError)")
                }
            }
            
            // Check for common timeout scenarios
            if (error as NSError).domain == NSURLErrorDomain {
                print("\n  💡 Tip: DeepResearch can take a very long time. Consider:")
                print("     - Using background mode for production")
                print("     - Implementing webhooks for completion notifications")
                print("     - Breaking down complex queries into smaller parts")
            }
        }
    }
    
    // Helper to describe JSONValue for display
    private func describeJSONValue(_ value: JSONValue) -> String {
        switch value {
        case .string(let s):
            return s
        case .int(let n):
            return String(n)
        case .double(let n):
            return String(n)
        case .bool(let b):
            return String(b)
        case .array(let arr):
            return "[\(arr.count) items]"
        case .object(let dict):
            if let query = dict["query"] {
                return describeJSONValue(query)
            }
            return "{\(dict.count) fields}"
        case .null:
            return "null"
        }
    }
    
    // Helper function to test raw DeepResearch API for long test
    private func testRawDeepResearchLong() async {
        do {
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "model": "o4-mini-deep-research",
                "input": "What is the capital of France?",
                "tools": [[
                    "type": "web_search_preview"
                ]],
                "max_output_tokens": 100,
                "stream": true
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            
            print("  Raw request JSON: \(String(data: jsonData, encoding: .utf8) ?? "invalid")")
            
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            if let response = httpResponse as? HTTPURLResponse {
                print("  API validation status: \(response.statusCode)")
                
                if response.statusCode == 200 {
                    // For streaming responses, parse the SSE data
                    if let streamData = String(data: data, encoding: .utf8) {
                        print("  Stream preview (first 500 chars):")
                        print("  \(streamData.prefix(500))...")
                        
                        // Parse first few SSE chunks
                        let lines = streamData.components(separatedBy: "\n")
                        var eventCount = 0
                        for line in lines {
                            if line.hasPrefix("data: ") && eventCount < 3 {
                                let jsonStr = String(line.dropFirst(6))
                                if jsonStr != "[DONE]",
                                   let jsonData = jsonStr.data(using: .utf8),
                                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                    eventCount += 1
                                    print("\n  Chunk #\(eventCount) structure:")
                                    print("    Keys: \(json.keys.sorted())")
                                    print("    Type: \(json["type"] ?? "no type")")
                                    if let delta = json["delta"] as? [String: Any] {
                                        print("    Delta keys: \(delta.keys.sorted())")
                                    }
                                    if let item = json["item"] as? [String: Any] {
                                        print("    Item keys: \(item.keys.sorted())")
                                        print("    Item type: \(item["type"] ?? "no type")")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("  Error response: \(errorJson)")
                    }
                }
            }
        } catch {
            print("  API validation failed: \(error)")
        }
    }
}