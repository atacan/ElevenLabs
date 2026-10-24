import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
import ElevenLabs
import ElevenLabsTypes

private struct HeaderCheckingTransport: ClientTransport {
    let expectedKey: String?

    func send(
        _ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        #expect(request.headerFields[HTTPField.Name("xi-api-key")!] == expectedKey)
        #expect(baseURL.absoluteString == "https://api.elevenlabs.io")
        return (.init(status: .ok, headerFields: [.contentType: "audio/mpeg"]), HTTPBody("offline-audio"))
    }
}

struct AuthenticationTests {
    @Test(arguments: [true, false])
    func optionalAPIKeyHeader(isAuthenticated: Bool) async throws {
        let key = isAuthenticated ? "offline-test-key" : nil
        let client = Client(
            serverURL: URL(string: "https://api.elevenlabs.io")!,
            transport: HeaderCheckingTransport(expectedKey: key),
            authentication: key.map(Authentication.apiKey) ?? .none
        )
        let response = try await client.text_to_speech_full(
            .init(path: .init(voice_id: "offline-voice"), body: .json(.init(text: "Offline test")))
        )
        let data = try await Data(collecting: response.ok.body.audio_mpeg, upTo: 1024)
        #expect(data == Data("offline-audio".utf8))
    }

    @Test func namedAPIKeyCredential() async throws {
        let client = Client(
            serverURL: URL(string: "https://api.elevenlabs.io")!,
            transport: HeaderCheckingTransport(expectedKey: "named-offline-key"),
            authentication: .credentials(["ElevenLabsAPIKey": .init("named-offline-key")])
        )
        _ = try await client.text_to_speech_full(
            .init(path: .init(voice_id: "offline-voice"), body: .json(.init(text: "Offline test")))
        )
    }
}
