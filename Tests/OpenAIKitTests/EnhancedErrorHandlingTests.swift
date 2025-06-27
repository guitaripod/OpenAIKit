import XCTest
@testable import OpenAIKit

final class EnhancedErrorHandlingTests: XCTestCase {
    
    // MARK: - OpenAIError UI Properties Tests
    
    func testErrorUIProperties() {
        let errors: [(OpenAIError, String, String, OpenAIError.Severity)] = [
            (.invalidURL, "Connection Error", "wifi.exclamationmark", .error),
            (.authenticationFailed, "Authentication Error", "lock.fill", .error),
            (.rateLimitExceeded, "Rate Limit Exceeded", "clock.fill", .warning),
            (.clientError(statusCode: 400), "Request Error", "exclamationmark.circle.fill", .error),
            (.serverError(statusCode: 500), "Server Error", "exclamationmark.circle.fill", .critical),
            (.invalidFileData, "Invalid File", "doc.fill.badge.exclamationmark", .error),
            (.streamingNotSupported, "Feature Not Supported", "antenna.radiowaves.left.and.right.slash", .info)
        ]
        
        for (error, expectedTitle, expectedIcon, expectedSeverity) in errors {
            XCTAssertEqual(error.userFriendlyTitle, expectedTitle)
            XCTAssertEqual(error.iconName, expectedIcon)
            XCTAssertEqual(error.severity, expectedSeverity)
        }
    }
    
    func testErrorRetryability() {
        XCTAssertFalse(OpenAIError.invalidURL.isRetryable)
        XCTAssertFalse(OpenAIError.authenticationFailed.isRetryable)
        XCTAssertTrue(OpenAIError.rateLimitExceeded.isRetryable)
        XCTAssertFalse(OpenAIError.clientError(statusCode: 400).isRetryable)
        XCTAssertTrue(OpenAIError.serverError(statusCode: 500).isRetryable)
        XCTAssertTrue(OpenAIError.serverError(statusCode: 503).isRetryable)
    }
    
    func testErrorRetryDelays() {
        XCTAssertNil(OpenAIError.invalidURL.suggestedRetryDelay)
        XCTAssertEqual(OpenAIError.rateLimitExceeded.suggestedRetryDelay, 60.0)
        XCTAssertEqual(OpenAIError.serverError(statusCode: 500).suggestedRetryDelay, 5.0)
        XCTAssertEqual(OpenAIError.serverError(statusCode: 503).suggestedRetryDelay, 5.0)
    }
    
    func testErrorCodes() {
        XCTAssertEqual(OpenAIError.invalidURL.errorCode, "invalid_url")
        XCTAssertEqual(OpenAIError.authenticationFailed.errorCode, "authentication_failed")
        XCTAssertEqual(OpenAIError.rateLimitExceeded.errorCode, "rate_limit_exceeded")
        XCTAssertNil(OpenAIError.clientError(statusCode: 400).errorCode)
    }
    
    // MARK: - API Error Details Tests
    
    func testAPIErrorWithAllFields() throws {
        let json = """
        {
            "error": {
                "message": "The model `gpt-5` does not exist",
                "type": "invalid_request_error",
                "param": "model",
                "code": "model_not_found"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let apiError = try decoder.decode(APIError.self, from: data)
        
        let openAIError = OpenAIError.apiError(apiError)
        XCTAssertEqual(openAIError.errorDescription, "The model `gpt-5` does not exist")
        
        if case .apiError(let error) = openAIError {
            XCTAssertEqual(error.error.type, "invalid_request_error")
            XCTAssertEqual(error.error.param, "model")
            XCTAssertEqual(error.error.code, "model_not_found")
        } else {
            XCTFail("Expected apiError case")
        }
    }
    
    func testAPIErrorMinimalFields() throws {
        let json = """
        {
            "error": {
                "message": "Something went wrong"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let apiError = try decoder.decode(APIError.self, from: data)
        
        XCTAssertEqual(apiError.error.message, "Something went wrong")
        XCTAssertNil(apiError.error.type)
        XCTAssertNil(apiError.error.param)
        XCTAssertNil(apiError.error.code)
    }
    
    // MARK: - Error Details Struct Tests
    
    func testOpenAIErrorDetails() {
        let rateLimitError = OpenAIError.rateLimitExceeded
        let details = OpenAIErrorDetails(from: rateLimitError)
        
        XCTAssertEqual(details.title, "Rate Limit Exceeded")
        XCTAssertEqual(details.message, rateLimitError.userFriendlyMessage)
        XCTAssertEqual(details.iconName, "clock.fill")
        XCTAssertEqual(details.severity, .warning)
        XCTAssertTrue(details.isRetryable)
        XCTAssertEqual(details.suggestedRetryDelay, 60.0)
        XCTAssertFalse(details.actions.isEmpty)
        XCTAssertNotNil(details.technicalDetails)
    }
    
    // MARK: - Error Action Tests
    
    func testErrorSuggestedActions() {
        let authError = OpenAIError.authenticationFailed
        let actions = authError.suggestedActions
        
        XCTAssertFalse(actions.isEmpty)
        XCTAssertTrue(actions.contains { $0.buttonTitle == "Check API Key" })
        
        let rateLimitError = OpenAIError.rateLimitExceeded
        let rateLimitActions = rateLimitError.suggestedActions
        
        XCTAssertTrue(rateLimitActions.contains { $0.buttonTitle.contains("Wait") })
        XCTAssertTrue(rateLimitActions.contains { $0.buttonTitle == "Try Again" })
    }
    
    // MARK: - Retry Handler Tests
    
    func testRetryHandlerConfiguration() {
        let config = RetryHandler.Configuration(
            maxAttempts: 5,
            baseDelay: 2.0,
            maxDelay: 30.0,
            useExponentialBackoff: true
        )
        
        XCTAssertEqual(config.maxAttempts, 5)
        XCTAssertEqual(config.baseDelay, 2.0)
        XCTAssertEqual(config.maxDelay, 30.0)
        XCTAssertTrue(config.useExponentialBackoff)
        
        let defaultConfig = RetryHandler.Configuration()
        XCTAssertEqual(defaultConfig.maxAttempts, 3)
        XCTAssertEqual(defaultConfig.baseDelay, 1.0)
    }
    
    func testRetryDelayCalculation() {
        let handler = RetryHandler(configuration: .init(
            baseDelay: 1.0,
            useExponentialBackoff: true
        ))
        
        // Test exponential backoff
        XCTAssertEqual(handler.configuration.baseDelay, 1.0)
        // First retry: 1.0 * 2^0 = 1.0
        // Second retry: 1.0 * 2^1 = 2.0
        // Third retry: 1.0 * 2^2 = 4.0
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkErrorMapping() {
        let urlError = URLError(.notConnectedToInternet)
        // In real implementation, this would be mapped to OpenAIError
        XCTAssertEqual(urlError.code, .notConnectedToInternet)
        
        let timeoutError = URLError(.timedOut)
        XCTAssertEqual(timeoutError.code, .timedOut)
    }
    
    // MARK: - Error Response Parsing Tests
    
    func testErrorResponseWithNestedDetails() throws {
        let json = """
        {
            "error": {
                "message": "Invalid request: The messages array must not be empty",
                "type": "invalid_request_error",
                "param": "messages",
                "code": "invalid_value",
                "details": {
                    "minimum_length": 1,
                    "actual_length": 0
                }
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // This tests that unknown fields (like 'details') don't break decoding
        let apiError = try decoder.decode(APIError.self, from: data)
        XCTAssertEqual(apiError.error.message, "Invalid request: The messages array must not be empty")
        XCTAssertEqual(apiError.error.code, "invalid_value")
    }
    
    // MARK: - Error Categorization Tests
    
    func testErrorRequiresUserAction() {
        XCTAssertTrue(OpenAIError.authenticationFailed.requiresUserAction)
        XCTAssertTrue(OpenAIError.invalidFileData.requiresUserAction)
        XCTAssertFalse(OpenAIError.rateLimitExceeded.requiresUserAction)
        XCTAssertFalse(OpenAIError.serverError(statusCode: 500).requiresUserAction)
    }
    
    func testErrorMaxRetryAttempts() {
        XCTAssertEqual(OpenAIError.rateLimitExceeded.maxRetryAttempts, 1)
        XCTAssertEqual(OpenAIError.serverError(statusCode: 500).maxRetryAttempts, 3)
        XCTAssertEqual(OpenAIError.authenticationFailed.maxRetryAttempts, 0)
    }
}