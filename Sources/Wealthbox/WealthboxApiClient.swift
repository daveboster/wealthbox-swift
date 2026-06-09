import Foundation

public enum FetchMethods: String, Sendable {
    case me = "/v1/me"
    case events = "/v1/events"
    case eventCategories = "/v1/categories/event_categories"
    case customFields = "/v1/categories/custom_fields"
    case contacts = "/v1/contacts"
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

    public func getCurrentUser() throws -> Workspace {
        try get(.me)
    }

    public func getEvent(id: Int) throws -> WBEvent {
        try get(.events, id: id)
    }

    public func getEvents(includeCategories: Bool = false) throws -> WBEvents {
        if includeCategories {
            let categories = try getEventCategories()
            let events: WBEvents = try get(.events)
            return events.enrichedWithCategories(categories)
        }

        return try get(.events)
    }

    public func getEventCategories() throws -> WBEventCategories {
        try get(.eventCategories)
    }

    public func getEventCustomFields() throws -> WBCustomFieldDefinitions {
        try getCustomFields(documentType: "Event")
    }

    public func getContactCustomFields() throws -> WBCustomFieldDefinitions {
        try getCustomFields(documentType: "Contact")
    }

    public func get<T: WBData>(_ method: FetchMethods, id: Int? = nil, queryItems: [URLQueryItem] = []) throws -> T {
        guard let url = endpoint(method, id: id, queryItems: queryItems) else {
            throw WealthboxError.internalError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let accessToken {
            request.setValue(accessToken, forHTTPHeaderField: "ACCESS_TOKEN")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
                capture(error: .serverError(code: -1, message: error.localizedDescription))
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
            return try T.decode(capturedBody) as! T
        }
        throw WealthboxError.internalError
    }

    private func getCustomFields(documentType: String) throws -> WBCustomFieldDefinitions {
        try get(.customFields, queryItems: [
            URLQueryItem(name: "document_type", value: documentType)
        ])
    }

    private func endpoint(_ method: FetchMethods, id: Int?, queryItems: [URLQueryItem]) -> URL? {
        let path = endpointPath(method, id: id)
        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            return nil
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    private func endpointPath(_ method: FetchMethods, id: Int?) -> String {
        guard let id else {
            return method.rawValue
        }
        return "\(method.rawValue)/\(id)"
    }
}
