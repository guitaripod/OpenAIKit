import Foundation
import OpenAIKit

struct TestRunner {
    let config = TestConfiguration.fromEnvironment()
    let output = ConsoleOutput()
    
    func execute(_ arguments: [String]) async {
        let openAI = OpenAIKit(apiKey: config.apiKey)
        
        if arguments.count < 2 {
            printUsage()
            return
        }
        
        let command = arguments[1]
        
        switch command {
        case "chat":
            await ChatTests().testChatCompletion(openAI: openAI)
        case "stream":
            await ChatTests().testStreamingChat(openAI: openAI)
        case "functions":
            await ChatTests().testFunctionCalling(openAI: openAI)
        case "embeddings":
            await EmbeddingTests().runAll(openAI: openAI)
        case "audio-transcribe":
            await AudioTests().testAudioTranscription(openAI: openAI)
        case "audio-tts":
            await AudioTests().testTextToSpeech(openAI: openAI)
        case "moderation":
            await ModerationTests().runAll(openAI: openAI)
        case "models":
            await ModelTests().runAll(openAI: openAI)
        case "files":
            await FileTests().runAll(openAI: openAI)
        case "images":
            await ImageTests().runAll(openAI: openAI)
        case "edge-cases":
            await EdgeCaseTests().testEdgeCases(openAI: openAI)
        case "error-handling":
            await EdgeCaseTests().testErrorHandling(openAI: openAI)
        case "advanced":
            await AdvancedTests().testAdvancedFeatures(openAI: openAI)
        case "error-ui":
            await AdvancedTests().testErrorUIFeatures(openAI: openAI)
        case "batch":
            await BatchTests().testBatchAPI(openAI: openAI)
        case "batch-edge":
            await BatchTests().testBatchEdgeCases(openAI: openAI)
        case "deepresearch", "deep-research":
            await DeepResearchTests().testDeepResearch(openAI: openAI)
        case "deepresearch-long":
            await DeepResearchTests().testDeepResearchLong(openAI: openAI)
        case "deepresearch-stream":
            await DeepResearchTests().testDeepResearchStreamQuick()
        case "all":
            await runAllTests(openAI: openAI)
        default:
            print("❌ Unknown command: \(command)")
            printUsage()
        }
    }
    
    func printUsage() {
        print("""
        Usage: swift run OpenAIKitTester <command>
        
        Commands:
          chat             Test basic chat completions
          stream           Test streaming chat completions
          functions        Test function calling
          embeddings       Test embeddings generation
          audio-transcribe Test audio transcription
          audio-tts        Test text-to-speech
          moderation       Test content moderation
          models           Test listing models
          files            Test files API
          images           Test image generation
          edge-cases       Test edge cases and corner scenarios
          error-handling   Test error handling
          advanced         Test advanced features
          error-ui         Test error UI features
          batch            Test batch API
          batch-edge       Test batch API edge cases
          deepresearch     Test DeepResearch capabilities (quick)
          deepresearch-long Test DeepResearch with real research task
          deepresearch-stream Test DeepResearch streaming quickly
          all              Run all tests
        """)
    }
    
    func runAllTests(openAI: OpenAIKit) async {
        print("\n🏃 Running all tests...")
        
        await ChatTests().runAll(openAI: openAI)
        await EmbeddingTests().runAll(openAI: openAI)
        await AudioTests().runAll(openAI: openAI)
        await ModerationTests().runAll(openAI: openAI)
        await ModelTests().runAll(openAI: openAI)
        await FileTests().runAll(openAI: openAI)
        await ImageTests().runAll(openAI: openAI)
        await EdgeCaseTests().runAll(openAI: openAI)
        await AdvancedTests().runAll(openAI: openAI)
        await DeepResearchTests().runAll(openAI: openAI)
        
        print("\n✅ All tests completed!")
    }
}