import Foundation

public extension WBContacts {
    static let supportedTypes = ["Person", "Household", "Organization", "Trust"]
    static let supportedContactTypes = ["Client", "Past Client", "Prospect", "Vendor", "Organization"]

    func filtered(type: String? = nil, contactType: String? = nil) throws -> WBContacts {
        let normalizedType = try type.map {
            try Self.normalizedValue(
                $0,
                allowedValues: Self.supportedTypes,
                fieldName: "contact type"
            )
        }
        let normalizedContactType = try contactType.map {
            try Self.normalizedValue(
                $0,
                allowedValues: Self.supportedContactTypes,
                fieldName: "contact_type"
            )
        }

        let filteredContacts = contacts.filter { contact in
            let matchesType = normalizedType.map { expected in
                contact.type?.caseInsensitiveCompare(expected) == .orderedSame
            } ?? true
            let matchesContactType = normalizedContactType.map { expected in
                contact.contactType?.caseInsensitiveCompare(expected) == .orderedSame
            } ?? true
            return matchesType && matchesContactType
        }

        return WBContacts(filteredContacts, page: page, perPage: perPage)
    }

    private static func normalizedValue(_ value: String, allowedValues: [String], fieldName: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = allowedValues.first(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return match
        }

        throw WealthboxError.validationError(
            message: "Invalid \(fieldName) '\(value)'. Use one of: \(allowedValues.joined(separator: ", "))."
        )
    }
}
