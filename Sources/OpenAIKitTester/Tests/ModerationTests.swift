import Foundation
import OpenAIKit

struct ModerationTests {
    let output = ConsoleOutput()
    
    func runAll(openAI: OpenAIKit) async {
        await testModeration(openAI: openAI)
    }
    
    func testModeration(openAI: OpenAIKit) async {
        output.startTest("🛡️ Testing Moderation...")
        
        do {
            let request = ModerationRequest(
                input: "This is a completely safe and appropriate message.",
                model: Models.Moderation.omniModerationLatest
            )
            
            let response = try await openAI.moderations.create(request)
            
            output.success("Moderation successful!")
            output.info("Model: \(response.model)")
            if let result = response.results.first {
                output.info("Flagged: \(result.flagged)")
                output.info("Categories: harassment=\(result.categories.harassment), violence=\(result.categories.violence)")
            }
        } catch {
            output.failure("Moderation failed", error: error)
        }
    }
}