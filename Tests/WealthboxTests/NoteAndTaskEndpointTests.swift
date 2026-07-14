import Foundation
import Testing
@testable import Wealthbox

/// Stubbed-transport coverage for the note read/update, note tags, and task
/// delete endpoints added for the QA-workspace tier-2 suite.
@Suite(.serialized)
struct NoteAndTaskEndpointTests {
    @Test
    func getNoteAppendsIdentifierToNotesEndpoint() throws {
        let session = URLSession.stubbedNoteTaskSession { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/notes/321")
            #expect(request.httpMethod == "GET")
            return makeNoteTaskJSONResponse(statusCode: 200, body: WBNote.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let note = try client.getNote(id: 321)

        #expect(note.id == 1)
    }

    @Test
    func getNotesBuildsDocumentedFilterQueryParametersAndDecodesStatusUpdates() throws {
        let session = URLSession.stubbedNoteTaskSession { request in
            #expect(request.url?.path == "/v1/notes")
            let queryItems = Dictionary(
                uniqueKeysWithValues: URLComponents(
                    url: try #require(request.url),
                    resolvingAgainstBaseURL: false
                )?.queryItems?.map { ($0.name, $0.value) } ?? []
            )
            #expect(queryItems == [
                "resource_id": "42",
                "resource_type": "Contact",
                "order": "updated",
                "updated_since": "2026-07-01 00:00 AM -0400",
                "page": "2",
                "per_page": "50"
            ])
            return makeNoteTaskJSONResponse(statusCode: 200, body: WBNotes.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let notes = try client.getNotes(filters: WBNoteListFilters(
            resourceId: 42,
            resourceType: "Contact",
            order: "updated",
            updatedSince: "2026-07-01 00:00 AM -0400",
            page: 2,
            perPage: 50
        ))

        #expect(notes.notes.count == 1)
        #expect(notes.statusUpdates.first?.id == 1)
        #expect(notes.page == 1)
        #expect(notes.perPage == 25)
    }

    @Test
    func createNoteSendsDocumentedTagsArray() throws {
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbedNoteTaskSession { request in
            if let data = noteTaskRequestBodyData(from: request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeNoteTaskJSONResponse(statusCode: 201, body: WBNote.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.createNote(
            content: "Reviewed the plan.",
            linkedTo: [WBNoteLink(id: 42, type: "Contact")],
            tags: ["wb-qa-test", "wb-qa-test-run-20260714-033320-a1b2"]
        )

        #expect(capturedBody?["content"] as? String == "Reviewed the plan.")
        #expect(capturedBody?["tags"] as? [String] == ["wb-qa-test", "wb-qa-test-run-20260714-033320-a1b2"])
    }

    @Test
    func createNoteOmitsTagsWhenNotProvided() throws {
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbedNoteTaskSession { request in
            if let data = noteTaskRequestBodyData(from: request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeNoteTaskJSONResponse(statusCode: 201, body: WBNote.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.createNote(content: "Called client.", contactId: 7)

        #expect(capturedBody?.keys.contains("tags") == false)
    }

    @Test
    func updateNotePutsReplacementContentToNoteEndpoint() throws {
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbedNoteTaskSession { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/notes/321")
            #expect(request.httpMethod == "PUT")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            if let data = noteTaskRequestBodyData(from: request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeNoteTaskJSONResponse(statusCode: 200, body: WBNote.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let note = try client.updateNote(
            id: 321,
            content: "Replaced content.",
            linkedTo: [WBNoteLink(id: 42, type: "Contact")],
            visibleTo: "Everyone",
            tags: ["wb-qa-test"]
        )

        #expect(note.id == 1)
        #expect(capturedBody?["content"] as? String == "Replaced content.")
        #expect(capturedBody?["visible_to"] as? String == "Everyone")
        #expect(capturedBody?["tags"] as? [String] == ["wb-qa-test"])
        let linked = capturedBody?["linked_to"] as? [[String: Any]]
        #expect(linked?.first?["id"] as? Int == 42)
    }

    @Test
    func updateNoteOmitsNilOptionalFields() throws {
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbedNoteTaskSession { request in
            if let data = noteTaskRequestBodyData(from: request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeNoteTaskJSONResponse(statusCode: 200, body: WBNote.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.updateNote(id: 321, content: "Replaced content.")

        #expect(capturedBody?["content"] as? String == "Replaced content.")
        #expect(capturedBody?.keys.contains("linked_to") == false)
        #expect(capturedBody?.keys.contains("visible_to") == false)
        #expect(capturedBody?.keys.contains("tags") == false)
    }

    @Test
    func deleteTaskSendsDeleteAndDecodesReturnedTaskBody() throws {
        let session = URLSession.stubbedNoteTaskSession { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/tasks/1234")
            #expect(request.httpMethod == "DELETE")
            return makeNoteTaskJSONResponse(statusCode: 200, body: WBTask.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let task = try client.deleteTask(id: 1234)

        #expect(task.id == 1)
    }

    @Test
    func deleteTaskMapsNotFoundToServerError() throws {
        let session = URLSession.stubbedNoteTaskSession { request in
            makeNoteTaskJSONResponse(statusCode: 404, body: "Not found", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.deleteTask(id: 999)
            Issue.record("Expected 404 to throw.")
        } catch let error as WealthboxError {
            #expect(error == .serverError(code: 404, message: "Not found"))
        }
    }
}

// Local stubbing helpers, kept file-private to avoid colliding with the
// equivalents in WealthboxApiClientTests.swift.
private final class NoteTaskMockURLProtocol: URLProtocol {
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
    static func stubbedNoteTaskSession(
        _ handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data?)
    ) -> URLSession {
        NoteTaskMockURLProtocol.requestHandler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NoteTaskMockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private func makeNoteTaskJSONResponse(statusCode: Int, body: String, request: URLRequest) -> (HTTPURLResponse, Data?) {
    let response = HTTPURLResponse(
        url: request.url!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    return (response, body.data(using: .utf8))
}

private func noteTaskRequestBodyData(from request: URLRequest) -> Data? {
    if let httpBody = request.httpBody {
        return httpBody
    }

    guard let stream = request.httpBodyStream else {
        return nil
    }

    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
        let count = stream.read(buffer, maxLength: bufferSize)
        if count < 0 {
            return nil
        }
        if count == 0 {
            break
        }
        data.append(buffer, count: count)
    }

    return data
}
