import Foundation

struct TestConfiguration {
    let apiKey: String
    let verbose: Bool
    let timeout: TimeInterval
    
    static func fromEnvironment() -> TestConfiguration {
        return TestConfiguration(
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_API_KEY_HERE",
            verbose: ProcessInfo.processInfo.environment["VERBOSE"] == "true",
            timeout: 120.0
        )
    }
    
    static func forDeepResearch() -> TestConfiguration {
        return TestConfiguration(
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_API_KEY_HERE",
            verbose: true,
            timeout: 3600.0  // 1 hour for DeepResearch
        )
    }
}