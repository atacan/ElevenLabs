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
        #expect(word.start! > 0)
        #expect(word.end! > 0)
        #expect(word.end! > word.start!)
    }

    @Test func testTextToSpeechApiStructure() async throws {
        let humanReadableDate: String = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let response = try await client.Text_to_speech_v1_text_to_speech__voice_id__post(
            path: Operations.Text_to_speech_v1_text_to_speech__voice_id__post.Input.Path.init(voice_id: "YVyp28LAMQfmx8iIH88U"),
            body: Operations.Text_to_speech_v1_text_to_speech__voice_id__post.Input.Body.json(
                Components.Schemas.Body_Text_to_speech_v1_text_to_speech__voice_id__post(
                    text: "Hello world! Code generation is working! Today's date is \(humanReadableDate).",
                    model_id: "eleven_multilingual_v2",
                    use_pvc_as_ivc: Optional<Swift.Bool>.none,
                    apply_text_normalization: Optional<Components.Schemas.Body_Text_to_speech_v1_text_to_speech__voice_id__post.apply_text_normalizationPayload>.none,
                    apply_language_text_normalization: Optional<Swift.Bool>.none,
                    language_code: Optional<Swift.String>.none,
                    voice_settings: Optional<Components.Schemas.VoiceSettingsResponseModel>.none,
                    pronunciation_dictionary_locators: Optional<[Components.Schemas.PronunciationDictionaryVersionLocatorRequestModel]>.none,
                    seed: Optional<Swift.Int>.none,
                    previous_text: Optional<Swift.String>.none,
                    next_text: Optional<Swift.String>.none,
                    previous_request_ids: Optional<[Swift.String]>.none,
                    next_request_ids: Optional<[Swift.String]>.none,
                )
            )
        )

        dump(response)

        let output: HTTPBody = try response.ok.body.audio_mpeg
        let audioData: Data = try await Data(collecting: output, upTo: 1024 * 1024 * 10)
        #expect(audioData.count > 0)

        let downloadsFolderUrl: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let audioUrl: URL = downloadsFolderUrl.appendingPathComponent("elevenlabs-test-\(Date().timeIntervalSince1970).mpeg")
        try audioData.write(to: audioUrl)
        #expect(FileManager.default.fileExists(atPath: audioUrl.path))
    }

    @Test func testClientInitialization() {
        // Test that client initializes correctly
        // The client should be created without throwing errors
        let _ = createClient(apiKey: "test")
    }
}
