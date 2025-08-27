import HTTPTypes
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

/// Injects an authorization header to every request.
public struct AuthenticationMiddleware: ClientMiddleware {
    /// x-goog-api-key
    public var apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        if let httpFieldName = HTTPField.Name.init("xi-api-key") {
            request.headerFields[httpFieldName] = apiKey
        }
        return try await next(request, body, baseURL)
    }
}