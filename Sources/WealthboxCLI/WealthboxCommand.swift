import ArgumentParser
import Foundation
import Wealthbox

@main
struct WealthboxCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wealthbox",
        abstract: "Call read-only Wealthbox API commands from the terminal.",
        subcommands: [
            Me.self,
            Contacts.self,
            Contact.self,
            Events.self,
            Event.self,
            EventCategories.self
        ]
    )
}

struct ClientOptions: ParsableArguments {
    @Option(help: "Wealthbox access token. Overrides WEALTHBOX_ACCESS_TOKEN.")
    var token: String?

    @Option(help: "Wealthbox API base URL. Overrides WEALTHBOX_BASE_URL.")
    var baseURL: String?

    @Flag(help: "Pretty-print JSON output.")
    var pretty = false

    func makeClient() throws -> WealthboxApiClient {
        let environment = ProcessInfo.processInfo.environment
        let resolvedToken = token ?? environment["WEALTHBOX_ACCESS_TOKEN"]
        guard let resolvedToken, !resolvedToken.isEmpty else {
            throw ValidationError("Missing access token. Pass --token or set WEALTHBOX_ACCESS_TOKEN.")
        }

        let resolvedBaseURL = baseURL ?? environment["WEALTHBOX_BASE_URL"] ?? WealthboxApiClient.defaultBaseUrl
        return WealthboxApiClient(baseURL: resolvedBaseURL, accessToken: resolvedToken)
    }

    func printJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(value)
        guard let output = String(data: data, encoding: .utf8) else {
            throw ValidationError("Unable to encode response as UTF-8 JSON.")
        }
        print(output)
    }
}

struct Me: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "me",
        abstract: "Fetch the current Wealthbox workspace and user."
    )

    @OptionGroup var options: ClientOptions

    func run() throws {
        let workspace = try options.makeClient().getCurrentUser()
        try options.printJSON(workspace)
    }
}

struct Contacts: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts",
        abstract: "Fetch Wealthbox contacts."
    )

    @OptionGroup var options: ClientOptions

    func run() throws {
        let contacts: WBContacts = try options.makeClient().get(.contacts)
        try options.printJSON(contacts)
    }
}

struct Contact: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contact",
        abstract: "Fetch a Wealthbox contact by identifier."
    )

    @Argument(help: "The Wealthbox contact identifier.")
    var id: Int

    @OptionGroup var options: ClientOptions

    func run() throws {
        let contact: WBContact = try options.makeClient().get(.contacts, id: id)
        try options.printJSON(contact)
    }
}

struct Events: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "events",
        abstract: "Fetch Wealthbox events."
    )

    @Option(help: "Filter events to a Sunday-start week offset. Use 0 for this week, -1 for last week, and 1 for next week.")
    var week: Int?

    @OptionGroup var options: ClientOptions

    func run() throws {
        var events = try options.makeClient().getEvents()
        if let week {
            events = try events.filteredByWeek(offset: week)
        }
        try options.printJSON(events)
    }
}

struct Event: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "event",
        abstract: "Fetch a Wealthbox event by identifier."
    )

    @Argument(help: "The Wealthbox event identifier.")
    var id: Int

    @OptionGroup var options: ClientOptions

    func run() throws {
        let event = try options.makeClient().getEvent(id: id)
        try options.printJSON(event)
    }
}

struct EventCategories: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "event-categories",
        abstract: "Fetch Wealthbox event category id/name values."
    )

    @OptionGroup var options: ClientOptions

    func run() throws {
        let categories = try options.makeClient().getEventCategories()
        try options.printJSON(categories)
    }
}
