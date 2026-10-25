# ElevenLabs response fixtures

The ElevenLabs SDK (`atacan/Elevenlabs` at `2085b3c`) has no captured responses: its only
speech-to-text test calls the live API and keeps nothing. These are live captures and
ElevenLabs' documented examples, all unedited.

## Documented examples

Taken on 2026-10-25 from the SDK's `openapi.json`, which carries ElevenLabs' own spec examples
unchanged (identical to its `original_openapi.json`). The API reference
(`https://elevenlabs.io/docs/api-reference/speech-to-text/convert`) shows the same two response
examples. Pretty-printed; values and keys are as published.

| File | Source | Notes |
| --- | --- | --- |
| `reference-single-channel.json` | `POST /v1/speech-to-text`, 200, example `single_channel` | Text "Hello world!" but only one word, "Hello". It isn't marked with "...", but it's a fragment: the rest of the words are left out. |
| `reference-multichannel.json` | 200, example `multichannel` | Two `transcripts`, one word each. Each word has `channel_index`, which the SDK's word type doesn't model. Fragments like the one above. |
| `reference-accepted.json` | 202 example | The webhook acknowledgement. |
| `schema-chunk.json` | `SpeechToTextChunkResponseModel` schema example | Words with a `spacing` item between them. |
| `schema-multichannel.json` | `MultichannelSpeechToTextResponseModel` schema example | Words and spacing per channel; no `channel_index` on words or transcripts. |
| `schema-webhook.json` | `SpeechToTextWebhookResponseModel` schema example | The 200 webhook shape (`message`, `request_id`). |

No documented example has audio events, diarized speakers, character timings,
`additional_formats`, `transcription_id` or `audio_duration_secs`, and none shows an error body.

## Live captures

Captured on 2026-10-25 by `../../capture-fixtures.sh` from `https://api.elevenlabs.io`, uploading
`../speech.wav` (4.5 s, one speaker), or with ElevenLabs fetching Deepgram's split-stereo florist
call (11.1 s) for multichannel. All files are from the script's second run.

| File | Request | Returned |
| --- | --- | --- |
| `captured-scribe-v2-diarized-keyterms-srt.json` | `scribe_v2`, `language_code=en`, word timestamps, `diarize`, two `keyterms`, `tag_audio_events`, `additional_formats=[{"format":"srt"}]` | 12 words, all `speaker_0`; the key term turned "Transcription Kit" into "TranscriptionKit"; the SRT inline in `additional_formats` (`content_type: text/srt`, not base64); no audio events |
| `captured-scribe-v2-multichannel-remote.json` | `scribe_v2`, `use_multi_channel`, word timestamps, `cloud_storage_url` | Two `transcripts` with `channel_index` 0 and 1 (26 and 15 words), `speaker_0` and `speaker_1` by channel, `channel_index` on every word, `audio_duration_secs` 11.09325 per transcript and 22.1865 (the sum) at the top |
| `captured-scribe-v1-detect-language.json` | `scribe_v1`, no other fields | `language_code: "eng"`, 13 words and 12 spacing items, no `speaker_id`, `transcription_id`, `audio_duration_secs: 4.5386875` (not in the SDK's type) |
| `captured-scribe-v2-character-timestamps.json` | `scribe_v2`, `timestamps_granularity=character` | The same words, each with `characters` |
| `captured-error-400-additional-formats-per-part.json` | `additional_formats` as one JSON object per part, the way the SDK encodes it | 400 `invalid_additional_format_options`: ElevenLabs wants one JSON array |
| `captured-error-400-multichannel-diarize.json` | `use_multi_channel` and `diarize` | 400 `invalid_parameters`: "Multichannel mode does not support diarization…" |
| `captured-error-400-model.json` | `model_id=scribe_v9` | 400 (not the documented 422) with `detail.message`, listing `scribe_v1`, `scribe_v1_experimental`, `scribe_v2`, `scribe_v2_medical` |
| `captured-error-401.json` | `xi-api-key: invalid` | 401 with `detail.message` "Invalid API key" |

The first run sent the SRT and multichannel requests in the rejected forms that the two error
captures above record. No capture has audio events (the clips have none), so that test builds
its response from the SDK's types, and the 402, 422 and 429 tests use bodies in the shapes of
the SDK's error schemas.
