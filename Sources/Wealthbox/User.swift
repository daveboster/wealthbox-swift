import Foundation

public struct User: Codable, Sendable {
    public let id: Int
    public let email: String
    public let name: String
    public let account: Int
    /// The documented user status on `/v1/me`'s `current_user`
    /// (`active`, `invited`, `inactive`, or `legacy`). Optional because other
    /// user payloads may omit it.
    public let status: String?

    public init(id: Int, email: String, name: String, account: Int, status: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.account = account
        self.status = status
    }
}
