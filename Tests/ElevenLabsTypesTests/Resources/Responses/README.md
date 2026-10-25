# Speech-to-text fixtures

Copied byte-for-byte from TranscriptionKit's Tests/TranscriptionKitElevenLabsTests/Resources/Responses on 2026-10-25. Captured files are real ElevenLabs API responses from its capture-fixtures.sh, with 4.5-second local audio or an 11.1-second stereo remote clip. reference-* and schema-* files are ElevenLabs OpenAPI examples. See the accompanying original provenance README.

The typed-array multipart overlay and new request fields were checked against https://elevenlabs.io/docs/api-reference/speech-to-text/convert on 2026-10-25. A plain array remains repeated even with application/json encoding in swift-openapi-generator 1.13. A semantically equivalent single-branch anyOf retains typed ExportOptions while making the whole array a single JSON part; the whole-request test verifies this contract. Entity redaction currently exposes its documented scalar/category form; list serialization has no captured evidence. Existing keyterms encoding remains unchanged.

401 decoding uses a captured body; 429 response-routing coverage uses a synthetic body of the same error schema. No live API calls are performed by these regression tests.
