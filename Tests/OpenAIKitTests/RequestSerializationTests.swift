import XCTest
@testable import OpenAIKit

final class RequestSerializationTests: XCTestCase {
    
    let encoder = JSONEncoder()
    
    override func setUp() {
        super.setUp()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: - Chat Request Tests
    
    func testChatCompletionRequestSerialization() throws {
        let request = ChatCompletionRequest(
            messages: [
                ChatMessage(role: .system, content: "You are a helpful assistant."),
                ChatMessage(role: .user, content: "Hello!")
            ],
            model: "gpt-4o",
            frequencyPenalty: 0.5,
            logitBias: ["50256": -100],
            logprobs: true,
            maxCompletionTokens: 100,
            n: 1,
            presencePenalty: 0.2,
            responseFormat: ResponseFormat(type: .jsonObject),
            seed: 12345,
            stop: .string("\\n"),
            stream: false,
            temperature: 0.7,
            topLogprobs: 3,
            topP: 0.9,
            user: "test-user"
        )
        
        let encoded = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["model"] as? String, "gpt-4o")
        XCTAssertEqual(json["frequency_penalty"] as? Double, 0.5)
        XCTAssertEqual(json["presence_penalty"] as? Double, 0.2)
        XCTAssertEqual(json["temperature"] as? Double, 0.7)
        XCTAssertEqual(json["top_p"] as? Double, 0.9)
        XCTAssertEqual(json["max_completion_tokens"] as? Int, 100)
        XCTAssertEqual(json["n"] as? Int, 1)
        XCTAssertEqual(json["seed"] as? Int, 12345)
        XCTAssertEqual(json["user"] as? String, "test-user")
        XCTAssertEqual(json["stream"] as? Bool, false)
        XCTAssertEqual(json["logprobs"] as? Bool, true)
        XCTAssertEqual(json["top_logprobs"] as? Int, 3)
        
        let messages = json["messages"] as! [[String: Any]]
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0]["role"] as? String, "system")
        XCTAssertEqual(messages[0]["content"] as? String, "You are a helpful assistant.")
        XCTAssertEqual(messages[1]["role"] as? String, "user")
        XCTAssertEqual(messages[1]["content"] as? String, "Hello!")
        
        let responseFormat = json["response_format"] as! [String: Any]
        XCTAssertEqual(responseFormat["type"] as? String, "json_object")
        
        let logitBias = json["logit_bias"] as! [String: Int]
        XCTAssertEqual(logitBias["50256"], -100)
    }
    
    func testChatRequestWithTools() throws {
        let weatherFunction = Tool(
            type: .function,
            function: Function(
                name: "get_weather",
                description: "Get the current weather",
                parameters: [
                    "type": "object",
                    "properties": [
                        "location": [
                            "type": "string",
                            "description": "The city and state"
                        ]
                    ],
                    "required": ["location"]
                ]
            )
        )
        
        let request = ChatCompletionRequest(
            messages: [ChatMessage(role: .user, content: "What's the weather?")],
            model: "gpt-4o",
            toolChoice: .function(name: "get_weather"),
            tools: [weatherFunction]
        )
        
        let encoded = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        let tools = json["tools"] as! [[String: Any]]
        XCTAssertEqual(tools.count, 1)
        XCTAssertEqual(tools[0]["type"] as? String, "function")
        
        let function = tools[0]["function"] as! [String: Any]
        XCTAssertEqual(function["name"] as? String, "get_weather")
        XCTAssertEqual(function["description"] as? String, "Get the current weather")
        
        let toolChoice = json["tool_choice"] as! [String: Any]
        XCTAssertEqual(toolChoice["type"] as? String, "function")
        let toolChoiceFunction = toolChoice["function"] as! [String: String]
        XCTAssertEqual(toolChoiceFunction["name"], "get_weather")
    }
    
    // MARK: - Embeddings Request Tests
    
    func testEmbeddingRequestSerialization() throws {
        let request = EmbeddingRequest(
            input: ["Hello world", "How are you?"],
            model: "text-embedding-3-small",
            dimensions: 512,
            encodingFormat: .float,
            user: "test-user"
        )
        
        let encoded = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["model"] as? String, "text-embedding-3-small")
        XCTAssertEqual(json["encoding_format"] as? String, "float")
        XCTAssertEqual(json["dimensions"] as? Int, 512)
        XCTAssertEqual(json["user"] as? String, "test-user")
        
        let input = json["input"] as! [String]
        XCTAssertEqual(input, ["Hello world", "How are you?"])
    }
    
    // MARK: - Audio Request Tests
    
    func testTranscriptionRequestSerialization() throws {
        let audioData = "test audio data".data(using: .utf8)!
        let request = TranscriptionRequest(
            file: audioData,
            fileName: "audio.mp3",
            model: "whisper-1",
            language: "en",
            prompt: "This is a test",
            responseFormat: .json,
            temperature: 0.5,
            timestampGranularities: [.segment, .word]
        )
        
        // Note: Audio requests use multipart form data, so we can't test full serialization
        // But we can verify the properties are set correctly
        XCTAssertEqual(request.fileName, "audio.mp3")
        XCTAssertEqual(request.model, "whisper-1")
        XCTAssertEqual(request.language, "en")
        XCTAssertEqual(request.prompt, "This is a test")
        XCTAssertEqual(request.responseFormat, .json)
        XCTAssertEqual(request.temperature, 0.5)
        XCTAssertEqual(request.timestampGranularities, [.segment, .word])
    }
    
    func testSpeechRequestSerialization() throws {
        let request = SpeechRequest(
            input: "Hello, world!",
            model: "tts-1",
            voice: .alloy,
            responseFormat: .mp3,
            speed: 1.5
        )
        
        let encoded = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["input"] as? String, "Hello, world!")
        XCTAssertEqual(json["model"] as? String, "tts-1")
        XCTAssertEqual(json["voice"] as? String, "alloy")
        XCTAssertEqual(json["response_format"] as? String, "mp3")
        XCTAssertEqual(json["speed"] as? Double, 1.5)
    }
    
    // MARK: - Image Request Tests
    
    func testImageGenerationRequestSerialization() throws {
        let request = ImageGenerationRequest(
            prompt: "A beautiful sunset",
            model: "dall-e-3",
            n: 1,
            quality: "hd",
            responseFormat: .url,
            size: "1024x1024",
            style: "vivid",
            user: "test-user"
        )
        
        let encoded = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["prompt"] as? String, "A beautiful sunset")
        XCTAssertEqual(json["model"] as? String, "dall-e-3")
        XCTAssertEqual(json["n"] as? Int, 1)
        XCTAssertEqual(json["quality"] as? String, "hd")
        XCTAssertEqual(json["response_format"] as? String, "url")
        XCTAssertEqual(json["size"] as? String, "1024x1024")
        XCTAssertEqual(json["style"] as? String, "vivid")
        XCTAssertEqual(json["user"] as? String, "test-user")
    }
    
    // MARK: - Moderation Request Tests
    
    func testModerationRequestSerialization() throws {
        let request = ModerationRequest(
            input: ["This is a test", "Another test"],
            model: "omni-moderation-latest"
        )
        
        let encoded = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        XCTAssertEqual(json["model"] as? String, "omni-moderation-latest")
        
        let input = json["input"] as! [String]
        XCTAssertEqual(input, ["This is a test", "Another test"])
    }
    
    // MARK: - Files Request Tests
    
    func testFileRequestProperties() throws {
        let fileData = "test file content".data(using: .utf8)!
        let request = FileRequest(
            file: fileData,
            fileName: "test.txt",
            purpose: .fineTune
        )
        
        XCTAssertEqual(request.fileName, "test.txt")
        XCTAssertEqual(request.purpose, .fineTune)
        XCTAssertEqual(request.file.count, fileData.count)
    }
    
    // MARK: - Response Format Tests
    
    func testResponseFormatSerialization() throws {
        let textFormat = ResponseFormat(type: .text)
        let jsonFormat = ResponseFormat(type: .jsonObject)
        let jsonSchemaFormat = ResponseFormat(
            type: .jsonSchema,
            jsonSchema: JSONSchema(
                name: "test_schema",
                schema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"]
                    ],
                    "required": ["name"]
                ],
                strict: true
            )
        )
        
        let encodedText = try encoder.encode(textFormat)
        let jsonText = try JSONSerialization.jsonObject(with: encodedText) as! [String: Any]
        XCTAssertEqual(jsonText["type"] as? String, "text")
        
        let encodedJson = try encoder.encode(jsonFormat)
        let jsonJson = try JSONSerialization.jsonObject(with: encodedJson) as! [String: Any]
        XCTAssertEqual(jsonJson["type"] as? String, "json_object")
        
        let encodedSchema = try encoder.encode(jsonSchemaFormat)
        let jsonSchema = try JSONSerialization.jsonObject(with: encodedSchema) as! [String: Any]
        XCTAssertEqual(jsonSchema["type"] as? String, "json_schema")
        
        let schemaObject = jsonSchema["json_schema"] as! [String: Any]
        XCTAssertEqual(schemaObject["name"] as? String, "test_schema")
        XCTAssertEqual(schemaObject["strict"] as? Bool, true)
        XCTAssertNotNil(schemaObject["schema"])
    }
}