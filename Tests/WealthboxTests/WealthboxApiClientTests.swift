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
    func getEventCategoriesUsesCustomizableCategoryEndpoint() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/categories/event_categories")
            return makeJSONResponse(statusCode: 200, body: WBEventCategories.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let categories = try client.getEventCategories()

        #expect(categories.eventCategories.first?.name == "Client Meeting")
    }

    @Test
    func errorStatusCodesMapToWealthboxErrors() throws {
        try assertStatusCode(400, body: "Bad request body", mapsTo: .badRequest(message: "Bad request body"))
        try assertStatusCode(401, body: "Unauthorized body", mapsTo: .unauthorized(message: "Unauthorized body"))
        try assertStatusCode(500, body: "Server exploded", mapsTo: .internalServerError(message: "Server exploded"))
        try assertStatusCode(418, body: "Teapot", mapsTo: .serverError(code: 418, message: "Teapot"))
    }

    @Test
    func transportErrorsMapToServerErrorMinusOne() throws {
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
            #expect(error == .serverError(code: -1, message: "Simulated offline"))
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
