# ElevenLabs Swift

A Swift package for the [ElevenLabs API](https://elevenlabs.io), generated from the official OpenAPI specification using [swift-openapi-generator](https://github.com/apple/swift-openapi-generator).

## Requirements

- Swift 5.9+
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
        ]
    ),
]
```

Use `ElevenLabsTypes` instead if you only need the types (e.g. for a server-side target that shares models).

## Products

| Product | Description |
|---|---|
| `ElevenLabsTypes` | Generated request/response types and the `AuthenticationMiddleware` |
| `ElevenLabs` | Generated HTTP client + `createClient(apiKey:)` factory function |

## Usage

### Creating a client

```swift
import ElevenLabs

let client = createClient(apiKey: "your-api-key")
```

`createClient` points at `https://api.elevenlabs.io` and attaches an `AuthenticationMiddleware` that injects the `xi-api-key` header on every request.

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

- `speech-to-text`
- `text-to-speech`

To enable additional tags, edit `openapi-generator-config-types.yaml` and `openapi-generator-config-client.yaml`, then run `make regenerate`.

## Development

### Regenerating from OpenAPI spec

The Swift sources under `Sources/*/GeneratedSources/` are generated — do not edit them by hand.

To regenerate after updating `openapi.json` or the generator configs:

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

Tests call the live ElevenLabs API. Provide your key in a `.env` file in the repository root:

```
ELEVENLABS_API_KEY=sk-...
```

Then:

```bash
swift test
# or
make test
```

### Project structure

```
Sources/
  ElevenLabsTypes/
    AuthenticationMiddleware.swift   # Injects xi-api-key header
    ElevenLabsTypes.swift            # Placeholder for custom extensions
    GeneratedSources/Types.swift     # Generated: Operations, Components, schemas
  ElevenLabs/
    ElevenLabs.swift                 # createClient(apiKey:) factory
    GeneratedSources/Client.swift    # Generated: Client struct
Tests/
  ElevenLabsTests/
    ElevenLabsTests.swift            # Integration tests
openapi.json                         # Source OpenAPI specification
openapi-generator-config-types.yaml  # Generator config for types target
openapi-generator-config-client.yaml # Generator config for client target
Makefile
```
