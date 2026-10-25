import ElevenLabs
import ElevenLabsTypes
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

private struct SpeechToTextTransport: ClientTransport {
    let status: HTTPResponse.Status
    let responseBody: String
    let expectedBody: String?

    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
        #expect(request.method == .post)
        #expect(request.path == "/v1/speech-to-text")
        if let expectedBody {
            #expect(request.headerFields[.contentType] == "multipart/form-data; boundary=offline-boundary")
            let bytes = try await Data(collecting: #require(body), upTo: 16384)
            #expect(String(decoding: bytes, as: UTF8.self) == expectedBody)
        }
        return (.init(status: status, headerFields: [.contentType: "application/json"]), HTTPBody(responseBody))
    }
}

struct SpeechToTextTests {
    @Test func additionalFormatsUsesOneJSONArrayPart() async throws {
        let expected = [
            "--offline-boundary",
            "content-disposition: form-data; name=\"model_id\"",
            "content-length: 9",
            "content-type: text/plain",
            "",
            "scribe_v2",
            "--offline-boundary",
            "content-disposition: form-data; name=\"additional_formats\"",
            "content-length: 35",
            "content-type: application/json; charset=utf-8",
            "",
            "[{\"format\":\"srt\"},{\"format\":\"txt\"}]",
            "--offline-boundary--",
            "",
            "",
        ]
        .joined(separator: "\r\n")
        let client = Client(
            serverURL: URL(string: "https://api.elevenlabs.io")!,
            configuration: .init(jsonEncodingOptions: [], multipartBoundaryGenerator: ConstantMultipartBoundaryGenerator(boundary: "offline-boundary")),
            transport: SpeechToTextTransport(status: .accepted, responseBody: "{\"message\":\"accepted\",\"request_id\":\"offline\"}", expectedBody: expected)
        )
        _ = try await client.speech_to_text(
            .init(
                body: .multipartForm([
                    .model_id(.init(payload: .init(body: HTTPBody("scribe_v2")))),
                    .additional_formats(.init(payload: .init(body: .init(value1: [.srt(.init(format: .srt)), .txt(.init(format: .txt))])))),
                ])
            )
        )
    }

    @Test(arguments: [400, 401, 429])
    func expectedErrorResponsesDecodeSuccessfully(status: Int) async throws {
        let json = "{\"detail\":{\"type\":\"test_error\",\"code\":\"offline\",\"message\":\"Offline failure\",\"status\":\"offline\",\"request_id\":\"test-request\"}}"
        let client = Client(
            serverURL: URL(string: "https://api.elevenlabs.io")!,
            transport: SpeechToTextTransport(status: .init(code: status), responseBody: json, expectedBody: nil)
        )
        let response = try await client.speech_to_text(
            .init(
                body: .multipartForm([
                    .model_id(.init(payload: .init(body: HTTPBody("scribe_v2"))))
                ])
            )
        )
        let error: Components.Schemas.BadRequestError
        switch response {
        case .badRequest(let value):
            #expect(status == 400)
            error = try value.body.json
        case .unauthorized(let value):
            #expect(status == 401)
            error = try value.body.json
        case .tooManyRequests(let value):
            #expect(status == 429)
            error = try value.body.json
        default:
            Issue.record("Expected a typed error response")
            return
        }
        #expect(error.detail?.message == "Offline failure")
        #expect(error.detail?.request_id == "test-request")
    }
}
