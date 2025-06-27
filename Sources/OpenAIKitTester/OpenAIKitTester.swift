import Foundation

@main
struct OpenAIKitTester {
    static func main() async {
        print("🚀 OpenAIKit Test Suite")
        print("====================")
        
        let runner = TestRunner()
        await runner.execute(CommandLine.arguments)
    }
}