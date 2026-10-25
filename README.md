# ElevenLabs Swift

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fatacan%2FElevenLabs%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/atacan/ElevenLabs)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fatacan%2FElevenLabs%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/atacan/ElevenLabs)

A Swift package for the [ElevenLabs API](https://elevenlabs.io), generated from the official OpenAPI specification using [swift-openapi-generator](https://github.com/apple/swift-openapi-generator).

## Requirements

- Swift 6.2+ with the current resolved dependencies (verified with Swift 6.4)
- macOS 13+, iOS 16+, tvOS 16+, watchOS 9+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/atacan/ElevenLabs", branch: "main"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "ElevenLabs", package: "ElevenLabs"),
            .product(name: "ElevenLabsURLSession", package: "ElevenLabs"),
        ]
    ),
]
```

Use `ElevenLabsTypes` instead if you only need the types (e.g. for a server-side target that shares models).

## Products

| Product | Description |
|---|---|
| `ElevenLabsTypes` | Generated models, operation inputs/outputs, and API protocol |
| `ElevenLabs` | Transport-independent HTTP client and shared authentication |
| `ElevenLabsURLSession` | `Client.urlSession(...)` factory |
| `ElevenLabsAsyncHTTPClient` | `Client.asyncHTTPClient(...)` and `createClient(apiKey:)` factories |

## Usage

### Creating a client

```swift
import Foundation
import ElevenLabs
import ElevenLabsURLSession

let client = Client.urlSession(
    serverURL: URL(string: "https://api.elevenlabs.io")!,
    authentication: .apiKey("YOUR_API_KEY")
)
```

For AsyncHTTPClient, add its product to your target dependencies:

```swift
import Foundation
import ElevenLabs
import ElevenLabsAsyncHTTPClient

let client = Client.asyncHTTPClient(
    serverURL: URL(string: "https://api.elevenlabs.io")!,
    authentication: .apiKey("YOUR_API_KEY")
)

// Provider helper with the same service URL and shared AsyncHTTPClient defaults.
let defaultClient = createClient(apiKey: "YOUR_API_KEY")
```

Both factories return `ElevenLabs.Client`. Shared authentication injects the
`xi-api-key` header. The overlay declares the API key as optional to match the
source specification's optional header parameters; the service still decides
which requests require credentials. Use `Authentication.credentials` with scheme
name `ElevenLabsAPIKey` when selecting credentials by name, or an async provider
with `.apiKey { try await keyStore.currentKey() }` for rotating keys.

Factories accept `configuration:`, `transportConfiguration:`, and `middlewares:`.
Additional middleware runs before shared authentication. Injected sessions/clients
remain owned by the caller; do not shut down the transports' shared instances.
For custom transports, use the core `Client(serverURL:configuration:transport:authentication:middlewares:)` initializer.
The core and Types targets contain no transport dependencies; SwiftPM can still
resolve both transport packages at the package level.

### Text to Speech

```swift
import ElevenLabs
import ElevenLabsTypes
import OpenAPIRuntime

let response = try await client.text_to_speech_full(
    Operations.text_to_speech_full.Input(
        path: .init(voice_id: "YVyp28LAMQfmx8iIH88U"),
        body: .json(
            Components.Schemas.Body_text_to_speech_full(
                text: "Hello, world!",
                model_id: "eleven_multilingual_v2"
            )
        )
    )
)

let audioBody: HTTPBody = try response.ok.body.audio_mpeg
let audioData: Data = try await Data(collecting: audioBody, upTo: 10 * 1024 * 1024)
```

Other text-to-speech operations:

| Operation | Description |
|---|---|
| `text_to_speech_full` | Full audio file, `audio/mpeg` response |
| `text_to_speech_full_with_timestamps` | Full audio + character-level timing JSON |
| `text_to_speech_stream` | Streaming audio |
| `text_to_speech_stream_with_timestamps` | Streaming audio + timing JSON |

### Speech to Text

```swift
import ElevenLabs
import ElevenLabsTypes
import OpenAPIRuntime

let audioData = try Data(contentsOf: audioFileURL)

let response = try await client.speech_to_text(
    Operations.speech_to_text.Input(
        query: .init(enable_logging: true),
        body: .multipartForm([
            .model_id(.init(payload: .init(body: HTTPBody("scribe_v1")))),
            .file(.init(payload: .init(body: HTTPBody(audioData)), filename: "audio.wav")),
        ])
    )
)

let result = try response.ok.body.json.value1  // SpeechToTextChunkResponseModel?
print(result?.text ?? "")
```

The multipart body supports additional parts such as `.language_code`, `.diarize`, `.timestamps_granularity`, etc. — all cases of `Components.Schemas.Body_Speech_to_Text_v1_speech_to_text_post`.

### Accessing structured output

Responses follow a consistent pattern: call `.ok` (throws if the status was not 200), then `.body`, then the content-type accessor:

```swift
// JSON response
let payload = try response.ok.body.json

// Binary response
let audioBody = try response.ok.body.audio_mpeg
```

## Enabled API tags

The generator configs filter to a subset of the full ElevenLabs API. Currently enabled tags:

- `models`
- `voices`
- `speech-to-text`
- `text-to-speech`

To enable additional tags, edit `openapi-generator-config-types.yaml` and `openapi-generator-config-client.yaml`, then run `make regenerate`.

## Development

### Regenerating from OpenAPI spec

The Swift sources under `Sources/*/GeneratedSources/` are generated — do not edit them by hand.

To regenerate after updating `original_openapi.json`, `openapi-overlay.json`, or the generator configs:

```bash
make regenerate
```

This runs [swift-package-generator-based-on-openapi](https://github.com/atacan/swift-package-generator-based-on-openapi) via `uvx`, which rebuilds the package scaffolding and re-runs the generator.

To run only the Swift OpenAPI Generator step (without rebuilding scaffolding):

```bash
make generate
```

### Other make targets

```
make build          Build the Swift package
make test           Run tests
make format         Run swift-format on Sources and Tests
make test-on-linux  Run tests inside a Docker container (swift:latest)
make merge-main     Merge current branch into main and push
```

### Running tests

Run the offline suites explicitly; they use mock transports and response middleware
and do not read `.env` or call the service:

```bash
swift build
swift test --filter 'AuthenticationTests|URLSessionFactoryTests|AsyncHTTPClientFactoryTests|ElevenLabsTypesTests|SpeechToTextTests'
```

The existing `ElevenLabsTests` suite calls the live API and reads
`ELEVENLABS_API_KEY` from the process environment. Export the key before running
it separately, and run it only when intended. The four network tests skip with
a clear message when the key is absent or blank. A configured key that the service
rejects still fails these success tests; mocked 400/401/429 tests assert the
expected error response and pass when it matches:

```bash
swift test --filter ElevenLabsTests
```

### Troubleshooting dates

If a response fails with `Expected date string to be ISO8601-formatted`, inspect
the actual timestamp. Fractional seconds can require
`configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds)`. Pass runtime
configuration to either factory; standalone JSON decoders need their own date
strategy. No fractional-second default is currently required by the enabled API
fixtures. If the provider needs it, update both preserved factory files and verify
both offline response paths and explicit caller overrides.

### Project structure

```
Sources/
  ElevenLabsTypes/                  # Generated models and custom type utilities
  ElevenLabs/
    Authentication/                # Shared authentication and generated security metadata
    GeneratedSources/              # Generated client
  ElevenLabsURLSession/            # URLSession factory
  ElevenLabsAsyncHTTPClient/       # AsyncHTTPClient factory and provider helper
Tests/
  ElevenLabsTests/                 # Live API tests plus offline authentication and speech-to-text tests
  ElevenLabsTypesTests/            # Offline response decoding tests and captured fixtures
  ElevenLabsURLSessionTests/       # Offline factory tests
  ElevenLabsAsyncHTTPClientTests/  # Offline factory tests
original_openapi.json              # Source specification
openapi-overlay.json               # Editable provider corrections
openapi.json                       # Generated, sanitized and overlaid specification
```

Regeneration preserves manual helpers, factory settings, manifests, generator
configs, tests, and documentation. Edit specifications through the original or
overlay; edit custom Swift outside `GeneratedSources/`. Regenerate operation
security metadata instead of editing it directly.
