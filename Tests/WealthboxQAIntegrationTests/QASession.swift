import Foundation
import Wealthbox
import WealthboxQA

/// Everything a tier-2 test may rely on after the guard has passed.
struct QAContext: Sendable {
    let client: WealthboxApiClient
    let identity: QAWorkspaceIdentity
    /// The Wealthbox contact id of the seeded household tests link artifacts
    /// to (households are contacts).
    let seedContactID: Int
    let seedContactName: String
}

enum QABootstrapError: Error, Sendable, CustomStringConvertible {
    case notConfigured
    case guardRefused(String)
    case seedHouseholdMissing(String)

    var description: String {
        switch self {
        case .notConfigured:
            return "QA run not configured: \(QARunEnvironment.Variable.accessToken) is not set. Run via bin/wb-qa-run."
        case .guardRefused(let message):
            return message
        case .seedHouseholdMissing(let message):
            return message
        }
    }
}

/// One shared, memoized bootstrap per test-process run: the `/v1/me` identity
/// guard runs exactly once, and every test in the suite draws its verified
/// context (or the original refusal) from that single result. A guard refusal
/// therefore fails every test loudly without a single write being attempted.
enum QASession {
    static let environment = QARunEnvironment.fromProcessEnvironment()

    /// One run id per suite invocation; every artifact this run creates
    /// carries it (note tags + marker lines), which is what the sweep keys on.
    static let runID = QARunID.generate()

    private static let bootstrap: Result<QAContext, QABootstrapError> = {
        guard environment.isConfigured else {
            return .failure(.notConfigured)
        }

        let client = environment.makeClient()

        let identity: QAWorkspaceIdentity
        do {
            identity = try QAWorkspaceGuard.verify(client: client, environment: environment)
        } catch {
            return .failure(.guardRefused(String(describing: error)))
        }

        do {
            let seed = try resolveSeedHousehold(client: client, name: environment.seedHouseholdName)
            return .success(QAContext(
                client: client,
                identity: identity,
                seedContactID: seed.id,
                seedContactName: seed.name
            ))
        } catch let error as QABootstrapError {
            return .failure(error)
        } catch {
            return .failure(.seedHouseholdMissing(
                "Could not look up the seeded household \"\(environment.seedHouseholdName)\": \(error)"
            ))
        }
    }()

    static func requireContext() throws -> QAContext {
        try bootstrap.get()
    }

    /// A brief pause between write calls, keeping suite traffic near
    /// Wealthbox's documented sustained rate (one request/second averaged
    /// over five minutes, short bursts permitted).
    static func pace() {
        Thread.sleep(forTimeInterval: 0.6)
    }

    /// A Wealthbox-format due date (`2026-07-21 09:00 AM -0400` style) a week
    /// out, for test tasks — `due_date` is required on task create.
    static func testDueDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd h:mm a Z"
        return formatter.string(from: Date().addingTimeInterval(7 * 24 * 60 * 60))
    }

    private static func resolveSeedHousehold(
        client: WealthboxApiClient,
        name: String
    ) throws -> (id: Int, name: String) {
        let results = try client.searchContacts(name: name, type: "household")
        let matches = results.contacts.compactMap { contact -> (id: Int, name: String)? in
            guard let id = contact.id, let contactName = contact.name else { return nil }
            guard contactName.range(of: name, options: .caseInsensitive) != nil else { return nil }
            return (id, contactName)
        }

        guard let seed = matches.first, matches.count == 1 else {
            let found = matches.isEmpty
                ? "none"
                : matches.map { "\($0.name) (\($0.id))" }.joined(separator: ", ")
            throw QABootstrapError.seedHouseholdMissing(
                "Expected exactly one seeded household matching \"\(name)\" in the QA workspace, found: \(found). Seed the four sample households by hand first — see docs/QA_WORKSPACE_TESTING.md."
            )
        }
        return seed
    }
}

/// Prints an observation from a live run in a greppable form. Findings are
/// facts worth folding back into the tier-1 mocks or the epic run record —
/// they ride the test log, while assertions handle pass/fail.
enum QAFindings {
    static func record(_ message: String) {
        print("[qa-finding] \(message)")
    }
}
