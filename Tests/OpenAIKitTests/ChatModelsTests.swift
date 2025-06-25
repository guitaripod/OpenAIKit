import XCTest
@testable import OpenAIKit

final class ChatModelsTests: XCTestCase {
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    override func setUp() {
        super.setUp()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    func testChatMessageEncodingDecoding() throws {
        let message = ChatMessage(
            role: .user,
            content: .string("Hello, world!"),
            name: "TestUser"
        )
        
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(ChatMessage.self, from: encoded)
        
        XCTAssertEqual(decoded.role, message.role)
        if case .string(let content) = decoded.content,
           case .string(let originalContent) = message.content {
            XCTAssertEqual(content, originalContent)
        } else {
            XCTFail("Content mismatch")
        }
        XCTAssertEqual(decoded.name, message.name)
    }
    
    func testChatMessageWithParts() throws {
        let parts = [
            MessagePart(type: .text, text: "Check out this image:"),
            MessagePart(type: .imageUrl, imageUrl: ImageURL(url: "https://example.com/image.png", detail: .high))
        ]
        
        let message = ChatMessage(
            role: .user,
            content: .parts(parts)
        )
        
        let encoded = try encoder.encode(message)
        let decoded = try decoder.decode(ChatMessage.self, from: encoded)
        
        XCTAssertEqual(decoded.role, message.role)
        if case .parts(let decodedParts) = decoded.content,
           case .parts(let originalParts) = message.content {
            XCTAssertEqual(decodedParts.count, originalParts.count)
            XCTAssertEqual(decodedParts[0].type, originalParts[0].type)
            XCTAssertEqual(decodedParts[0].text, originalParts[0].text)
            XCTAssertEqual(decodedParts[1].type, originalParts[1].type)
            XCTAssertEqual(decodedParts[1].imageUrl?.url, originalParts[1].imageUrl?.url)
            XCTAssertEqual(decodedParts[1].imageUrl?.detail, originalParts[1].imageUrl?.detail)
        } else {
            XCTFail("Content parts mismatch")
        }
    }
    
    func testChatCompletionResponse() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "gpt-4o",
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "Hello! How can I help you today?"
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": 9,
                "completion_tokens": 12,
                "total_tokens": 21
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(ChatCompletionResponse.self, from: data)
        
        XCTAssertEqual(response.id, "chatcmpl-123")
        XCTAssertEqual(response.object, "chat.completion")
        XCTAssertEqual(response.created, 1677652288)
        XCTAssertEqual(response.model, "gpt-4o")
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].index, 0)
        XCTAssertEqual(response.choices[0].message.role, .assistant)
        if case .string(let content) = response.choices[0].message.content {
            XCTAssertEqual(content, "Hello! How can I help you today?")
        } else {
            XCTFail("Message content mismatch")
        }
        XCTAssertEqual(response.choices[0].finishReason, .stop)
        XCTAssertEqual(response.usage?.promptTokens, 9)
        XCTAssertEqual(response.usage?.completionTokens, 12)
        XCTAssertEqual(response.usage?.totalTokens, 21)
    }
    
    func testStreamChunk() throws {
        let json = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion.chunk",
            "created": 1677652288,
            "model": "gpt-4o",
            "choices": [{
                "index": 0,
                "delta": {
                    "content": "Hello"
                },
                "finish_reason": null
            }]
        }
        """
        
        let data = json.data(using: .utf8)!
        let chunk = try decoder.decode(ChatStreamChunk.self, from: data)
        
        XCTAssertEqual(chunk.id, "chatcmpl-123")
        XCTAssertEqual(chunk.object, "chat.completion.chunk")
        XCTAssertEqual(chunk.created, 1677652288)
        XCTAssertEqual(chunk.model, "gpt-4o")
        XCTAssertEqual(chunk.choices.count, 1)
        XCTAssertEqual(chunk.choices[0].delta.content, "Hello")
        XCTAssertNil(chunk.choices[0].finishReason)
    }
    
    func testToolChoice() throws {
        let none = ToolChoice.none
        let auto = ToolChoice.auto
        let required = ToolChoice.required
        let function = ToolChoice.function(name: "get_weather")
        
        let encodedNone = try encoder.encode(none)
        let decodedNone = try decoder.decode(ToolChoice.self, from: encodedNone)
        if case .none = decodedNone {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .none")
        }
        
        let encodedAuto = try encoder.encode(auto)
        let decodedAuto = try decoder.decode(ToolChoice.self, from: encodedAuto)
        if case .auto = decodedAuto {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .auto")
        }
        
        let encodedRequired = try encoder.encode(required)
        let decodedRequired = try decoder.decode(ToolChoice.self, from: encodedRequired)
        if case .required = decodedRequired {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .required")
        }
        
        let encodedFunction = try encoder.encode(function)
        let decodedFunction = try decoder.decode(ToolChoice.self, from: encodedFunction)
        if case .function(let name) = decodedFunction {
            XCTAssertEqual(name, "get_weather")
        } else {
            XCTFail("Expected .function")
        }
    }
    
    func testStopSequence() throws {
        let string = StopSequence.string("\n")
        let array = StopSequence.array(["\n", ".", "!"])
        
        let encodedString = try encoder.encode(string)
        let decodedString = try decoder.decode(StopSequence.self, from: encodedString)
        if case .string(let value) = decodedString {
            XCTAssertEqual(value, "\n")
        } else {
            XCTFail("Expected .string")
        }
        
        let encodedArray = try encoder.encode(array)
        let decodedArray = try decoder.decode(StopSequence.self, from: encodedArray)
        if case .array(let values) = decodedArray {
            XCTAssertEqual(values, ["\n", ".", "!"])
        } else {
            XCTFail("Expected .array")
        }
    }
}