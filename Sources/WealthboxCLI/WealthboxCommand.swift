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
            EventCategories.self,
            EventCustomFields.self,
            ContactCustomFields.self,
            EventUpdateCategory.self,
            EventUpdateStatus.self
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

    @Option(help: "Filter by Wealthbox contact object type. Choices: Person, Household, Organization, Trust.")
    var type: String?

    @Option(help: "Filter by Wealthbox contact_type. Choices: Client, Past Client, Prospect, Vendor, Organization.")
    var contactType: String?

    @OptionGroup var options: ClientOptions

    func run() throws {
        let contacts: WBContacts = try options.makeClient().get(.contacts)
        let filteredContacts = try contacts.filtered(type: type, contactType: contactType)
        try options.printJSON(filteredContacts)
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

    @Flag(help: "Fetch event categories first and append each matching category object under category.")
    var includeCategories = false

    @OptionGroup var options: ClientOptions

    func run() throws {
        var events = try options.makeClient().getEvents(includeCategories: includeCategories)
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

struct EventCustomFields: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "event-custom-fields",
        abstract: "Fetch Wealthbox custom field definitions for events."
    )

    @OptionGroup var options: ClientOptions

    func run() throws {
        let customFields = try options.makeClient().getEventCustomFields()
        try options.printJSON(customFields)
    }
}

struct ContactCustomFields: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contact-custom-fields",
        abstract: "Fetch Wealthbox custom field definitions for contacts."
    )

    @OptionGroup var options: ClientOptions

    func run() throws {
        let customFields = try options.makeClient().getContactCustomFields()
        try options.printJSON(customFields)
    }
}

struct EventUpdateCategory: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "event-update-category",
        abstract: "Update an event category after validating its current category."
    )

    @Argument(help: "The Wealthbox event identifier.")
    var eventId: Int

    @Option(help: "Expected current event category id.")
    var fromCategoryId: Int?

    @Option(help: "Expected current event category name.")
    var fromCategoryName: String?

    @Option(help: "New event category id.")
    var toCategoryId: Int?

    @Option(help: "New event category name.")
    var toCategoryName: String?

    @OptionGroup var options: ClientOptions

    func run() throws {
        try validateSelector(id: fromCategoryId, name: fromCategoryName, label: "from")
        try validateSelector(id: toCategoryId, name: toCategoryName, label: "to")

        let client = try options.makeClient()
        let fromId: Int
        let toId: Int

        if let fromCategoryId, let toCategoryId {
            fromId = fromCategoryId
            toId = toCategoryId
        } else {
            let categories = try client.getEventCategories()
            fromId = try fromCategoryId ?? resolveCategoryId(named: fromCategoryName, in: categories)
            toId = try toCategoryId ?? resolveCategoryId(named: toCategoryName, in: categories)
        }

        let event = try client.updateEventCategory(eventId: eventId, fromCategoryId: fromId, toCategoryId: toId)
        try options.printJSON(event)
    }

    private func validateSelector(id: Int?, name: String?, label: String) throws {
        switch (id, name?.isEmpty == false ? name : nil) {
        case (.some, nil), (nil, .some):
            return
        case (.none, .none):
            throw ValidationError("Pass exactly one --\(label)-category-id or --\(label)-category-name.")
        case (.some, .some):
            throw ValidationError("Pass only one --\(label)-category-id or --\(label)-category-name.")
        }
    }

    private func resolveCategoryId(named name: String?, in categories: WBEventCategories) throws -> Int {
        guard let name else {
            throw ValidationError("Missing category name.")
        }

        let matches = categories.eventCategories.filter {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
        if matches.count == 1, let match = matches.first {
            return match.id
        }
        if matches.isEmpty {
            throw ValidationError("No event category named '\(name)' was found. No update sent.")
        }
        throw ValidationError("Multiple event categories named '\(name)' were found. No update sent.")
    }
}

struct EventUpdateStatus: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "event-update-status",
        abstract: "Update an event status after validating its current status."
    )

    @Argument(help: "The Wealthbox event identifier.")
    var eventId: Int

    @Option(help: "Expected current event status. Choices: unconfirmed, confirmed, tentative, completed, cancelled.")
    var fromStatus: String

    @Option(help: "New event status. Choices: unconfirmed, confirmed, tentative, completed, cancelled.")
    var toStatus: String

    @OptionGroup var options: ClientOptions

    func run() throws {
        let event = try options.makeClient().updateEventState(
            eventId: eventId,
            fromState: fromStatus,
            toState: toStatus
        )
        try options.printJSON(event)
    }
}
