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
            if let data = requestBodyData(from: request) {
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
            if let data = requestBodyData(from: request) {
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
    func createTaskPostsExpectedBodyAndDecodesResponse() throws {
        let expectedToken = "token-task"
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/tasks")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "ACCESS_TOKEN") == expectedToken)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            if let data = requestBodyData(from: request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeJSONResponse(statusCode: 201, body: WBTask.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session, accessToken: expectedToken)

        let task = try client.createTask(
            name: "Follow up: rebalance review",
            dueDate: "2026-07-20 11:00 AM -0400",
            description: "From 7/13 meeting. expanse://household/42/meeting/7",
            linkedTo: [WBTaskLink(id: 42, type: "Contact", name: "The Andersons")],
            assignedTo: 5,
            priority: "High",
            customFields: [WBCustomFieldRequest(id: 9, value: "Retirement")]
        )

        #expect(task.id == 1)
        #expect(task.name == "Return Bill's call")
        #expect(task.descriptionHtml == "<div>Follow up from message...</div>")
        #expect(capturedBody?["name"] as? String == "Follow up: rebalance review")
        #expect(capturedBody?["due_date"] as? String == "2026-07-20 11:00 AM -0400")
        #expect(capturedBody?["description"] as? String == "From 7/13 meeting. expanse://household/42/meeting/7")
        #expect(capturedBody?["assigned_to"] as? Int == 5)
        #expect(capturedBody?["priority"] as? String == "High")
        let linked = capturedBody?["linked_to"] as? [[String: Any]]
        #expect(linked?.first?["id"] as? Int == 42)
        #expect(linked?.first?["type"] as? String == "Contact")
        let customFields = capturedBody?["custom_fields"] as? [[String: Any]]
        #expect(customFields?.first?["id"] as? Int == 9)
        #expect(customFields?.first?["value"] as? String == "Retirement")
    }

    @Test
    func createTaskConvenienceLinksSingleContactAndOmitsEmptyFields() throws {
        nonisolated(unsafe) var capturedBody: [String: Any]?
        let session = URLSession.stubbed { request in
            if let data = requestBodyData(from: request) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return makeJSONResponse(statusCode: 201, body: WBTask.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.createTask(name: "Send letter", dueDate: "2026-07-20 09:00 AM -0400", contactId: 7)

        #expect(capturedBody?["name"] as? String == "Send letter")
        // Optional fields are nil and must be omitted, not sent as null.
        #expect(capturedBody?.keys.contains("assigned_to") == false)
        #expect(capturedBody?.keys.contains("priority") == false)
        #expect(capturedBody?.keys.contains("custom_fields") == false)
        let linked = capturedBody?["linked_to"] as? [[String: Any]]
        #expect(linked?.first?["id"] as? Int == 7)
        #expect(linked?.first?["type"] as? String == "Contact")
    }

    @Test
    func getTaskAppendsIdentifierToTasksEndpoint() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/tasks/1234")
            #expect(request.httpMethod == "GET")
            return makeJSONResponse(statusCode: 200, body: WBTask.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let task = try client.getTask(id: 1234)

        #expect(task.id == 1)
        #expect(task.complete == true)
    }

    @Test
    func getTasksBuildsDocumentedFilterQueryParameters() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.path == "/v1/tasks")
            let queryItems = Dictionary(
                uniqueKeysWithValues: URLComponents(
                    url: try #require(request.url),
                    resolvingAgainstBaseURL: false
                )?.queryItems?.map { ($0.name, $0.value) } ?? []
            )
            #expect(queryItems == [
                "resource_id": "42",
                "resource_type": "Contact",
                "completed": "true",
                "task_type": "parents",
                "updated_since": "2026-07-01 00:00 AM -0400"
            ])
            return makeJSONResponse(statusCode: 200, body: WBTasks.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let tasks = try client.getTasks(
            filters: WBTaskListFilters(
                resourceId: 42,
                resourceType: "Contact",
                completed: true,
                taskType: "parents",
                updatedSince: "2026-07-01 00:00 AM -0400"
            )
        )

        #expect(tasks.tasks.count == 1)
        #expect(tasks.page == 1)
        #expect(tasks.perPage == 25)
    }

    @Test
    func getContactsBuildsDocumentedFilterQueryParameters() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.path == "/v1/contacts")
            let queryItems = Dictionary(
                uniqueKeysWithValues: URLComponents(
                    url: try #require(request.url),
                    resolvingAgainstBaseURL: false
                )?.queryItems?.map { ($0.name, $0.value) } ?? []
            )
            #expect(queryItems == [
                "type": "person",
                "contact_type": "Past Client",
                "name": "Anderson",
                "email": "kevin@example.com",
                "phone": "(555) 123-4567",
                "active": "true"
            ])
            return makeJSONResponse(statusCode: 200, body: WBContacts.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.getContacts(
            filters: WBContactListFilters(
                contactType: "Past Client",
                name: "Anderson",
                email: "kevin@example.com",
                phone: "(555) 123-4567",
                active: true,
                type: "Person"
            )
        )
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
    func getEventCustomFieldsUsesEventDocumentTypeQuery() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/categories/custom_fields?document_type=Event")
            return makeJSONResponse(statusCode: 200, body: WBCustomFieldDefinitions.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let customFields = try client.getEventCustomFields()

        #expect(customFields.customFields.first?.name == "Meeting Type")
        #expect(customFields.customFields.first?.documentType == "Event")
    }

    @Test
    func getContactCustomFieldsUsesContactDocumentTypeQuery() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/categories/custom_fields?document_type=Contact")
            return makeJSONResponse(statusCode: 200, body: WBCustomFieldDefinitions.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.getContactCustomFields()
    }

    @Test
    func getEventsBuildsDocumentedStartDateFilterQueryParameters() throws {
        let session = URLSession.stubbed { request in
            #expect(request.url?.path == "/v1/events")
            let queryItems = Dictionary(
                uniqueKeysWithValues: URLComponents(
                    url: try #require(request.url),
                    resolvingAgainstBaseURL: false
                )?.queryItems?.map { ($0.name, $0.value) } ?? []
            )
            #expect(queryItems == [
                "start_date_min": "2026-06-01",
                "start_date_max": "2026-06-30"
            ])
            return makeJSONResponse(statusCode: 200, body: WBEvents.sampleJSON(), request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        _ = try client.getEvents(filters: WBEventListFilters(fromDate: "2026-06-01", untilDate: "2026-06-30"))
    }

    @Test
    func getEventsRejectsInvalidStartDateBeforeRequesting() throws {
        nonisolated(unsafe) var requestCount = 0
        let session = URLSession.stubbed { request in
            requestCount += 1
            return makeJSONResponse(statusCode: 500, body: "Request should not be sent", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.getEvents(filters: WBEventListFilters(fromDate: "06/01/2026"))
            Issue.record("Expected invalid from date to throw.")
        } catch let error as WealthboxError {
            #expect(error == .validationError(message: "Invalid from date '06/01/2026'. Use YYYY-MM-DD format."))
        }

        #expect(requestCount == 0)
    }

    @Test
    func getEventsWithCategoriesFetchesCategoriesBeforeEventsAndEnrichesResults() throws {
        nonisolated(unsafe) var requestedPaths: [String] = []
        let session = URLSession.stubbed { request in
            requestedPaths.append(request.url?.path ?? "")
            if request.url?.path == "/v1/categories/event_categories" {
                return makeJSONResponse(statusCode: 200, body: WBEventCategories.sampleJSON(), request: request)
            }
            if request.url?.path == "/v1/events" {
                return makeJSONResponse(statusCode: 200, body: WBEvents.sampleJSON(), request: request)
            }
            return makeJSONResponse(statusCode: 404, body: "Unexpected path", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let events = try client.getEvents(includeCategories: true)

        #expect(requestedPaths == ["/v1/categories/event_categories", "/v1/events"])
        #expect(events.events.first?.eventCategory == 2)
        #expect(events.events.first?.category?.id == 2)
        #expect(events.events.first?.category?.name == "Review")
    }

    @Test
    func updateEventCategoryFetchesEventThenPutsRequiredFieldsAndNewCategory() throws {
        nonisolated(unsafe) var requests: [String] = []
        let session = URLSession.stubbed { request in
            requests.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")

            if request.httpMethod == "GET", request.url?.path == "/v1/events/1" {
                return makeJSONResponse(statusCode: 200, body: WBEvent.sampleJSON(), request: request)
            }

            if request.httpMethod == "PUT", request.url?.path == "/v1/events/1" {
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
                let body = try #require(requestBodyData(from: request))
                let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
                #expect(json["title"] as? String == "Client Meeting")
                #expect(json["starts_at"] as? String == "2015-05-24 10:00 AM -0400")
                #expect(json["ends_at"] as? String == "2015-05-24 11:00 AM -0400")
                #expect(json["event_category"] as? Int == 3)
                #expect(json["category"] == nil)
                #expect(json["id"] == nil)
                return makeJSONResponse(statusCode: 200, body: eventJSON(categoryId: 3), request: request)
            }

            return makeJSONResponse(statusCode: 404, body: "Unexpected request", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let event = try client.updateEventCategory(eventId: 1, fromCategoryId: 2, toCategoryId: 3)

        #expect(requests == ["GET /v1/events/1", "PUT /v1/events/1"])
        #expect(event.eventCategory == 3)
    }

    @Test
    func updateEventCategoryDoesNotPutWhenCurrentCategoryDoesNotMatchExpectedFromCategory() throws {
        nonisolated(unsafe) var requests: [String] = []
        let session = URLSession.stubbed { request in
            requests.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")

            if request.httpMethod == "GET", request.url?.path == "/v1/events/1" {
                return makeJSONResponse(statusCode: 200, body: WBEvent.sampleJSON(), request: request)
            }

            return makeJSONResponse(statusCode: 500, body: "PUT should not be sent", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.updateEventCategory(eventId: 1, fromCategoryId: 99, toCategoryId: 3)
            Issue.record("Expected mismatched from category to throw.")
        } catch let error as WealthboxError {
            #expect(error == .validationError(message: "Event 1 has event_category 2, expected 99. No update sent."))
        }

        #expect(requests == ["GET /v1/events/1"])
    }

    @Test
    func updateEventCategoryByNameResolvesNamesBeforeUpdating() throws {
        nonisolated(unsafe) var requests: [String] = []
        let session = URLSession.stubbed { request in
            requests.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")

            if request.httpMethod == "GET", request.url?.path == "/v1/categories/event_categories" {
                return makeJSONResponse(statusCode: 200, body: WBEventCategories.sampleJSON(), request: request)
            }

            if request.httpMethod == "GET", request.url?.path == "/v1/events/1" {
                return makeJSONResponse(statusCode: 200, body: WBEvent.sampleJSON(), request: request)
            }

            if request.httpMethod == "PUT", request.url?.path == "/v1/events/1" {
                let body = try #require(requestBodyData(from: request))
                let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
                #expect(json["event_category"] as? Int == 1)
                return makeJSONResponse(statusCode: 200, body: eventJSON(categoryId: 1), request: request)
            }

            return makeJSONResponse(statusCode: 404, body: "Unexpected request", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let event = try client.updateEventCategory(eventId: 1, fromCategoryName: "review", toCategoryName: "Client Meeting")

        #expect(requests == [
            "GET /v1/categories/event_categories",
            "GET /v1/events/1",
            "PUT /v1/events/1"
        ])
        #expect(event.eventCategory == 1)
    }

    @Test
    func updateEventStateFetchesEventThenPutsRequiredFieldsCurrentCategoryAndNewState() throws {
        nonisolated(unsafe) var requests: [String] = []
        let session = URLSession.stubbed { request in
            requests.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")

            if request.httpMethod == "GET", request.url?.path == "/v1/events/1" {
                return makeJSONResponse(statusCode: 200, body: WBEvent.sampleJSON(), request: request)
            }

            if request.httpMethod == "PUT", request.url?.path == "/v1/events/1" {
                let body = try #require(requestBodyData(from: request))
                let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
                #expect(json["title"] as? String == "Client Meeting")
                #expect(json["starts_at"] as? String == "2015-05-24 10:00 AM -0400")
                #expect(json["ends_at"] as? String == "2015-05-24 11:00 AM -0400")
                #expect(json["event_category"] as? Int == 2)
                #expect(json["state"] as? String == "completed")
                return makeJSONResponse(statusCode: 200, body: eventJSON(categoryId: 2, state: "completed"), request: request)
            }

            return makeJSONResponse(statusCode: 404, body: "Unexpected request", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        let event = try client.updateEventState(eventId: 1, fromState: "confirmed", toState: "completed")

        #expect(requests == ["GET /v1/events/1", "PUT /v1/events/1"])
        #expect(event.state == "completed")
    }

    @Test
    func updateEventStateDoesNotPutWhenCurrentStateDoesNotMatchExpectedFromState() throws {
        nonisolated(unsafe) var requests: [String] = []
        let session = URLSession.stubbed { request in
            requests.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")

            if request.httpMethod == "GET", request.url?.path == "/v1/events/1" {
                return makeJSONResponse(statusCode: 200, body: WBEvent.sampleJSON(), request: request)
            }

            return makeJSONResponse(statusCode: 500, body: "PUT should not be sent", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.updateEventState(eventId: 1, fromState: "tentative", toState: "completed")
            Issue.record("Expected mismatched from state to throw.")
        } catch let error as WealthboxError {
            #expect(error == .validationError(message: "Event 1 has state 'confirmed', expected 'tentative'. No update sent."))
        }

        #expect(requests == ["GET /v1/events/1"])
    }

    @Test
    func updateEventStateRejectsInvalidStateBeforeFetchingEvent() throws {
        nonisolated(unsafe) var requestCount = 0
        let session = URLSession.stubbed { request in
            requestCount += 1
            return makeJSONResponse(statusCode: 500, body: "Request should not be sent", request: request)
        }
        let client = WealthboxApiClient(baseURL: "https://example.com", session: session)

        do {
            _ = try client.updateEventState(eventId: 1, fromState: "confirmed", toState: "done")
            Issue.record("Expected invalid to state to throw.")
        } catch let error as WealthboxError {
            #expect(error == .validationError(message: "Invalid event state 'done'. Use one of: unconfirmed, confirmed, tentative, completed, cancelled."))
        }

        #expect(requestCount == 0)
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

private func eventJSON(categoryId: Int, state: String = "confirmed") -> String {
    """
    {
      "id": 1,
      "creator": 1,
      "created_at": "2015-05-24 10:00 AM -0400",
      "updated_at": "2015-10-12 11:30 PM -0400",
      "title": "Client Meeting",
      "starts_at": "2015-05-24 10:00 AM -0400",
      "ends_at": "2015-05-24 11:00 AM -0400",
      "repeats": true,
      "event_category": \(categoryId),
      "all_day": true,
      "location": "Conference Room",
      "description": "Review meeting for Kevin...",
      "state": "\(state)",
      "visible_to": "Everyone",
      "email_invitees": true,
      "linked_to": [],
      "invitees": [],
      "custom_fields": []
    }
    """
}

private func requestBodyData(from request: URLRequest) -> Data? {
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
