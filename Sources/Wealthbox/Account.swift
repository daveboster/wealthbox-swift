import Foundation

public struct Account: Codable, Sendable {
    public let id: Int
    public let name: String
    public let createdAt: String

    public init() {
        self.id = 0
        self.name = ""
        self.createdAt = ""
    }

    public init(id: Int, name: String, createdAt: String) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}
