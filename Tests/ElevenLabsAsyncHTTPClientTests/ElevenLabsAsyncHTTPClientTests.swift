import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
import ElevenLabs
import ElevenLabsAsyncHTTPClient

private struct OfflineResponse: ClientMiddleware {
    var expectsCompactJSON = false

    func intercept(
        _ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        if expectsCompactJSON {
            let body = try #require(body)
            let data = try await Data(collecting: body, upTo: 4096)
            let json = String(decoding: data, as: UTF8.self)
            #expect(!json.contains("\n"))
            #expect(json.contains("https://example.com"))
        }
        #expect(operationID == "text_to_speech_full")
        #expect(baseURL.absoluteString == "https://api.elevenlabs.io")
        return (.init(status: .ok, headerFields: [.contentType: "audio/mpeg"]), HTTPBody("offline-audio"))
    }
}

struct AsyncHTTPClientFactoryTests {
    @Test func decodesResponseWithoutNetwork() async throws {
        let client = Client.asyncHTTPClient(
            serverURL: URL(string: "https://api.elevenlabs.io")!,
            authentication: .apiKey("offline-test-key"),
            middlewares: [OfflineResponse()]
        )
        let response = try await client.text_to_speech_full(
            .init(path: .init(voice_id: "offline-voice"), body: .json(.init(text: "Offline test")))
        )
        let data = try await Data(collecting: response.ok.body.audio_mpeg, upTo: 1024)
        #expect(data == Data("offline-audio".utf8))
    }

    @Test func appliesExplicitConfigurationDuringRequestEncoding() async throws {
        let client = Client.asyncHTTPClient(
            serverURL: URL(string: "https://api.elevenlabs.io")!,
            configuration: .init(jsonEncodingOptions: [.withoutEscapingSlashes]),
            middlewares: [OfflineResponse(expectsCompactJSON: true)]
        )
        _ = try await client.text_to_speech_full(
            .init(path: .init(voice_id: "offline-voice"), body: .json(.init(text: "https://example.com")))
        )
    }

    @Test func createsProviderClient() {
        let _: Client = createClient(apiKey: "offline-test-key")
    }

}
