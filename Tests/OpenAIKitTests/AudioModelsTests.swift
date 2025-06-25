import XCTest
@testable import OpenAIKit

final class AudioModelsTests: XCTestCase {
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    override func setUp() {
        super.setUp()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    func testSpeechRequestEncoding() throws {
        let request = SpeechRequest(
            input: "Hello, world!",
            model: "tts-1",
            voice: .alloy,
            responseFormat: .mp3,
            speed: 1.5
        )
        
        let encoded = try encoder.encode(request)
        let decoded = try decoder.decode(SpeechRequest.self, from: encoded)
        
        XCTAssertEqual(decoded.input, request.input)
        XCTAssertEqual(decoded.model, request.model)
        XCTAssertEqual(decoded.voice, request.voice)
        XCTAssertEqual(decoded.responseFormat, request.responseFormat)
        XCTAssertEqual(decoded.speed, request.speed)
    }
    
    func testVoiceRawValues() {
        XCTAssertEqual(Voice.alloy.rawValue, "alloy")
        XCTAssertEqual(Voice.echo.rawValue, "echo")
        XCTAssertEqual(Voice.fable.rawValue, "fable")
        XCTAssertEqual(Voice.onyx.rawValue, "onyx")
        XCTAssertEqual(Voice.nova.rawValue, "nova")
        XCTAssertEqual(Voice.shimmer.rawValue, "shimmer")
    }
    
    func testAudioFormatRawValues() {
        XCTAssertEqual(AudioFormat.mp3.rawValue, "mp3")
        XCTAssertEqual(AudioFormat.opus.rawValue, "opus")
        XCTAssertEqual(AudioFormat.aac.rawValue, "aac")
        XCTAssertEqual(AudioFormat.flac.rawValue, "flac")
        XCTAssertEqual(AudioFormat.wav.rawValue, "wav")
        XCTAssertEqual(AudioFormat.pcm.rawValue, "pcm")
    }
    
    func testTranscriptionResponse() throws {
        let json = """
        {
            "text": "This is a transcribed text.",
            "language": "en",
            "duration": 5.5,
            "segments": [{
                "id": 0,
                "seek": 0,
                "start": 0.0,
                "end": 2.5,
                "text": "This is a",
                "tokens": [1, 2, 3],
                "temperature": 0.0,
                "avg_logprob": -0.5,
                "compression_ratio": 1.2,
                "no_speech_prob": 0.01
            }],
            "usage": {
                "prompt_tokens": 0,
                "completion_tokens": 10,
                "total_tokens": 10
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(TranscriptionResponse.self, from: data)
        
        XCTAssertEqual(response.text, "This is a transcribed text.")
        XCTAssertEqual(response.language, "en")
        XCTAssertEqual(response.duration, 5.5)
        XCTAssertEqual(response.segments?.count, 1)
        XCTAssertEqual(response.segments?[0].text, "This is a")
        XCTAssertEqual(response.usage?.totalTokens, 10)
    }
    
    func testChunkingStrategy() throws {
        let auto = ChunkingStrategy.auto
        let staticStrategy = ChunkingStrategy.staticStrategy(
            ChunkingStrategy.Static(chunkLength: 1000, chunkOverlap: 100)
        )
        
        let encodedAuto = try encoder.encode(auto)
        let decodedAuto = try decoder.decode(ChunkingStrategy.self, from: encodedAuto)
        if case .auto = decodedAuto {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .auto")
        }
        
        let encodedStatic = try encoder.encode(staticStrategy)
        let decodedStatic = try decoder.decode(ChunkingStrategy.self, from: encodedStatic)
        if case .staticStrategy(let s) = decodedStatic {
            XCTAssertEqual(s.chunkLength, 1000)
            XCTAssertEqual(s.chunkOverlap, 100)
        } else {
            XCTFail("Expected .staticStrategy")
        }
    }
}