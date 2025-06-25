import XCTest
@testable import OpenAIKit

final class ConfigurationTests: XCTestCase {
    
    func testConfigurationInitialization() {
        let apiKey = "test-api-key"
        let organization = "test-org"
        let project = "test-project"
        
        let config = Configuration(
            apiKey: apiKey,
            organization: organization,
            project: project
        )
        
        XCTAssertEqual(config.apiKey, apiKey)
        XCTAssertEqual(config.organization, organization)
        XCTAssertEqual(config.project, project)
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.openai.com")
        XCTAssertEqual(config.timeoutInterval, 60)
    }
    
    func testConfigurationWithCustomBaseURL() {
        let apiKey = "test-api-key"
        let customURL = URL(string: "https://custom.api.com")!
        let timeout: TimeInterval = 120
        
        let config = Configuration(
            apiKey: apiKey,
            baseURL: customURL,
            timeoutInterval: timeout
        )
        
        XCTAssertEqual(config.apiKey, apiKey)
        XCTAssertNil(config.organization)
        XCTAssertNil(config.project)
        XCTAssertEqual(config.baseURL, customURL)
        XCTAssertEqual(config.timeoutInterval, timeout)
    }
}