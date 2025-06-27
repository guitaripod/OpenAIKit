// DeepResearchStreaming.swift
import Foundation
import OpenAIKit

/// Example of using DeepResearch with streaming for real-time updates
class DeepResearchStreaming {
    let openAI = OpenAIManager.shared.client
    
    /// Stream a DeepResearch query with progress updates
    func streamResearch(query: String) async throws {
        print("🔬 Starting DeepResearch for: \(query)")
        print("Note: DeepResearch can take tens of minutes to complete")
        
        // Create request with appropriate settings for DeepResearch
        let request = ResponseRequest(
            input: query,
            model: Models.DeepResearch.o4MiniDeepResearch,
            tools: [.webSearchPreview(WebSearchPreviewTool())],
            maxOutputTokens: 10000  // High limit for complete responses
        )
        
        var messageContent = ""
        var webSearchCount = 0
        var reasoningCount = 0
        
        // Stream the response
        for try await chunk in openAI.responses.createStream(request) {
            guard let eventType = chunk.type else { continue }
            
            switch eventType {
            case "response.created":
                if let response = chunk.response {
                    print("\n📋 Response ID: \(response.id)")
                    print("📊 Status: \(response.status ?? "unknown")")
                }
                
            case "response.output_item.added":
                if let item = chunk.item {
                    switch item.type {
                    case "web_search_call":
                        webSearchCount += 1
                        print("\n🔍 Web Search #\(webSearchCount) started")
                    case "reasoning":
                        reasoningCount += 1
                        print("\n🧠 Reasoning step #\(reasoningCount)")
                    default:
                        break
                    }
                }
                
            case "response.output_item.done":
                if let item = chunk.item {
                    switch item.type {
                    case "message":
                        if let content = item.content {
                            messageContent += content
                            print("\n✉️ Message content received")
                            print(content)
                        }
                    case "web_search_call":
                        if let toolCall = item.toolCall,
                           case .object(let args) = toolCall.arguments,
                           let query = args["query"],
                           case .string(let searchQuery) = query {
                            print("   ✓ Searched for: \(searchQuery)")
                        }
                    default:
                        break
                    }
                }
                
            case "response.done":
                print("\n" + String(repeating: "=", count: 50))
                if let response = chunk.response {
                    print("✅ Research completed!")
                    print("📊 Final status: \(response.status ?? "unknown")")
                    
                    if let usage = response.usage {
                        print("\n💰 Token usage:")
                        print("   Input: \(usage.inputTokens ?? 0)")
                        print("   Output: \(usage.outputTokens ?? 0)")
                        print("   Total: \(usage.totalTokens ?? 0)")
                    }
                    
                    if response.status == "incomplete" {
                        print("\n⚠️ Response incomplete - hit token limit")
                        print("💡 For complete responses, increase maxOutputTokens or use background mode")
                    }
                }
                
            default:
                // Other event types
                break
            }
        }
        
        print("\n📊 Summary:")
        print("   Web searches performed: \(webSearchCount)")
        print("   Reasoning steps: \(reasoningCount)")
        print("   Message length: \(messageContent.count) characters")
    }
    
    /// Example with background mode for long-running research
    func backgroundResearch(query: String) async throws -> String {
        print("🔬 Starting background DeepResearch...")
        
        let request = ResponseRequest(
            input: query,
            model: Models.DeepResearch.o3DeepResearch,  // More comprehensive model
            tools: [
                .webSearchPreview(WebSearchPreviewTool()),
                .codeInterpreter(CodeInterpreterTool(container: CodeContainer(type: "auto")))
            ],
            maxOutputTokens: 20000,  // Very high limit for comprehensive research
            background: true  // Enable background mode
        )
        
        let response = try await openAI.responses.create(request)
        
        print("📋 Background task created: \(response.id)")
        print("⏱️ Check status with: openAI.responses.get(id: \"\(response.id)\")")
        
        // In production, you would:
        // 1. Store the response ID
        // 2. Set up a webhook or polling mechanism
        // 3. Check status periodically until complete
        
        return response.id
    }
}

// Usage example
let researcher = DeepResearchStreaming()

// Stream a research query
Task {
    do {
        try await researcher.streamResearch(
            query: "What are the latest breakthroughs in quantum computing in 2024?"
        )
    } catch {
        print("❌ Research failed: \(error)")
    }
}

// Or use background mode for long research
Task {
    do {
        let taskId = try await researcher.backgroundResearch(
            query: "Comprehensive analysis of AI safety research with citations"
        )
        print("Research task ID: \(taskId)")
    } catch {
        print("❌ Failed to start research: \(error)")
    }
}