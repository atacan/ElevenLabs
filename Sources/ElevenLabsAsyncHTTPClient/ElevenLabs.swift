import Foundation
import ElevenLabs

/// Creates a client for the ElevenLabs service using the shared AsyncHTTPClient.
public func createClient(apiKey: String) -> Client {
    Client.asyncHTTPClient(
        serverURL: URL(string: "https://api.elevenlabs.io")!,
        authentication: .apiKey(apiKey)
    )
}
