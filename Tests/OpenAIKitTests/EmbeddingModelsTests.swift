import XCTest
@testable import OpenAIKit

final class EmbeddingModelsTests: XCTestCase {
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    override func setUp() {
        super.setUp()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    func testEmbeddingInputString() throws {
        let input = EmbeddingInput.string("Hello, world!")
        
        let encoded = try encoder.encode(input)
        let decoded = try decoder.decode(EmbeddingInput.self, from: encoded)
        
        if case .string(let value) = decoded {
            XCTAssertEqual(value, "Hello, world!")
        } else {
            XCTFail("Expected .string")
        }
    }
    
    func testEmbeddingInputArray() throws {
        let input = EmbeddingInput.array(["Hello", "World"])
        
        let encoded = try encoder.encode(input)
        let decoded = try decoder.decode(EmbeddingInput.self, from: encoded)
        
        if case .array(let values) = decoded {
            XCTAssertEqual(values, ["Hello", "World"])
        } else {
            XCTFail("Expected .array")
        }
    }
    
    func testEmbeddingInputIntArray() throws {
        let input = EmbeddingInput.intArray([1, 2, 3, 4, 5])
        
        let encoded = try encoder.encode(input)
        let decoded = try decoder.decode(EmbeddingInput.self, from: encoded)
        
        if case .intArray(let values) = decoded {
            XCTAssertEqual(values, [1, 2, 3, 4, 5])
        } else {
            XCTFail("Expected .intArray")
        }
    }
    
    func testEmbeddingRequest() throws {
        let request = EmbeddingRequest(
            input: "Test embedding",
            model: "text-embedding-3-small",
            dimensions: 512,
            encodingFormat: .float,
            user: "test-user"
        )
        
        let encoded = try encoder.encode(request)
        let decoded = try decoder.decode(EmbeddingRequest.self, from: encoded)
        
        if case .string(let input) = decoded.input {
            XCTAssertEqual(input, "Test embedding")
        } else {
            XCTFail("Expected string input")
        }
        XCTAssertEqual(decoded.model, request.model)
        XCTAssertEqual(decoded.dimensions, request.dimensions)
        XCTAssertEqual(decoded.encodingFormat, request.encodingFormat)
        XCTAssertEqual(decoded.user, request.user)
    }
    
    func testEmbeddingResponse() throws {
        let json = """
        {
            "object": "list",
            "data": [{
                "object": "embedding",
                "embedding": [0.1, 0.2, 0.3, 0.4, 0.5],
                "index": 0
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
        
        XCTAssertEqual(response.object, "list")
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].object, "embedding")
        XCTAssertEqual(response.data[0].index, 0)
        if case .float(let values) = response.data[0].embedding {
            XCTAssertEqual(values, [0.1, 0.2, 0.3, 0.4, 0.5])
        } else {
            XCTFail("Expected float embedding")
        }
        XCTAssertEqual(response.model, "text-embedding-3-small")
        XCTAssertEqual(response.usage.promptTokens, 5)
        XCTAssertEqual(response.usage.totalTokens, 5)
    }
    
    func testEmbeddingVectorBase64() throws {
        let json = """
        {
            "object": "embedding",
            "embedding": "dGVzdA==",
            "index": 0
        }
        """
        
        let data = json.data(using: .utf8)!
        let embedding = try decoder.decode(Embedding.self, from: data)
        
        if case .base64(let value) = embedding.embedding {
            XCTAssertEqual(value, "dGVzdA==")
        } else {
            XCTFail("Expected base64 embedding")
        }
        
        XCTAssertNil(embedding.embedding.floatValues)
        XCTAssertEqual(embedding.embedding.base64Value, "dGVzdA==")
    }
}