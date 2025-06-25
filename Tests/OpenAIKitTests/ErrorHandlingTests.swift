import XCTest
@testable import OpenAIKit

final class ErrorHandlingTests: XCTestCase {
    
    func testOpenAIErrorDescriptions() {
        let invalidURL = OpenAIError.invalidURL
        XCTAssertEqual(invalidURL.errorDescription, "Invalid URL")
        
        let authFailed = OpenAIError.authenticationFailed
        XCTAssertEqual(authFailed.errorDescription, "Authentication failed. Check your API key.")
        
        let rateLimited = OpenAIError.rateLimitExceeded
        XCTAssertEqual(rateLimited.errorDescription, "Rate limit exceeded. Please try again later.")
        
        let clientError = OpenAIError.clientError(statusCode: 400)
        XCTAssertEqual(clientError.errorDescription, "Client error with status code: 400")
        
        let serverError = OpenAIError.serverError(statusCode: 500)
        XCTAssertEqual(serverError.errorDescription, "Server error with status code: 500")
    }
    
    func testAPIErrorDecoding() throws {
        let json = """
        {
            "error": {
                "message": "Invalid API key provided",
                "type": "invalid_request_error",
                "param": "api_key",
                "code": "invalid_api_key"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let apiError = try decoder.decode(APIError.self, from: data)
        
        XCTAssertEqual(apiError.error.message, "Invalid API key provided")
        XCTAssertEqual(apiError.error.type, "invalid_request_error")
        XCTAssertEqual(apiError.error.param, "api_key")
        XCTAssertEqual(apiError.error.code, "invalid_api_key")
    }
    
    func testAPIErrorInOpenAIError() {
        let apiError = APIError(
            error: APIErrorDetail(
                message: "Test error message",
                type: "test_error",
                param: nil,
                code: "test_code"
            )
        )
        
        let openAIError = OpenAIError.apiError(apiError)
        XCTAssertEqual(openAIError.errorDescription, "Test error message")
    }
}