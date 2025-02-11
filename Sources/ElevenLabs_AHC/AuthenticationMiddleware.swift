import AsyncHTTPClient
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
    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// The token value.
    public var apiKey: String

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        if let httpFieldName = HTTPField.Name("xi-api-key") {
            request.headerFields[httpFieldName] = apiKey
        }
        return try await next(request, body, baseURL)
    }
}
