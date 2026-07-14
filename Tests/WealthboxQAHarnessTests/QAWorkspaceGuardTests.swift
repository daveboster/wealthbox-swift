import Foundation
import Testing
import Wealthbox
@testable import WealthboxQA

/// Guard-decision tests over the documented `/v1/me` shape: the top-level
/// fields describe the *login profile* (the user, not a workspace),
/// `current_user.account` is the documented write target, and `accounts`
/// lists every workspace the login can access.
///
/// Serialized because the two `verify(client:environment:)` tests share the
/// URLProtocol stub's static request handler; running them in parallel lets
/// one test's handler clobber the other's before its URLSession callback
/// fires (matching the `WealthboxApiClientTests` precedent).
@Suite(.serialized)
struct QAWorkspaceGuardTests {
    // A user-scoped credential that lists a production CRM and other
    // workspaces alongside QA, with placeholder ids/names standing in for
    // real tenant values.
    private let qaWorkspaceID = 125_001
    private let realCrmID = 71_001
    private let thirdWorkspaceID = 72_001

    private func workspaceJSON(
        currentAccountID: Int,
        accounts: [(id: Int, name: String)],
        status: String? = "active"
    ) -> String {
        let accountsJSON = accounts
            .map { "{\"id\": \($0.id), \"name\": \"\($0.name)\", \"created_at\": \"2026-01-05 9:00 AM -0400\"}" }
            .joined(separator: ", ")
        let statusJSON = status.map { ", \"status\": \"\($0)\"" } ?? ""
        return """
        {
            "id": 9,
            "name": "Jordan Advisor",
            "first_name": "Jordan",
            "last_name": "Advisor",
            "email": "jordan@example.com",
            "plan": "premier",
            "created_at": "2026-01-05 9:00 AM -0400",
            "updated_at": "2026-07-01 9:00 AM -0400",
            "current_user": {
                "id": 9,
                "email": "jordan@example.com",
                "name": "Jordan Advisor",
                "account": \(currentAccountID)\(statusJSON)
            },
            "accounts": [\(accountsJSON)]
        }
        """
    }

    private func workspace(
        currentAccountID: Int,
        accounts: [(id: Int, name: String)],
        status: String? = "active"
    ) throws -> Workspace {
        try Workspace.decode(workspaceJSON(
            currentAccountID: currentAccountID,
            accounts: accounts,
            status: status
        ))
    }

    @Test
    func qaOnlyCredentialPassesAndReportsIdentity() throws {
        let me = try workspace(currentAccountID: qaWorkspaceID, accounts: [(qaWorkspaceID, "QA")])

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: qaWorkspaceID)

        let identity = try result.get()
        #expect(identity.workspaceID == qaWorkspaceID)
        #expect(identity.workspaceName == "QA")
        #expect(identity.userName == "Jordan Advisor")
        #expect(identity.userEmail == "jordan@example.com")
        #expect(identity.userStatus == "active")
        #expect(identity.accessibleWorkspaces == [QAWorkspaceSummary(id: qaWorkspaceID, name: "QA")])
    }

    @Test
    func workspaceNameComparisonIsCaseInsensitive() throws {
        let me = try workspace(currentAccountID: qaWorkspaceID, accounts: [(qaWorkspaceID, "QA")])

        let result = QAWorkspaceGuard.evaluate(
            workspace: me,
            expectedWorkspaceID: qaWorkspaceID,
            expectedWorkspaceName: "qa"
        )

        #expect(throws: Never.self) { try result.get() }
    }

    @Test
    func missingExpectedWorkspaceIDFailsClosed() throws {
        let me = try workspace(currentAccountID: qaWorkspaceID, accounts: [(qaWorkspaceID, "QA")])

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: nil)

        guard case .failure(.missingExpectedWorkspaceID) = result else {
            Issue.record("Expected .missingExpectedWorkspaceID, got \(result)")
            return
        }
    }

    @Test
    func missingCurrentUserFailsClosed() throws {
        let me = try Workspace.decode("""
        {
            "id": 9,
            "name": "Jordan Advisor",
            "first_name": "Jordan",
            "last_name": "Advisor",
            "email": "jordan@example.com",
            "plan": "premier",
            "created_at": "2026-01-05 9:00 AM -0400",
            "updated_at": "2026-07-01 9:00 AM -0400",
            "accounts": [{"id": \(qaWorkspaceID), "name": "QA", "created_at": "2026-01-05 9:00 AM -0400"}]
        }
        """)

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: qaWorkspaceID)

        guard case .failure(.missingCurrentUser) = result else {
            Issue.record("Expected .missingCurrentUser, got \(result)")
            return
        }
    }

    @Test
    func missingAccountsArrayFailsClosed() throws {
        let me = try Workspace.decode("""
        {
            "id": 9,
            "name": "Jordan Advisor",
            "first_name": "Jordan",
            "last_name": "Advisor",
            "email": "jordan@example.com",
            "plan": "premier",
            "created_at": "2026-01-05 9:00 AM -0400",
            "updated_at": "2026-07-01 9:00 AM -0400",
            "current_user": {
                "id": 9,
                "email": "jordan@example.com",
                "name": "Jordan Advisor",
                "account": \(qaWorkspaceID)
            }
        }
        """)

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: qaWorkspaceID)

        guard case .failure(.unverifiableWorkspaceMembership) = result else {
            Issue.record("Expected .unverifiableWorkspaceMembership, got \(result)")
            return
        }
    }

    @Test
    func writeTargetPointingAtAnotherWorkspaceAborts() throws {
        // The dangerous shape: the credential's documented write target is
        // the real CRM even though QA is accessible.
        let me = try workspace(
            currentAccountID: realCrmID,
            accounts: [(realCrmID, "Real CRM"), (qaWorkspaceID, "QA"), (thirdWorkspaceID, "Third Workspace")]
        )

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: qaWorkspaceID)

        guard case .failure(.writeTargetMismatch(let actual, let expected, let accounts)) = result else {
            Issue.record("Expected .writeTargetMismatch, got \(result)")
            return
        }
        #expect(actual == realCrmID)
        #expect(expected == qaWorkspaceID)
        #expect(accounts.count == 3)
    }

    @Test
    func writeTargetMismatchAbortsEvenWhenMultiWorkspaceIsAllowed() throws {
        let me = try workspace(
            currentAccountID: realCrmID,
            accounts: [(realCrmID, "Real CRM"), (qaWorkspaceID, "QA")]
        )

        let result = QAWorkspaceGuard.evaluate(
            workspace: me,
            expectedWorkspaceID: qaWorkspaceID,
            allowMultiWorkspaceUser: true
        )

        guard case .failure(.writeTargetMismatch) = result else {
            Issue.record("Expected .writeTargetMismatch, got \(result)")
            return
        }
    }

    @Test
    func multiWorkspaceCredentialAbortsByDefaultEvenWhenTargetingQA() throws {
        // The dangerous shape: three accessible workspaces. Even with the
        // write target on QA, strict mode refuses — nothing proves the
        // target cannot move to a production CRM.
        let me = try workspace(
            currentAccountID: qaWorkspaceID,
            accounts: [(realCrmID, "Real CRM"), (qaWorkspaceID, "QA"), (thirdWorkspaceID, "Third Workspace")]
        )

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: qaWorkspaceID)

        guard case .failure(.multiWorkspaceCredential(let accounts)) = result else {
            Issue.record("Expected .multiWorkspaceCredential, got \(result)")
            return
        }
        #expect(accounts.count == 3)
    }

    @Test
    func multiWorkspaceCredentialPassesOnlyWithExplicitOverride() throws {
        let me = try workspace(
            currentAccountID: qaWorkspaceID,
            accounts: [(realCrmID, "Real CRM"), (qaWorkspaceID, "QA")]
        )

        let result = QAWorkspaceGuard.evaluate(
            workspace: me,
            expectedWorkspaceID: qaWorkspaceID,
            allowMultiWorkspaceUser: true
        )

        let identity = try result.get()
        #expect(identity.workspaceID == qaWorkspaceID)
        #expect(identity.accessibleWorkspaces.count == 2)
    }

    @Test
    func expectedWorkspaceMissingFromAccountsAborts() throws {
        // current_user.account matches the expected id but the accounts array
        // does not list it — inconsistent payloads fail closed.
        let me = try workspace(currentAccountID: qaWorkspaceID, accounts: [(realCrmID, "Real CRM")])

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: qaWorkspaceID)

        guard case .failure(.expectedWorkspaceNotAccessible(let expected, _)) = result else {
            Issue.record("Expected .expectedWorkspaceNotAccessible, got \(result)")
            return
        }
        #expect(expected == qaWorkspaceID)
    }

    @Test
    func mismatchedWorkspaceNameAborts() throws {
        // A transposed/mis-set expected id that lands on a differently-named
        // workspace must not pass on id equality alone.
        let me = try workspace(currentAccountID: realCrmID, accounts: [(realCrmID, "Real CRM")])

        let result = QAWorkspaceGuard.evaluate(workspace: me, expectedWorkspaceID: realCrmID)

        guard case .failure(.workspaceNameMismatch(let expectedName, let actualName, let id)) = result else {
            Issue.record("Expected .workspaceNameMismatch, got \(result)")
            return
        }
        #expect(expectedName == "QA")
        #expect(actualName == "Real CRM")
        #expect(id == realCrmID)
    }

    @Test
    func verifyWithoutTokenThrowsBeforeAnyNetworkUse() {
        let environment = QARunEnvironment(accessToken: nil, expectedWorkspaceID: qaWorkspaceID)

        #expect(throws: QAGuardError.self) {
            try QAWorkspaceGuard.verify(environment: environment)
        }
    }

    @Test
    func verifyFetchesIdentityThroughInjectedClient() throws {
        let body = workspaceJSON(currentAccountID: qaWorkspaceID, accounts: [(qaWorkspaceID, "QA")])
        let session = URLSession.stubbed { request in
            #expect(request.url?.absoluteString == "https://example.com/v1/me")
            #expect(request.value(forHTTPHeaderField: "ACCESS_TOKEN") == "qa-token")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(body.utf8))
        }
        let client = WealthboxApiClient(
            baseURL: "https://example.com",
            session: session,
            accessToken: "qa-token"
        )
        let environment = QARunEnvironment(
            accessToken: "qa-token",
            expectedWorkspaceID: qaWorkspaceID
        )

        let identity = try QAWorkspaceGuard.verify(client: client, environment: environment)

        #expect(identity.workspaceID == qaWorkspaceID)
        #expect(identity.summary.contains("QA (\(qaWorkspaceID))"))
    }

    @Test
    func verifyWrapsFetchFailuresAsGuardErrors() {
        let session = URLSession.stubbed { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("bad token".utf8))
        }
        let client = WealthboxApiClient(
            baseURL: "https://example.com",
            session: session,
            accessToken: "bad"
        )
        let environment = QARunEnvironment(accessToken: "bad", expectedWorkspaceID: qaWorkspaceID)

        do {
            _ = try QAWorkspaceGuard.verify(client: client, environment: environment)
            Issue.record("Expected verify to throw.")
        } catch let error as QAGuardError {
            guard case .identityFetchFailed = error else {
                Issue.record("Expected .identityFetchFailed, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected QAGuardError, got \(error)")
        }
    }
}
