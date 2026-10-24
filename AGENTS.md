We generate the Swift code using swift-openapi-generator. As we apply complex transformations to the original OpenAPI specification, we use a Python tool to do this. Run the generation with 

```bash
make regenerate
```

As this is a Swift package, you can find the code of the Swift package dependencies in the ".build/checkouts" directory. Look at that folder when you need to understand how to use the code from the Swift package dependencies.


The package exposes ElevenLabsTypes, ElevenLabs, ElevenLabsURLSession, and
ElevenLabsAsyncHTTPClient. Keep transport imports/dependencies in convenience
targets. Shared authentication lives in ElevenLabs/Authentication; its generated
security metadata reflects the final overlay. The overlay defines optional
ElevenLabsAPIKey authentication in the xi-api-key header. The provider-specific
createClient(apiKey:) helper belongs to ElevenLabsAsyncHTTPClient.

Verify changes offline with:

```bash
swift build
swift test --filter 'AuthenticationTests|URLSessionFactoryTests|AsyncHTTPClientFactoryTests|ElevenLabsTypesTests'
```

The ElevenLabsTests suite loads .env and performs live API requests; run it only
when explicitly requested. Never print credentials. Factory tests short-circuit
network requests and shared-authentication tests use a mock transport.

If date decoding reports `Expected date string to be ISO8601-formatted`, inspect
the timestamp. Fractional seconds may need
`configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds)` in both
preserved factory defaults. Keep caller overrides available, verify both factories
offline, and remember standalone JSONDecoder needs its own date strategy.
Do not change provider defaults without evidence from the enabled responses.

Factory usage (add and import the selected convenience product):

```swift
import Foundation
import ElevenLabs
import ElevenLabsURLSession

let client = Client.urlSession(
    serverURL: URL(string: "https://api.elevenlabs.io")!,
    authentication: .apiKey("YOUR_API_KEY")
)
```

```swift
import Foundation
import ElevenLabs
import ElevenLabsAsyncHTTPClient

let client = Client.asyncHTTPClient(
    serverURL: URL(string: "https://api.elevenlabs.io")!,
    authentication: .apiKey("YOUR_API_KEY")
)
```
