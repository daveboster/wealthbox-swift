import Foundation
import Testing
@testable import Wealthbox

@Suite(.serialized)
struct WealthboxApiClientTests {
    @Test
    func baseURLDefaultsToProductionAPI() {
        let client = WealthboxApiClient()

        #expect(client.currentBaseUrl == WealthboxApiClient.defaultBaseUrl)
    }

    @Test
    func baseURLCanBeOverridden() {
        let client = WealthboxApiClient(baseURL: "https://example.com")

        #expect(client.currentBaseUrl == "https://example.com")
    }

    @Test
    func getCurrentUserBuildsExpectedRequestAndAccessTokenHeader() throws {
        let expectedToken = "token-123"
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/me")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "ACCESS_TOKEN") == expectedToken)
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            return makeJSONResponse(statusCode: 200, body: Workspace.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session, accessToken: expectedToken)

        let workspace = try client.getCurrentUser()

        #expect(workspace.id == 1)
    }

    @Test
    func getContactAppendsIdentifierToContactsEndpoint() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/contacts/48828625")
            return makeJSONResponse(statusCode: 200, body: WBContact.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let contact: WBContact = try client.get(.contacts, id: 48_828_625)

        #expect(contact.id == 1)
    }

    @Test
    func searchContactsBuildsExpectedQueryParameters() throws {
        let session = URLSession.stubbed { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            #expect(components?.path == "/v1/contacts")
            let items = Dictionary(
                uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item -> (String, String)? in
                    guard let value = item.value else { return nil }
                    return (item.name, value)
                }
            )
            #expect(items["name"] == "Anderson")
            #expect(items["email"] == "kevin@example.com")
            #expect(items["type"] == "household")
            #expect(items["active"] == "true")
            #expect(items["page"] == "2")
            #expect(items["per_page"] == "50")
            return makeJSONResponse(statusCode: 200, body: WBContacts.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let contacts = try client.searchContacts(
            name: "Anderson",
            email: "kevin@example.com",
            type: "household",
            active: true,
            page: 2,
            perPage: 50
        )

        #expect(contacts.contacts.count == 1)
    }

    @Test
    func createNotePostsExpectedBodyAndDecodesResponse() throws {
        let expectedToken = "token-abc"
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/notes")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "ACCESS_TOKEN") == expectedToken)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            if let data = requestBodyData(request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeJSONResponse(statusCode: 201, body: WBNote.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session, accessToken: expectedToken)

        let note = try client.createNote(
            content: "Reviewed the plan with the household.",
            linkedTo: [WBNoteLink(id: 42, type: "Contact")],
            visibleTo: "Everyone"
        )

        #expect(note.id == 1)
        #expect(note.content == "Spoke with Kevin about the upcoming review meeting.")
        #expect(capturedBody?["content"] as? String == "Reviewed the plan with the household.")
        #expect(capturedBody?["visible_to"] as? String == "Everyone")
        let linked = capturedBody?["linked_to"] as? [[String: Any]]
        #expect(linked?.count == 1)
        #expect(linked?.first?["id"] as? Int == 42)
        #expect(linked?.first?["type"] as? String == "Contact")
    }

    @Test
    func createNoteConvenienceLinksSingleContactAndOmitsEmptyFields() throws {
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbed { request in
            if let data = requestBodyData(request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeJSONResponse(statusCode: 201, body: WBNote.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.createNote(content: "Called client.", contactId: 7)

        #expect(capturedBody?["content"] as? String == "Called client.")
        // visible_to is nil and must be omitted, not sent as null.
        #expect(capturedBody?.keys.contains("visible_to") == false)
        let linked = capturedBody?["linked_to"] as? [[String: Any]]
        #expect(linked?.first?["id"] as? Int == 7)
        #expect(linked?.first?["type"] as? String == "Contact")
    }

    @Test
    func errorStatusCodesMapToWealthboxErrors() throws {
        try assertStatusCode(400, body: "Bad request body", mapsTo: .badRequest(message: "Bad request body"))
        try assertStatusCode(401, body: "Unauthorized body", mapsTo: .unauthorized(message: "Unauthorized body"))
        try assertStatusCode(429, body: "Too many requests", mapsTo: .rateLimited(retryAfter: nil))
        try assertStatusCode(500, body: "Server exploded", mapsTo: .internalServerError(message: "Server exploded"))
        try assertStatusCode(418, body: "Teapot", mapsTo: .serverError(code: 418, message: "Teapot"))
    }

    @Test
    func rateLimitedParsesRetryAfterHeader() throws {
        let session = URLSession.stubbed { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Retry-After": "30"]
            )!
            return (response, Data("slow down".utf8))
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.getCurrentUser()
            Issue.record("Expected 429 to throw.")
        } catch let error as WealthboxError {
            #expect(error == .rateLimited(retryAfter: 30))
            #expect(error.retryAfterSeconds == 30)
            #expect(error.isRetriable)
        }
    }

    @Test
    func transportErrorsMapToNetworkError() throws {
        let session = URLSession.stubbed { _ in
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "Simulated offline"]
            )
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.getCurrentUser()
            Issue.record("Expected getCurrentUser to throw.")
        } catch let error as WealthboxError {
            #expect(error == .network(message: "Simulated offline"))
            #expect(error.isRetriable)
        }
    }

    private func assertStatusCode(_ statusCode: Int, body: String, mapsTo expected: WealthboxError) throws {
        let session = URLSession.stubbed { request in
            makeJSONResponse(statusCode: statusCode, body: body, request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.getCurrentUser()
            Issue.record("Expected status \(statusCode) to throw.")
        } catch let error as WealthboxError {
            #expect(error == expected)
        }
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLSession {
    static func stubbed(_ handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data?)) -> URLSession {
        MockURLProtocol.requestHandler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private func makeJSONResponse(statusCode: Int, body: String, request: URLRequest) -> (HTTPURLResponse, Data?) {
    let response = HTTPURLResponse(
        url: request.url!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    return (response, body.data(using: .utf8))
}

/// Reads a request body regardless of whether `URLSession` kept it as
/// `httpBody` or converted it to an `httpBodyStream` (the common case for
/// bodies handed to a `URLProtocol` stub).
private func requestBodyData(_ request: URLRequest) -> Data? {
    if let body = request.httpBody {
        return body
    }
    guard let stream = request.httpBodyStream else {
        return nil
    }
    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 4096
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
        let read = stream.read(buffer, maxLength: bufferSize)
        if read <= 0 { break }
        data.append(buffer, count: read)
    }
    return data
}
