import Foundation
import Testing
@testable import Wealthbox

struct ContactFilterTests {
    @Test
    func contactsFilterByTypeCaseInsensitively() throws {
        let contacts = try WBContacts.decode(
            """
            {
              "contacts": [
                { "id": 1, "name": "Kevin Anderson", "type": "Person", "contact_type": "Client" },
                { "id": 2, "name": "Anderson Household", "type": "Household", "contact_type": "Client" },
                { "id": 3, "name": "Acme Co.", "type": "Organization", "contact_type": "Vendor" }
              ]
            }
            """
        )

        let filtered = try contacts.filtered(type: "person")

        #expect(filtered.contacts.map(\.id) == [1])
    }

    @Test
    func contactsFilterByContactTypeCaseInsensitively() throws {
        let contacts = try WBContacts.decode(
            """
            {
              "contacts": [
                { "id": 1, "name": "Kevin Anderson", "type": "Person", "contact_type": "Client" },
                { "id": 2, "name": "Past Household", "type": "Household", "contact_type": "Past Client" },
                { "id": 3, "name": "Acme Co.", "type": "Organization", "contact_type": "Vendor" }
              ]
            }
            """
        )

        let filtered = try contacts.filtered(contactType: "past client")

        #expect(filtered.contacts.map(\.id) == [2])
    }

    @Test
    func contactsFilterByTypeAndContactType() throws {
        let contacts = try WBContacts.decode(
            """
            {
              "contacts": [
                { "id": 1, "name": "Kevin Anderson", "type": "Person", "contact_type": "Client" },
                { "id": 2, "name": "Anderson Household", "type": "Household", "contact_type": "Client" },
                { "id": 3, "name": "Acme Co.", "type": "Organization", "contact_type": "Vendor" }
              ]
            }
            """
        )

        let filtered = try contacts.filtered(type: "organization", contactType: "vendor")

        #expect(filtered.contacts.map(\.id) == [3])
    }

    @Test
    func contactsFilterRejectsUnsupportedType() throws {
        let contacts = try WBContacts.decode("{ \"contacts\": [] }")

        do {
            _ = try contacts.filtered(type: "Company")
            Issue.record("Expected unsupported contact type to throw.")
        } catch let error as WealthboxError {
            #expect(error == .validationError(message: "Invalid contact type 'Company'. Use one of: Person, Household, Organization, Trust."))
        }
    }

    @Test
    func contactsFilterRejectsUnsupportedContactType() throws {
        let contacts = try WBContacts.decode("{ \"contacts\": [] }")

        do {
            _ = try contacts.filtered(contactType: "Lead")
            Issue.record("Expected unsupported contact_type to throw.")
        } catch let error as WealthboxError {
            #expect(error == .validationError(message: "Invalid contact_type 'Lead'. Use one of: Client, Past Client, Prospect, Vendor, Organization."))
        }
    }
}
