import Foundation

public protocol WBData: Codable {
    associatedtype AssocType: WBData where AssocType: Decodable

    static func fromJSONString(_ jsonString: String) -> AssocType
    static func decode(_ jsonString: String) throws -> AssocType
    static func sampleJSON() -> String
    static func sample() -> AssocType

    var json: String? { get set }
}

public protocol WealthboxItem: Hashable {
    var wealthboxId: Int { get }
    var wealthboxType: WealthboxItemType { get }
    var wealthboxName: String? { get }
}

public enum WealthboxItemType: Codable {
    case contact(WBContact)
    case unknown(WBContact)

    private enum DiscriminatorCodingKey: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: DiscriminatorCodingKey.self),
           let discriminator = try? container.decode(String.self, forKey: .type),
           let content = try? WBContact(from: decoder) {
            switch discriminator.lowercased() {
            case "contact", "person", "household", "organization", "trust":
                self = .contact(content)
            default:
                self = .unknown(content)
            }
            return
        }

        throw DecodingError.typeMismatch(
            WBContact.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "The type of the decoded Wealthbox item cannot be determined."
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .contact(let contact):
            try contact.encode(to: encoder)
        case .unknown(let contact):
            try contact.encode(to: encoder)
        }
    }
}

extension WBContact: WealthboxItem {
    public var wealthboxType: WealthboxItemType {
        switch (type ?? "").lowercased() {
        case "person", "organization", "household", "trust":
            return .contact(self)
        default:
            return .unknown(self)
        }
    }

    public var wealthboxName: String? {
        name
    }

    public var wealthboxId: Int {
        id ?? 0
    }

    public static func == (lhs: WBContact, rhs: WBContact) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public protocol WealthboxItems {
    var contacts: [any WealthboxItem] { get set }
}
