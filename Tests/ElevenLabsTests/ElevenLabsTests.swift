import ElevenLabsAsyncHTTPClient
import Foundation
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import Testing

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

private let liveAPIKey = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"]?
    .trimmingCharacters(in: .whitespacesAndNewlines)

struct ElevenLabsTests {
    private var client: Client {
        get throws {
            let apiKey = try #require(liveAPIKey, "ELEVENLABS_API_KEY is required for live API tests.")
            return createClient(apiKey: apiKey)
        }
    }

    @Test(.enabled(if: liveAPIKey?.isEmpty == false, "Set ELEVENLABS_API_KEY to run this live API test."))
    func testSpeechToTextApiStructure() async throws {
        let audioURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("60s_speech.wav")
        let audioData = try Data(contentsOf: audioURL)

        let response = try await client.speech_to_text(
            Operations.speech_to_text.Input(
                query: .init(enable_logging: true),
                body: .multipartForm([
                    .model_id(.init(payload: .init(body: HTTPBody("scribe_v1")))),
                    .file(
                        .init(
                            payload: .init(body: HTTPBody(audioData)),
                            filename: "speech.mp3"
                        )
                    ),
                ])
            )
        )

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

    @Test(.enabled(if: liveAPIKey?.isEmpty == false, "Set ELEVENLABS_API_KEY to run this live API test."))
    func testTextToSpeechApiStructure() async throws {
        let client = try self.client
        let voiceResponse = try await client.get_voices(.init(query: .init(show_legacy: false)))
        let voices = try voiceResponse.ok.body.json.voices
        // Default voices are returned as premade; library voices require a paid API plan.
        let voice = try #require(
            voices.first { $0.category == .premade && $0.is_legacy != true },
            "No current default voice is available to this account; refusing to use a paid library voice."
        )
        let response = try await client.text_to_speech_full(
            Operations.text_to_speech_full.Input(
                path: .init(voice_id: voice.voice_id),
                body: .json(
                    Components.Schemas.Body_text_to_speech_full(
                        text: "Hello world.",
                        model_id: "eleven_multilingual_v2"
                    )
                )
            )
        )

        let output: HTTPBody = try response.ok.body.audio_mpeg
        let audioData: Data = try await Data(collecting: output, upTo: 1024 * 1024 * 10)
        #expect(audioData.count > 0)

        let downloadsFolderUrl: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let audioUrl: URL = downloadsFolderUrl.appendingPathComponent("elevenlabs-test-\(Date().timeIntervalSince1970).mpeg")
        try audioData.write(to: audioUrl)
        #expect(FileManager.default.fileExists(atPath: audioUrl.path))
    }

    @Test(.enabled(if: liveAPIKey?.isEmpty == false, "Set ELEVENLABS_API_KEY to run this live API test."))
    func testGetModelsApiStructure() async throws {
        let response = try await client.get_models(Operations.get_models.Input())

        let models: [Components.Schemas.ModelResponseModel] = try response.ok.body.json
        #expect(models.isEmpty == false)

        let model: Components.Schemas.ModelResponseModel = models[0]
        #expect(model.model_id.isEmpty == false)
        #expect(model.name.isEmpty == false)

        let languages: [Components.Schemas.LanguageResponseModel] = model.languages
        #expect(languages.isEmpty == false)

        let ttsModel: Components.Schemas.ModelResponseModel? = models.first { $0.can_do_text_to_speech }
        #expect(ttsModel != nil)
    }

    @Test(.enabled(if: liveAPIKey?.isEmpty == false, "Set ELEVENLABS_API_KEY to run this live API test."))
    func testGetVoicesApiStructure() async throws {
        let response = try await client.get_voices(
            Operations.get_voices.Input(query: .init(show_legacy: true))
        )

        let output: Components.Schemas.GetVoicesResponseModel = try response.ok.body.json

        let voices: [Components.Schemas.VoiceResponseModel] = output.voices
        #expect(voices.isEmpty == false)

        let voice: Components.Schemas.VoiceResponseModel = voices[0]
        #expect(voice.voice_id.isEmpty == false)
        #expect(voice.name.isEmpty == false)

        let category: Components.Schemas.VoiceResponseModel.categoryPayload = voice.category
        #expect(Components.Schemas.VoiceResponseModel.categoryPayload.allCases.contains(category))
    }

    @Test func testClientInitialization() {
        // Test that client initializes correctly
        // The client should be created without throwing errors
        let _ = createClient(apiKey: "test")
    }
}
