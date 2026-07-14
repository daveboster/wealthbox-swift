import Foundation
import Wealthbox

/// Run-time configuration for QA-workspace (tier-2/tier-3) runs, read
/// from environment variables at call time.
///
/// The QA access token is never stored in the repository or in test
/// code: a wrapper script (`bin/wb-qa-run`) reads it from the macOS
/// Keychain and exports it into the environment of the one command it runs.
/// When `WEALTHBOX_QA_ACCESS_TOKEN` is absent the QA suites are
/// skipped entirely and make no network calls, which keeps live tests out of
/// the standard `swift test` run and out of every CI merge path.
///
/// The expected workspace identity (`WEALTHBOX_QA_WORKSPACE_ID`, plus
/// the name cross-check) is deliberately *not* defaulted in code: the guard
/// fails closed when it is missing, and the values live alongside the token
/// in the Keychain rather than in this public package.
public struct QARunEnvironment: Sendable {
    /// Environment variable names, kept in one place so the wrapper script,
    /// tests, and docs cannot drift apart.
    public enum Variable {
        public static let accessToken = "WEALTHBOX_QA_ACCESS_TOKEN"
        public static let workspaceID = "WEALTHBOX_QA_WORKSPACE_ID"
        public static let workspaceName = "WEALTHBOX_QA_WORKSPACE_NAME"
        public static let allowMultiWorkspaceUser = "WEALTHBOX_QA_ALLOW_MULTI_WORKSPACE_USER"
        public static let baseURL = "WEALTHBOX_QA_BASE_URL"
        public static let seedHousehold = "WEALTHBOX_QA_SEED_HOUSEHOLD"
    }

    public static let defaultWorkspaceName = "QA"
    public static let defaultSeedHouseholdName = "Sample Household"

    public let accessToken: String?
    public let expectedWorkspaceID: Int?
    public let expectedWorkspaceName: String
    public let allowMultiWorkspaceUser: Bool
    public let baseURL: String?
    public let seedHouseholdName: String

    public init(
        accessToken: String? = nil,
        expectedWorkspaceID: Int? = nil,
        expectedWorkspaceName: String = QARunEnvironment.defaultWorkspaceName,
        allowMultiWorkspaceUser: Bool = false,
        baseURL: String? = nil,
        seedHouseholdName: String = QARunEnvironment.defaultSeedHouseholdName
    ) {
        self.accessToken = accessToken
        self.expectedWorkspaceID = expectedWorkspaceID
        self.expectedWorkspaceName = expectedWorkspaceName
        self.allowMultiWorkspaceUser = allowMultiWorkspaceUser
        self.baseURL = baseURL
        self.seedHouseholdName = seedHouseholdName
    }

    /// Builds a configuration from an environment dictionary. Injectable for
    /// tests; production callers use `fromProcessEnvironment()`.
    public init(environment: [String: String]) {
        self.init(
            accessToken: Self.nonEmpty(environment[Variable.accessToken]),
            expectedWorkspaceID: Self.nonEmpty(environment[Variable.workspaceID]).flatMap(Int.init),
            expectedWorkspaceName: Self.nonEmpty(environment[Variable.workspaceName])
                ?? QARunEnvironment.defaultWorkspaceName,
            allowMultiWorkspaceUser: Self.isTruthy(environment[Variable.allowMultiWorkspaceUser]),
            baseURL: Self.nonEmpty(environment[Variable.baseURL]),
            seedHouseholdName: Self.nonEmpty(environment[Variable.seedHousehold])
                ?? QARunEnvironment.defaultSeedHouseholdName
        )
    }

    public static func fromProcessEnvironment() -> QARunEnvironment {
        QARunEnvironment(environment: ProcessInfo.processInfo.environment)
    }

    /// Whether a QA run was requested at call time: true only when the
    /// wrapper (or caller) supplied a non-empty access token. This is the
    /// run-selection switch for the tier-2 suite — absent token, the suite is
    /// skipped and no client is ever constructed.
    public var isConfigured: Bool {
        accessToken != nil
    }

    /// A client pointed at the configured base URL with the QA token.
    public func makeClient() -> WealthboxApiClient {
        WealthboxApiClient(baseURL: baseURL, accessToken: accessToken)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func isTruthy(_ value: String?) -> Bool {
        guard let value = nonEmpty(value)?.lowercased() else {
            return false
        }
        return ["1", "true", "yes"].contains(value)
    }
}
