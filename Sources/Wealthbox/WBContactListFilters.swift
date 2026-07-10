import Foundation

public struct WBContactListFilters: Sendable {
    public let contactType: String?
    public let name: String?
    public let email: String?
    public let phone: String?
    public let active: Bool?
    public let type: String?

    public init(
        contactType: String? = nil,
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        active: Bool? = nil,
        type: String? = nil
    ) {
        self.contactType = contactType
        self.name = name
        self.email = email
        self.phone = phone
        self.active = active
        self.type = type
    }

    public func queryItems() throws -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if let type, !type.isEmpty {
            items.append(URLQueryItem(name: "type", value: try Self.normalizedType(type)))
        }
        if let contactType, !contactType.isEmpty {
            items.append(URLQueryItem(name: "contact_type", value: try Self.normalizedContactType(contactType)))
        }
        if let name, !name.isEmpty {
            items.append(URLQueryItem(name: "name", value: name))
        }
        if let email, !email.isEmpty {
            items.append(URLQueryItem(name: "email", value: email))
        }
        if let phone, !phone.isEmpty {
            items.append(URLQueryItem(name: "phone", value: phone))
        }
        if let active {
            items.append(URLQueryItem(name: "active", value: active ? "true" : "false"))
        }

        return items
    }

    private static func normalizedType(_ value: String) throws -> String {
        let normalized = try WBContacts.normalizedValue(
            value,
            allowedValues: WBContacts.supportedTypes,
            fieldName: "contact type"
        )
        return normalized.lowercased()
    }

    private static func normalizedContactType(_ value: String) throws -> String {
        try WBContacts.normalizedValue(
            value,
            allowedValues: WBContacts.supportedContactTypes,
            fieldName: "contact_type"
        )
    }
}
