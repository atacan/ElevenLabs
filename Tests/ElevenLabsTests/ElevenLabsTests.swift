import Foundation
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import Testing
import UsefulThings

@testable import ElevenLabs
@testable import ElevenLabsTypes

#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
@preconcurrency import struct Foundation.Date
#else
import struct Foundation.URL
import struct Foundation.Data
import struct Foundation.Date
#endif

struct ElevenLabsTests {
    let client = {
        let envFileUrl = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".env")
        let apiKey = getEnvironmentVariable("ELEVENLABS_API_KEY", from: envFileUrl)!
        let client = createClient(apiKey: apiKey)
        return client
    }()

    @Test func testSpeechToTextApiStructure() async throws {
        let audioData = try! Data(contentsOf: URL(fileURLWithPath: "/Users/atacan/Developer/Repositories/GoogleGenerativeLanguage/assets/speech.mp3"))

        let response = try await client.Speech_to_Text_v1_speech_to_text_post(
            query: Operations.Speech_to_Text_v1_speech_to_text_post.Input.Query.init(enable_logging: true),
            body: Operations.Speech_to_Text_v1_speech_to_text_post.Input.Body.multipartForm(
                [
                    .model_id(.init(payload: .init(body: HTTPBody("scribe_v1")))),
                    .file(
                        .init(
                            payload: .init(
                                body: HTTPBody(
                                    audioData
                                )
                            ),
                            filename: "speech.mp3"
                        )
                    ),
                ]
            )
        )

        dump(response)

        let output: Components.Schemas.SpeechToTextChunkResponseModel? = try response.ok.body.json.value1
        guard let output: Components.Schemas.SpeechToTextChunkResponseModel = output else {
            throw NSError(domain: "No output", code: 1)
        }

        let text: String = output.text
        #expect(text.isEmpty == false)

        let words: [Components.Schemas.SpeechToTextWordResponseModel] = output.words
        #expect(words.count > 0)

        let word: Components.Schemas.SpeechToTextWordResponseModel = words[0]
        #expect(word.text.isEmpty == false)
        // #expect(word. > 0)
        // #expect(word.end > 0)
        // #expect(word.end > word.start)
    }

    @Test func testClientInitialization() {
        // Test that client initializes correctly
        // The client should be created without throwing errors
        let _ = createClient(apiKey: "test")
    }
}
