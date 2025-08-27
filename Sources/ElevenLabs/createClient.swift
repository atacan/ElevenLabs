import ElevenLabsTypes
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime

#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
@preconcurrency import struct Foundation.Date
#else
import struct Foundation.URL
import struct Foundation.Data
import struct Foundation.Date
#endif

public func createClient(apiKey: String) -> Client {

    guard let serverURL = URL(string: "https://api.elevenlabs.io") else {
        preconditionFailure("Failed to create server URL")
    }
    let client = Client(
        serverURL: serverURL,
        // configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
        transport: AsyncHTTPClientTransport(),
        middlewares: [
            AuthenticationMiddleware(apiKey: apiKey)
        ]
    )

    return client
}
