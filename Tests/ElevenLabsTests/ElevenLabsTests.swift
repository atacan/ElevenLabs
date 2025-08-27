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
        let serverURL = URL(string: "https://api.elevenlabs.io/v1")!
        let envFileUrl = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".env")
        let client = Client(
            serverURL: serverURL,
            transport: AsyncHTTPClientTransport()
        )
        return client
    }()
    let audioData = try! Data(contentsOf: URL(fileURLWithPath: "/Users/atacan/Developer/Repositories/GoogleGenerativeLanguage/assets/speech.mp3"))

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let response = try await client.Speech_to_Text_v1_speech_to_text_post(
            query: Operations.Speech_to_Text_v1_speech_to_text_post.Input.Query.init(enable_logging: true),
            body: Operations.Speech_to_Text_v1_speech_to_text_post.Input.Body.multipartForm(
                [
                    .file(.init(payload: .init(body: HTTPBody(audioData))))
                ]
            )
        )
        dump(response)
    }
}
