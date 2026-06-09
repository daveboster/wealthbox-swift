public struct IntegrationSettings: Sendable {
    public let accessToken: String?
    public let baseURL: String

    public init(accessToken: String?, baseURL: String = WealthboxApiClient.defaultBaseUrl) {
        self.accessToken = accessToken
        self.baseURL = baseURL
    }
}
