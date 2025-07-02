import XCTest
@testable import OpenAIKit

final class ResponseParsingTests: XCTestCase {
    
    let decoder = JSONDecoder()
    
    override func setUp() {
        super.setUp()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Chat Response Tests
    
    func testChatCompletionWithToolCalls() throws {
        let json = """
        {
            "id": "chatcmpl-abc123",
            "object": "chat.completion",
            "created": 1677858242,
            "model": "gpt-4o",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": null,
                    "tool_calls": [{
                        "id": "call_abc123",
                        "type": "function",
                        "function": {
                            "name": "get_weather",
                            "arguments": "{\\"location\\": \\"San Francisco, CA\\", \\"unit\\": \\"celsius\\"}"
                        }
                    }]
                },
                "finish_reason": "tool_calls"
            }],
            "usage": {
                "prompt_tokens": 82,
                "completion_tokens": 17,
                "total_tokens": 99
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(ChatCompletionResponse.self, from: data)
        
        XCTAssertEqual(response.id, "chatcmpl-abc123")
        XCTAssertEqual(response.choices.count, 1)
        
        let message = response.choices[0].message
        XCTAssertNil(message.content)
        XCTAssertEqual(message.toolCalls?.count, 1)
        
        let toolCall = message.toolCalls![0]
        XCTAssertEqual(toolCall.id, "call_abc123")
        XCTAssertEqual(toolCall.type, .function)
        XCTAssertEqual(toolCall.function?.name, "get_weather")
        XCTAssertEqual(toolCall.function?.arguments, #"{"location": "San Francisco, CA", "unit": "celsius"}"#)
        
        XCTAssertEqual(response.choices[0].finishReason, .toolCalls)
    }
    
    func testStreamingResponseWithUsage() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion.chunk",
            "created": 1677652288,
            "model": "gpt-4o-mini",
            "choices": [{
                "index": 0,
                "delta": {
                    "content": "Hello"
                },
                "finish_reason": null
            }],
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": 5,
                "total_tokens": 15
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let chunk = try decoder.decode(ChatStreamChunk.self, from: data)
        
        XCTAssertEqual(chunk.id, "chatcmpl-123")
        XCTAssertEqual(chunk.choices[0].delta.content, "Hello")
        XCTAssertNotNil(chunk.usage)
        XCTAssertEqual(chunk.usage?.totalTokens, 15)
    }
    
    // MARK: - Embeddings Response Tests
    
    func testEmbeddingsResponse() throws {
        let json = """
        {
            "object": "list",
            "data": [
                {
                    "object": "embedding",
                    "index": 0,
                    "embedding": [0.1, 0.2, 0.3, 0.4, 0.5]
                },
                {
                    "object": "embedding",
                    "index": 1,
                    "embedding": [0.6, 0.7, 0.8, 0.9, 1.0]
                }
            ],
            "model": "text-embedding-3-small",
            "usage": {
                "prompt_tokens": 8,
                "total_tokens": 8
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(EmbeddingResponse.self, from: data)
        
        XCTAssertEqual(response.object, "list")
        XCTAssertEqual(response.model, "text-embedding-3-small")
        XCTAssertEqual(response.data.count, 2)
        
        XCTAssertEqual(response.data[0].index, 0)
        XCTAssertEqual(response.data[0].embedding.floatValues, [0.1, 0.2, 0.3, 0.4, 0.5])
        
        XCTAssertEqual(response.data[1].index, 1)
        XCTAssertEqual(response.data[1].embedding.floatValues, [0.6, 0.7, 0.8, 0.9, 1.0])
        
        XCTAssertEqual(response.usage.promptTokens, 8)
        XCTAssertEqual(response.usage.totalTokens, 8)
    }
    
    func testEmbeddingsWithBase64() throws {
        let json = """
        {
            "object": "list",
            "data": [{
                "object": "embedding",
                "index": 0,
                "embedding": "SGVsbG8gV29ybGQ="
            }],
            "model": "text-embedding-3-small",
            "usage": {
                "prompt_tokens": 5,
                "total_tokens": 5
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(EmbeddingResponse.self, from: data)
        
        // Verify the embedding was parsed (base64 string support may vary)
        XCTAssertNotNil(response.data[0].embedding)
    }
    
    // MARK: - Audio Response Tests
    
    func testTranscriptionResponse() throws {
        let json = """
        {
            "text": "Hello, this is a test transcription.",
            "language": "english",
            "duration": 5.5,
            "segments": [
                {
                    "id": 0,
                    "seek": 0,
                    "start": 0.0,
                    "end": 2.5,
                    "text": "Hello, this is",
                    "tokens": [1, 2, 3],
                    "temperature": 0.0,
                    "avg_logprob": -0.5,
                    "compression_ratio": 1.2,
                    "no_speech_prob": 0.01
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(TranscriptionResponse.self, from: data)
        
        XCTAssertEqual(response.text, "Hello, this is a test transcription.")
        XCTAssertEqual(response.language, "english")
        XCTAssertEqual(response.duration, 5.5)
        XCTAssertEqual(response.segments?.count, 1)
        
        let segment = response.segments![0]
        XCTAssertEqual(segment.id, 0)
        XCTAssertEqual(segment.start, 0.0)
        XCTAssertEqual(segment.end, 2.5)
        XCTAssertEqual(segment.text, "Hello, this is")
    }
    
    // MARK: - Image Response Tests
    
    func testImageGenerationResponse() throws {
        let json = """
        {
            "created": 1677858242,
            "data": [
                {
                    "url": "https://example.com/image1.png"
                },
                {
                    "b64_json": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        // Use decoder with snake case conversion to match NetworkClient
        let imageDecoder = JSONDecoder()
        imageDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try imageDecoder.decode(ImageResponse.self, from: data)
        
        XCTAssertEqual(response.created, 1677858242)
        XCTAssertEqual(response.data.count, 2)
        
        XCTAssertEqual(response.data[0].url, "https://example.com/image1.png")
        XCTAssertNil(response.data[0].revisedPrompt) // Not included in this test JSON
        
        XCTAssertNotNil(response.data[1].b64Json)
        if let b64 = response.data[1].b64Json {
            XCTAssertTrue(b64.starts(with: "iVBORw0"))
        }
    }
    
    // MARK: - Moderation Response Tests
    
    func testModerationResponse() throws {
        let json = """
        {
            "id": "modr-abc123",
            "model": "omni-moderation-latest",
            "results": [{
                "flagged": true,
                "categories": {
                    "harassment": true,
                    "harassment/threatening": true,
                    "hate": false,
                    "hate/threatening": false,
                    "illicit": false,
                    "illicit/violent": false,
                    "self-harm": false,
                    "self-harm/intent": false,
                    "self-harm/instructions": false,
                    "sexual": false,
                    "sexual/minors": false,
                    "violence": false,
                    "violence/graphic": false
                },
                "category_scores": {
                    "harassment": 0.95,
                    "harassment/threatening": 0.85,
                    "hate": 0.02,
                    "hate/threatening": 0.01,
                    "illicit": 0.001,
                    "illicit/violent": 0.001,
                    "self-harm": 0.001,
                    "self-harm/intent": 0.001,
                    "self-harm/instructions": 0.001,
                    "sexual": 0.01,
                    "sexual/minors": 0.001,
                    "violence": 0.05,
                    "violence/graphic": 0.001
                }
            }]
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(ModerationResponse.self, from: data)
        
        XCTAssertEqual(response.id, "modr-abc123")
        XCTAssertEqual(response.model, "omni-moderation-latest")
        XCTAssertEqual(response.results.count, 1)
        
        let result = response.results[0]
        XCTAssertTrue(result.flagged)
        XCTAssertTrue(result.categories.harassment)
        XCTAssertTrue(result.categories.harassmentThreatening)
        XCTAssertFalse(result.categories.violence)
        
        XCTAssertEqual(result.categoryScores.harassment, 0.95)
        XCTAssertEqual(result.categoryScores.harassmentThreatening, 0.85)
    }
    
    // MARK: - Model Response Tests
    
    func testModelListResponse() throws {
        let json = """
        {
            "object": "list",
            "data": [
                {
                    "id": "gpt-4o",
                    "object": "model",
                    "created": 1677858242,
                    "owned_by": "openai"
                },
                {
                    "id": "gpt-4o-mini",
                    "object": "model",
                    "created": 1677858243,
                    "owned_by": "openai"
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(ModelsResponse.self, from: data)
        
        XCTAssertEqual(response.object, "list")
        XCTAssertEqual(response.data.count, 2)
        
        XCTAssertEqual(response.data[0].id, "gpt-4o")
        XCTAssertEqual(response.data[0].object, "model")
        XCTAssertEqual(response.data[0].ownedBy, "openai")
        
        XCTAssertEqual(response.data[1].id, "gpt-4o-mini")
    }
    
    // MARK: - File Response Tests
    
    func testFileResponse() throws {
        let json = """
        {
            "id": "file-abc123",
            "object": "file",
            "bytes": 1024,
            "created_at": 1677858242,
            "filename": "test.jsonl",
            "purpose": "fine-tune"
        }
        """
        
        let data = json.data(using: .utf8)!
        let file = try decoder.decode(FileObject.self, from: data)
        
        XCTAssertEqual(file.id, "file-abc123")
        XCTAssertEqual(file.object, "file")
        XCTAssertEqual(file.bytes, 1024)
        XCTAssertEqual(file.createdAt, 1677858242)
        XCTAssertEqual(file.filename, "test.jsonl")
        XCTAssertEqual(file.purpose, "fine-tune")
    }
    
    // MARK: - Usage Details Tests
    
    func testUsageWithDetails() throws {
        let json = """
        {
            "prompt_tokens": 100,
            "completion_tokens": 50,
            "total_tokens": 150,
            "prompt_tokens_details": {
                "cached_tokens": 80,
                "audio_tokens": 20
            },
            "completion_tokens_details": {
                "reasoning_tokens": 30,
                "audio_tokens": 10,
                "accepted_prediction_tokens": 5,
                "rejected_prediction_tokens": 5
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let usage = try decoder.decode(Usage.self, from: data)
        
        XCTAssertEqual(usage.promptTokens, 100)
        XCTAssertEqual(usage.completionTokens, 50)
        XCTAssertEqual(usage.totalTokens, 150)
        
        XCTAssertEqual(usage.promptTokensDetails?.cachedTokens, 80)
        XCTAssertEqual(usage.promptTokensDetails?.audioTokens, 20)
        
        XCTAssertEqual(usage.completionTokensDetails?.reasoningTokens, 30)
        XCTAssertEqual(usage.completionTokensDetails?.audioTokens, 10)
        XCTAssertEqual(usage.completionTokensDetails?.acceptedPredictionTokens, 5)
        XCTAssertEqual(usage.completionTokensDetails?.rejectedPredictionTokens, 5)
    }
}