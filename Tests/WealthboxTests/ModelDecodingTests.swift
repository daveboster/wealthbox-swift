import Testing
@testable import Wealthbox

struct ModelDecodingTests {
    @Test
    func workspaceSampleDecodesExpectedCurrentUser() throws {
        let workspace = Workspace.sample()

        #expect(workspace.id == 1)
        #expect(workspace.currentUser?.email == "bill@example.com")
        #expect(workspace.accounts?.first?.name == "ABC Financial")
        #expect(workspace.json?.contains("\"first_name\"") == true)
    }

    @Test
    func contactSamplesDecodeExpectedNestedCollections() throws {
        let contact = WBContact.sample()
        let contacts = WBContacts.sample()

        #expect(contact.id == 1)
        #expect(contact.firstName == "Kevin")
        #expect(contact.household?.members?.first?.firstName == "Kevin")
        #expect(contact.emailAddresses?.first?.address == "kevin.anderson@example.com")
        #expect(contacts.contacts.count == 1)
        #expect(contacts.page == 1)
        #expect(contacts.perPage == 25)
    }

    @Test
    func eventSamplesDecodeExpectedLinkedContacts() throws {
        let event = WBEvent.sample()
        let events = WBEvents.sample()

        #expect(event.id == 1)
        #expect(event.linkedTo.first?.name == "Kevin Anderson")
        #expect(event.customFields.first?.documentType == "Contact")
        #expect(events.events.count == 1)
    }

    @Test
    func noteSampleDecodesExpectedContentAndLinks() throws {
        let note = WBNote.sample()

        #expect(note.id == 1)
        #expect(note.content == "Spoke with Kevin about the upcoming review meeting.")
        #expect(note.visibleTo == "Everyone")
        #expect(note.linkedTo?.first?.type == "Contact")
        #expect(note.linkedTo?.first?.name == "Kevin Anderson")
        #expect(note.tags?.first?.name == "Meeting")
        #expect(note.json?.contains("\"content\"") == true)
    }

    @Test
    func wealthboxItemTypeClassifiesKnownContacts() throws {
        let contact = WBContact.sample()

        #expect(contact.wealthboxId == 1)
        #expect(contact.wealthboxName == contact.name)
        if case .contact = contact.wealthboxType {
            #expect(Bool(true))
        } else {
            Issue.record("Expected sample contact to classify as a contact.")
        }
    }
}
