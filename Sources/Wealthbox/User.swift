import Foundation

public struct User: Codable, Sendable {
    public let id: Int
    public let email: String
    public let name: String
    public let account: Int

    public init(id: Int, email: String, name: String, account: Int) {
        self.id = id
        self.email = email
        self.name = name
        self.account = account
    }
}
