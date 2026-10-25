import ElevenLabsTypes
import Foundation
import Testing

struct ElevenLabsTypesTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Resources/Responses"))
        return try Data(contentsOf: url)
    }

    @Test(arguments: ["captured-scribe-v1-detect-language", "captured-scribe-v2-character-timestamps", "captured-scribe-v2-diarized-keyterms-srt"])
    func capturedSingleChannel(name: String) throws {
        let data = try fixture(name)
        let transcript = try JSONDecoder().decode(Components.Schemas.SpeechToTextChunkResponseModel.self, from: data)
        #expect(transcript.audio_duration_secs == 4.5386875)
        #expect(!transcript.words.isEmpty)
        #expect(!transcript.text.isEmpty)
    }

    @Test func capturedMultichannel() throws {
        let response = try JSONDecoder().decode(Components.Schemas.MultichannelSpeechToTextResponseModel.self, from: fixture("captured-scribe-v2-multichannel-remote"))
        #expect(response.audio_duration_secs == 22.1865)
        #expect(response.transcripts.count == 2)
        for (index, transcript) in response.transcripts.enumerated() {
            #expect(transcript.audio_duration_secs == 11.09325)
            #expect(transcript.channel_index == index)
            #expect(!transcript.words.isEmpty)
            #expect(transcript.words.allSatisfy { $0.channel_index == index })
        }
    }

    @Test(
        arguments: [
            ("captured-error-400-additional-formats-per-part", "invalid_additional_format_options", nil, nil, nil),
            ("captured-error-400-model", "invalid_model_id", "validation_error", "unsupported_model", "model_id"),
            ("captured-error-400-multichannel-diarize", "invalid_parameters", "validation_error", "invalid_parameters", "use_multi_channel"),
            ("captured-error-401", "invalid_api_key", "authentication_error", "unauthorized", nil),
        ] as [(String, String, String?, String?, String?)]
    )
    func capturedErrors(name: String, status: String, type: String?, code: String?, param: String?) throws {
        let response = try JSONDecoder().decode(Components.Schemas.BadRequestError.self, from: fixture(name))
        let detail = try #require(response.detail)
        #expect(detail.status == status)
        #expect(detail._type == type)
        #expect(detail.code == code)
        #expect(detail.param == param)
        #expect(detail.message?.isEmpty == false)
        if type != nil { #expect(detail.request_id?.isEmpty == false) }
    }

    @Test func missingOptionalFieldsRemainCompatible() throws {
        let data = try fixture("reference-single-channel")
        let transcript = try JSONDecoder().decode(Components.Schemas.SpeechToTextChunkResponseModel.self, from: data)
        #expect(transcript.audio_duration_secs == nil)
        #expect(transcript.words.first?.channel_index == nil)
    }
}
