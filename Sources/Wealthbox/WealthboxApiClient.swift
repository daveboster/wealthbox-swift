import Foundation

public enum FetchMethods: String, Sendable {
    case me = "/v1/me"
    case events = "/v1/events"
    case contacts = "/v1/contacts"
    case notes = "/v1/notes"
}

public final class WealthboxApiClient: Sendable {
    public static let defaultBaseUrl = "https://api.crmworkspace.com"

    private let baseURL: String
    private let accessToken: String?
    private let session: URLSession

    public var currentBaseUrl: String { baseURL }

    public init(_ accessToken: String? = nil) {
        self.baseURL = Self.defaultBaseUrl
        self.session = .shared
        self.accessToken = accessToken
    }

    public init(baseURL: String? = nil, accessToken: String? = nil) {
        self.baseURL = baseURL ?? Self.defaultBaseUrl
        self.session = .shared
        self.accessToken = accessToken
    }

    public init(baseURL: String? = nil, session: URLSession? = nil, accessToken: String? = nil) {
        self.baseURL = baseURL ?? Self.defaultBaseUrl
        self.session = session ?? .shared
        self.accessToken = accessToken
    }

    // MARK: - Current user

    public func getCurrentUser() throws -> Workspace {
        try get(.me)
    }

    // MARK: - Events

    public func getEvent(id: Int) throws -> WBEvent {
        try get(.events, id: id)
    }

    public func getEvents() throws -> WBEvents {
        try get(.events)
    }

    // MARK: - Contacts

    /// Fetches a single contact by its Wealthbox identifier.
    public func getContact(id: Int) throws -> WBContact {
        try get(.contacts, id: id)
    }

    /// Searches contacts using Wealthbox's documented `GET /v1/contacts` query
    /// parameters.
    ///
    /// `name` supports partial matches. `type` accepts the documented values
    /// `person`, `household`, `organization`, or `trust`. Every parameter is
    /// optional; passing none returns the first page of all contacts. Persons,
    /// households, and organizations are all contacts and are all searchable
    /// here.
    public func searchContacts(
        name: String? = nil,
        email: String? = nil,
        type: String? = nil,
        active: Bool? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) throws -> WBContacts {
        var queryItems: [URLQueryItem] = []
        if let name { queryItems.append(URLQueryItem(name: "name", value: name)) }
        if let email { queryItems.append(URLQueryItem(name: "email", value: email)) }
        if let type { queryItems.append(URLQueryItem(name: "type", value: type)) }
        if let active { queryItems.append(URLQueryItem(name: "active", value: active ? "true" : "false")) }
        if let page { queryItems.append(URLQueryItem(name: "page", value: String(page))) }
        if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: String(perPage))) }
        return try get(.contacts, queryItems: queryItems)
    }

    // MARK: - Notes (write)

    /// Creates a note via `POST /v1/notes`, optionally linking it to Wealthbox
    /// records.
    ///
    /// - Parameters:
    ///   - content: The note body text.
    ///   - linkedTo: Records to attach the note to. Linking by a contact's own
    ///     id with `type: "Contact"` works for people, households, and
    ///     organizations, since all are contacts; callers that need a more
    ///     specific `linked_to` type (confirmed against the live Wealthbox API)
    ///     can set it explicitly via `WBNoteLink(id:type:)`.
    ///   - visibleTo: Optional visibility (e.g. `"Everyone"`, `"Private"`).
    @discardableResult
    public func createNote(
        content: String,
        linkedTo: [WBNoteLink] = [],
        visibleTo: String? = nil
    ) throws -> WBNote {
        let requestBody = WBNoteCreateRequest(
            content: content,
            linkedTo: linkedTo.isEmpty ? nil : linkedTo,
            visibleTo: visibleTo
        )
        let httpBody = try JSONEncoder().encode(requestBody)
        let url = try makeURL(path: endpoint(.notes, id: nil), queryItems: [])
        let request = makeRequest(method: "POST", url: url, body: httpBody)
        let responseBody = try perform(request)
        return try WBNote.decode(responseBody)
    }

    /// Convenience for the common case of linking a new note to a single contact.
    @discardableResult
    public func createNote(content: String, contactId: Int) throws -> WBNote {
        try createNote(content: content, linkedTo: [WBNoteLink(id: contactId, type: "Contact")])
    }

    // MARK: - Generic GET

    public func get<T: WBData>(
        _ method: FetchMethods,
        id: Int? = nil,
        queryItems: [URLQueryItem] = []
    ) throws -> T {
        let url = try makeURL(path: endpoint(method, id: id), queryItems: queryItems)
        let request = makeRequest(method: "GET", url: url, body: nil)
        let responseBody = try perform(request)
        return try T.decode(responseBody) as! T
    }

    // MARK: - Request plumbing

    private func endpoint(_ method: FetchMethods, id: Int?) -> String {
        guard let id else {
            return "\(baseURL)\(method.rawValue)"
        }
        return "\(baseURL)\(method.rawValue)/\(id)"
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(string: path) else {
            throw WealthboxError.internalError
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw WealthboxError.internalError
        }
        return url
    }

    private func makeRequest(method: String, url: URL, body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let accessToken {
            request.setValue(accessToken, forHTTPHeaderField: "ACCESS_TOKEN")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func perform(_ request: URLRequest) throws -> String {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        let lock = NSLock()
        nonisolated(unsafe) var capturedBody: String?
        nonisolated(unsafe) var capturedError: WealthboxError?

        let task = session.dataTask(with: request) { data, response, error in
            defer { dispatchGroup.leave() }

            func capture(error: WealthboxError) {
                lock.lock()
                capturedError = error
                lock.unlock()
            }

            if let error {
                capture(error: .network(message: error.localizedDescription))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                capture(error: .internalError)
                return
            }

            let bodyString = data.flatMap { String(data: $0, encoding: .utf8) }

            switch httpResponse.statusCode {
            case 400:
                capture(error: .badRequest(message: bodyString ?? "The server could not understand the request due to invalid syntax."))
                return
            case 401:
                capture(error: .unauthorized(message: bodyString ?? "Unauthorized. Access is denied due to invalid credentials."))
                return
            case 429:
                capture(error: .rateLimited(retryAfter: Self.retryAfterSeconds(from: httpResponse)))
                return
            case 500:
                capture(error: .internalServerError(message: bodyString ?? "The server has encountered a situation it doesn't know how to handle."))
                return
            default:
                break
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                capture(error: .serverError(code: httpResponse.statusCode, message: bodyString))
                return
            }

            guard let bodyString, !bodyString.isEmpty else {
                capture(error: .internalError)
                return
            }

            lock.lock()
            capturedBody = bodyString
            lock.unlock()
        }

        task.resume()
        dispatchGroup.wait()

        if let capturedError {
            throw capturedError
        }
        if let capturedBody {
            return capturedBody
        }
        throw WealthboxError.internalError
    }

    private static func retryAfterSeconds(from response: HTTPURLResponse) -> Int? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }
        return Int(value.trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - Request bodies

/// Encodable request body for `POST /v1/notes`.
///
/// `nil` optionals are omitted from the encoded JSON, so a note with no links
/// or explicit visibility sends only `content`.
struct WBNoteCreateRequest: Encodable {
    let content: String
    let linkedTo: [WBNoteLink]?
    let visibleTo: String?

    enum CodingKeys: String, CodingKey {
        case content
        case linkedTo = "linked_to"
        case visibleTo = "visible_to"
    }
}
