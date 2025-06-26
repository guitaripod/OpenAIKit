import XCTest
@testable import OpenAIKit

final class OpenAIKitTests: XCTestCase {
    
    func testOpenAIKitInitialization() {
        let apiKey = "test-api-key"
        let client = OpenAIKit(apiKey: apiKey)
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.chat)
        XCTAssertNotNil(client.audio)
        XCTAssertNotNil(client.images)
        XCTAssertNotNil(client.embeddings)
        XCTAssertNotNil(client.models)
        XCTAssertNotNil(client.moderations)
        XCTAssertNotNil(client.files)
        XCTAssertNotNil(client.fineTuning)
        XCTAssertNotNil(client.assistants)
        XCTAssertNotNil(client.threads)
        XCTAssertNotNil(client.vectorStores)
        XCTAssertNotNil(client.batches)
    }
    
    func testOpenAIKitInitializationWithConfiguration() {
        let config = Configuration(
            apiKey: "test-api-key",
            organization: "test-org",
            project: "test-project",
            baseURL: URL(string: "https://custom.api.com")!,
            timeoutInterval: 120
        )
        
        let client = OpenAIKit(configuration: config)
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.chat)
        XCTAssertNotNil(client.audio)
        XCTAssertNotNil(client.images)
        XCTAssertNotNil(client.embeddings)
        XCTAssertNotNil(client.models)
        XCTAssertNotNil(client.moderations)
        XCTAssertNotNil(client.files)
        XCTAssertNotNil(client.fineTuning)
        XCTAssertNotNil(client.assistants)
        XCTAssertNotNil(client.threads)
        XCTAssertNotNil(client.vectorStores)
        XCTAssertNotNil(client.batches)
    }
}