import XCTest
@testable import OpenAIKit

final class ModelConstantsTests: XCTestCase {
    
    // MARK: - Chat Model Tests
    
    func testChatModelConstants() {
        // GPT-4 models
        XCTAssertEqual(Models.Chat.gpt4o, "gpt-4o")
        XCTAssertEqual(Models.Chat.gpt4oMini, "gpt-4o-mini")
        XCTAssertEqual(Models.Chat.gpt4Turbo, "gpt-4-turbo")
        XCTAssertEqual(Models.Chat.gpt4TurboPreview, "gpt-4-turbo-preview")
        XCTAssertEqual(Models.Chat.gpt4, "gpt-4")
        
        // GPT-3.5 models
        XCTAssertEqual(Models.Chat.gpt35Turbo, "gpt-3.5-turbo")
        
        // o1 models
        XCTAssertEqual(Models.Chat.o1, "o1")
        XCTAssertEqual(Models.Chat.o1Mini, "o1-mini")
        XCTAssertEqual(Models.Chat.o1Preview, "o1-preview")
        
        // Audio models
        XCTAssertEqual(Models.Chat.gpt4oAudio, "gpt-4o-audio-preview")
        XCTAssertEqual(Models.Chat.gpt4oAudioPreview20241201, "gpt-4o-audio-preview-2024-12-17")
    }
    
    func testChatModelDateVersions() {
        XCTAssertEqual(Models.Chat.gpt4o20241120, "gpt-4o-2024-11-20")
        XCTAssertEqual(Models.Chat.gpt4o20240806, "gpt-4o-2024-08-06")
        XCTAssertEqual(Models.Chat.gpt4o20240513, "gpt-4o-2024-05-13")
        XCTAssertEqual(Models.Chat.gpt4oMini20240718, "gpt-4o-mini-2024-07-18")
        XCTAssertEqual(Models.Chat.gpt4Turbo20240409, "gpt-4-turbo-2024-04-09")
        XCTAssertEqual(Models.Chat.gpt40125Preview, "gpt-4-0125-preview")
        XCTAssertEqual(Models.Chat.gpt41106Preview, "gpt-4-1106-preview")
        XCTAssertEqual(Models.Chat.gpt40613, "gpt-4-0613")
        XCTAssertEqual(Models.Chat.gpt35Turbo0125, "gpt-3.5-turbo-0125")
        XCTAssertEqual(Models.Chat.gpt35Turbo1106, "gpt-3.5-turbo-1106")
    }
    
    // MARK: - Embedding Model Tests
    
    func testEmbeddingModelConstants() {
        XCTAssertEqual(Models.Embeddings.textEmbedding3Large, "text-embedding-3-large")
        XCTAssertEqual(Models.Embeddings.textEmbedding3Small, "text-embedding-3-small")
        XCTAssertEqual(Models.Embeddings.textEmbeddingAda002, "text-embedding-ada-002")
    }
    
    // MARK: - Audio Model Tests
    
    func testAudioModelConstants() {
        // Whisper models
        XCTAssertEqual(Models.Audio.whisper1, "whisper-1")
        
        // TTS models
        XCTAssertEqual(Models.Audio.tts1, "tts-1")
        XCTAssertEqual(Models.Audio.tts1HD, "tts-1-hd")
    }
    
    func testVoiceConstants() {
        XCTAssertEqual(Voice.alloy.rawValue, "alloy")
        XCTAssertEqual(Voice.ash.rawValue, "ash")
        XCTAssertEqual(Voice.ballad.rawValue, "ballad")
        XCTAssertEqual(Voice.coral.rawValue, "coral")
        XCTAssertEqual(Voice.echo.rawValue, "echo")
        XCTAssertEqual(Voice.fable.rawValue, "fable")
        XCTAssertEqual(Voice.nova.rawValue, "nova")
        XCTAssertEqual(Voice.onyx.rawValue, "onyx")
        XCTAssertEqual(Voice.sage.rawValue, "sage")
        XCTAssertEqual(Voice.shimmer.rawValue, "shimmer")
        XCTAssertEqual(Voice.verse.rawValue, "verse")
    }
    
    // MARK: - Image Model Tests
    
    func testImageModelConstants() {
        XCTAssertEqual(Models.Images.dallE3, "dall-e-3")
        XCTAssertEqual(Models.Images.dallE2, "dall-e-2")
        XCTAssertEqual(Models.Images.gptImage1, "gpt-image-1")
    }
    
    // MARK: - Moderation Model Tests
    
    func testModerationModelConstants() {
        XCTAssertEqual(Models.Moderation.omniModerationLatest, "omni-moderation-latest")
        XCTAssertEqual(Models.Moderation.omniModeration20241025, "omni-moderation-2024-10-25")
        XCTAssertEqual(Models.Moderation.textModerationLatest, "text-moderation-latest")
        XCTAssertEqual(Models.Moderation.textModerationStable, "text-moderation-stable")
        XCTAssertEqual(Models.Moderation.textModeration007, "text-moderation-007")
    }
    
    // MARK: - DeepResearch Model Tests
    
    func testDeepResearchModelConstants() {
        XCTAssertEqual(Models.DeepResearch.o3DeepResearch, "o3-deep-research")
        XCTAssertEqual(Models.DeepResearch.o4MiniDeepResearch, "o4-mini-deep-research")
    }
    
    // MARK: - Model Compatibility Tests
    
    func testModelStringInterpolation() {
        let model = Models.Chat.gpt4o
        let interpolated = "\(model)"
        XCTAssertEqual(interpolated, "gpt-4o")
        
        // Test that models can be used in string contexts
        let message = "Using model: \(Models.Chat.gpt4oMini)"
        XCTAssertEqual(message, "Using model: gpt-4o-mini")
    }
    
    func testModelEquality() {
        XCTAssertEqual(Models.Chat.gpt4o, Models.Chat.gpt4o)
        XCTAssertNotEqual(Models.Chat.gpt4o, Models.Chat.gpt4oMini)
    }
    
    // MARK: - File Purpose Tests
    
    func testFilePurposeValues() {
        XCTAssertEqual(FilePurpose.assistants.rawValue, "assistants")
        XCTAssertEqual(FilePurpose.batch.rawValue, "batch")
        XCTAssertEqual(FilePurpose.fineTune.rawValue, "fine-tune")
        XCTAssertEqual(FilePurpose.vision.rawValue, "vision")
        XCTAssertEqual(FilePurpose.userData.rawValue, "user_data")
    }
    
    // MARK: - Response Format Tests
    
    func testResponseFormatTypes() {
        XCTAssertEqual(ResponseFormatType.text.rawValue, "text")
        XCTAssertEqual(ResponseFormatType.jsonObject.rawValue, "json_object")
        XCTAssertEqual(ResponseFormatType.jsonSchema.rawValue, "json_schema")
    }
    
    // MARK: - Finish Reason Tests
    
    func testFinishReasonValues() {
        XCTAssertEqual(FinishReason.stop.rawValue, "stop")
        XCTAssertEqual(FinishReason.length.rawValue, "length")
        XCTAssertEqual(FinishReason.contentFilter.rawValue, "content_filter")
        XCTAssertEqual(FinishReason.toolCalls.rawValue, "tool_calls")
    }
}