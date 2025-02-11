import Foundation
import HTTPTypes
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import Testing

@testable import ElevenLabs_AHC

#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
@preconcurrency import struct Foundation.Date
#else
import struct Foundation.URL
import struct Foundation.Data
import struct Foundation.Date
#endif

final class ElevenLabs_AHCTests {
    let client = {
        // get api key from environment
        let apiKey = getEnvironmentVariable("ELEVENLABS_API_KEY")!
        let stsUrl = URL(string: "https://api.elevenlabs.io")!

        let authMiddleware = AuthenticationMiddleware(apiKey: apiKey)

        return Client(
            serverURL: stsUrl,
            transport: AsyncHTTPClientTransport(),
            middlewares: [
                authMiddleware
            ]
        )
    }()

    @Test
    func testElevenLabs_AHCTests() async throws {
        let audioFileUrl = Bundle.module.url(forResource: "Resources/amazing-things", withExtension: "wav")!
        let audioData = try Data(contentsOf: audioFileUrl)

        let response = try await client.Speech_to_Text_v1_speech_to_text_post(
            body: .multipartForm([
                .model_id(.init(payload: .init(body: .init("scribe_v1")))),
                .file(.init(payload: .init(body: .init(audioData)), filename: "amazing-things.wav"))
            ])
        )
        dump(response)
    }
}
