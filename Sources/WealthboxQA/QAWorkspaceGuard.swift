import Foundation
import Wealthbox

/// The identity facts a passing guard verified, safe to print in run output
/// (no token material).
public struct QAWorkspaceIdentity: Sendable {
    public let workspaceID: Int
    public let workspaceName: String
    public let userID: Int
    public let userName: String
    public let userEmail: String
    public let userStatus: String?
    /// Every workspace the credential's login profile can access, for the run
    /// log. A strict-mode pass means this contains exactly the QA
    /// workspace.
    public let accessibleWorkspaces: [QAWorkspaceSummary]

    public var summary: String {
        let workspaces = accessibleWorkspaces
            .map { "\($0.name) (\($0.id))" }
            .joined(separator: ", ")
        return """
        Verified QA workspace identity:
          write-target workspace: \(workspaceName) (\(workspaceID))
          user: \(userName) [id \(userID)\(userStatus.map { ", \($0)" } ?? "")]
          accessible workspaces: \(workspaces)
        """
    }
}

public struct QAWorkspaceSummary: Sendable, Equatable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

/// Why the guard refused to run. Every case is a hard abort: no test or sweep
/// write is attempted after a guard failure.
public enum QAGuardError: Error, Sendable, CustomStringConvertible {
    /// No `WEALTHBOX_QA_ACCESS_TOKEN` in the environment.
    case missingAccessToken
    /// No `WEALTHBOX_QA_WORKSPACE_ID` in the environment. The expected
    /// workspace is never defaulted or hardcoded — a run must state, from
    /// outside the repo, which workspace it believes it is talking to.
    case missingExpectedWorkspaceID
    /// `/v1/me` could not be fetched or decoded.
    case identityFetchFailed(message: String)
    /// `/v1/me` returned no `current_user` — without it the write-target
    /// workspace (`current_user.account`) cannot be verified.
    case missingCurrentUser
    /// The documented write target (`current_user.account` — "All API calls
    /// with this token will be performed in this user's account (workspace)")
    /// is not the expected QA workspace.
    case writeTargetMismatch(actualAccountID: Int, expectedWorkspaceID: Int, accounts: [QAWorkspaceSummary])
    /// `/v1/me` returned no `accounts` array, so the expected workspace's
    /// name cannot be cross-checked and sole membership cannot be proven.
    case unverifiableWorkspaceMembership
    /// The expected workspace id is not among the credential's accessible
    /// workspaces — most likely a mis-set `WEALTHBOX_QA_WORKSPACE_ID`.
    case expectedWorkspaceNotAccessible(expectedWorkspaceID: Int, accounts: [QAWorkspaceSummary])
    /// The workspace with the expected id does not carry the expected name.
    /// This catches a transposed or stale id before any write is attempted.
    case workspaceNameMismatch(expectedName: String, actualName: String, workspaceID: Int)
    /// The credential can reach workspaces beyond QA. A user-scoped key
    /// that also reaches a production CRM is the dangerous shape; strict
    /// mode (the default) refuses it even when the current write target is
    /// QA, because nothing proves the target cannot
    /// move. Set `WEALTHBOX_QA_ALLOW_MULTI_WORKSPACE_USER=1` only as a
    /// deliberate, documented decision.
    case multiWorkspaceCredential(accounts: [QAWorkspaceSummary])

    public var description: String {
        switch self {
        case .missingAccessToken:
            return "QA guard: no \(QARunEnvironment.Variable.accessToken) is set. Run through bin/wb-qa-run so the key is read from the Keychain at call time."
        case .missingExpectedWorkspaceID:
            return "QA guard: no \(QARunEnvironment.Variable.workspaceID) is set. The expected QA workspace id is required and is never defaulted in code."
        case .identityFetchFailed(let message):
            return "QA guard: /v1/me could not be verified: \(message)"
        case .missingCurrentUser:
            return "QA guard: /v1/me returned no current_user, so the write-target workspace cannot be verified. Aborting."
        case .writeTargetMismatch(let actual, let expected, let accounts):
            return "QA guard: this token's API calls target workspace \(actual), not the expected QA workspace \(expected). Accessible workspaces: \(Self.describe(accounts)). Aborting before any write."
        case .unverifiableWorkspaceMembership:
            return "QA guard: /v1/me returned no accounts array, so workspace membership cannot be verified. Aborting."
        case .expectedWorkspaceNotAccessible(let expected, let accounts):
            return "QA guard: expected workspace \(expected) is not among this credential's accessible workspaces: \(Self.describe(accounts)). Check \(QARunEnvironment.Variable.workspaceID)."
        case .workspaceNameMismatch(let expectedName, let actualName, let id):
            return "QA guard: workspace \(id) is named \"\(actualName)\", expected \"\(expectedName)\". Check \(QARunEnvironment.Variable.workspaceID) / \(QARunEnvironment.Variable.workspaceName)."
        case .multiWorkspaceCredential(let accounts):
            return "QA guard: this credential can access \(accounts.count) workspaces (\(Self.describe(accounts))). A QA run requires a credential whose only workspace is QA; use a dedicated QA-only login, or set \(QARunEnvironment.Variable.allowMultiWorkspaceUser)=1 to accept the risk deliberately."
        }
    }

    private static func describe(_ accounts: [QAWorkspaceSummary]) -> String {
        guard !accounts.isEmpty else { return "none" }
        return accounts.map { "\($0.name) (\($0.id))" }.joined(separator: ", ")
    }
}

/// The workspace-identity interlock for every QA-workspace run.
///
/// Wealthbox exposes one shared API base for all workspaces, and `/v1/me`
/// describes a *login profile*: the top-level `name` is the user's name, and
/// `accounts` lists every workspace the login can access — a user-scoped key
/// can list a production CRM alongside the QA workspace. The documented write
/// target is `current_user.account` — "All API calls with this token will be
/// performed in this user's account (workspace)".
///
/// `evaluate` therefore requires, in order, failing closed at each step:
///  1. an expected workspace id supplied from outside the repo;
///  2. `current_user.account` equal to that id (the write target really is
///     QA);
///  3. the expected id present in `accounts` *and* carrying the expected name
///     (default "QA"), so a transposed id cannot slip through;
///  4. strict mode (default): `accounts` contains *only* the QA
///     workspace, proving the credential cannot reach the real CRM at all.
///
/// Tier 2 (package integration tests) and tier 3 (app UI smoke tests) both
/// call this same guard, and the sweep tool runs behind it as well.
public enum QAWorkspaceGuard {
    /// Pure decision logic over an already-fetched `/v1/me` payload.
    public static func evaluate(
        workspace: Workspace,
        expectedWorkspaceID: Int?,
        expectedWorkspaceName: String = QARunEnvironment.defaultWorkspaceName,
        allowMultiWorkspaceUser: Bool = false
    ) -> Result<QAWorkspaceIdentity, QAGuardError> {
        guard let expectedWorkspaceID else {
            return .failure(.missingExpectedWorkspaceID)
        }

        guard let currentUser = workspace.currentUser else {
            return .failure(.missingCurrentUser)
        }

        guard let accounts = workspace.accounts, !accounts.isEmpty else {
            return .failure(.unverifiableWorkspaceMembership)
        }
        let summaries = accounts.map { QAWorkspaceSummary(id: $0.id, name: $0.name) }

        guard currentUser.account == expectedWorkspaceID else {
            return .failure(.writeTargetMismatch(
                actualAccountID: currentUser.account,
                expectedWorkspaceID: expectedWorkspaceID,
                accounts: summaries
            ))
        }

        guard let expectedAccount = summaries.first(where: { $0.id == expectedWorkspaceID }) else {
            return .failure(.expectedWorkspaceNotAccessible(
                expectedWorkspaceID: expectedWorkspaceID,
                accounts: summaries
            ))
        }

        guard expectedAccount.name.caseInsensitiveCompare(expectedWorkspaceName) == .orderedSame else {
            return .failure(.workspaceNameMismatch(
                expectedName: expectedWorkspaceName,
                actualName: expectedAccount.name,
                workspaceID: expectedWorkspaceID
            ))
        }

        if !allowMultiWorkspaceUser && summaries.count > 1 {
            return .failure(.multiWorkspaceCredential(accounts: summaries))
        }

        return .success(QAWorkspaceIdentity(
            workspaceID: expectedAccount.id,
            workspaceName: expectedAccount.name,
            userID: currentUser.id,
            userName: currentUser.name,
            userEmail: currentUser.email,
            userStatus: currentUser.status,
            accessibleWorkspaces: summaries
        ))
    }

    /// Fetches `/v1/me` with the environment's client and evaluates it.
    /// Throws `QAGuardError` on any refusal; callers must not attempt
    /// writes after a throw.
    public static func verify(environment: QARunEnvironment) throws -> QAWorkspaceIdentity {
        guard environment.isConfigured else {
            throw QAGuardError.missingAccessToken
        }
        return try verify(client: environment.makeClient(), environment: environment)
    }

    /// `verify(environment:)` with an injectable client, so callers holding a
    /// client (and tests stubbing one) reuse it for the identity fetch.
    public static func verify(
        client: WealthboxApiClient,
        environment: QARunEnvironment
    ) throws -> QAWorkspaceIdentity {
        guard environment.isConfigured else {
            throw QAGuardError.missingAccessToken
        }
        guard environment.expectedWorkspaceID != nil else {
            throw QAGuardError.missingExpectedWorkspaceID
        }

        let workspace: Workspace
        do {
            workspace = try client.getCurrentUser()
        } catch {
            throw QAGuardError.identityFetchFailed(message: String(describing: error))
        }

        switch evaluate(
            workspace: workspace,
            expectedWorkspaceID: environment.expectedWorkspaceID,
            expectedWorkspaceName: environment.expectedWorkspaceName,
            allowMultiWorkspaceUser: environment.allowMultiWorkspaceUser
        ) {
        case .success(let identity):
            return identity
        case .failure(let error):
            throw error
        }
    }
}
