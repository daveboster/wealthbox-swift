import Foundation
import Testing
@testable import Wealthbox

struct EventCategoryTests {
    @Test
    func eventCategoriesDecodeFromEventCategoriesKey() throws {
        let categories = try WBEventCategories.decode(
            """
            {
              "event_categories": [
                {
                  "id": 1,
                  "name": "Client Meeting"
                },
                {
                  "id": 2,
                  "name": "Review"
                }
              ]
            }
            """
        )

        #expect(categories.eventCategories.map { $0.id } == [1, 2])
        #expect(categories.eventCategories.map { $0.name } == ["Client Meeting", "Review"])
    }

    @Test
    func eventCategoriesDecodeFromGenericTagsKey() throws {
        let categories = try WBEventCategories.decode(
            """
            {
              "tags": [
                {
                  "id": 9,
                  "name": "Planning"
                }
              ]
            }
            """
        )

        #expect(categories.eventCategories.first?.id == 9)
        #expect(categories.eventCategories.first?.name == "Planning")
    }

    @Test
    func eventsEnrichedWithCategoriesPreserveEventCategoryIdAndAppendCategoryObject() throws {
        let events = try WBEvents.decode(
            """
            {
              "events": [
                {
                  "id": 1,
                  "creator": 1,
                  "created_at": "2026-06-07 10:00 AM +0000",
                  "updated_at": "2026-06-07 10:00 AM +0000",
                  "title": "Client Meeting",
                  "starts_at": "2026-06-07 12:00 PM +0000",
                  "ends_at": "2026-06-07 01:00 PM +0000",
                  "event_category": 2,
                  "linked_to": [],
                  "invitees": [],
                  "custom_fields": []
                },
                {
                  "id": 2,
                  "creator": 1,
                  "created_at": "2026-06-07 10:00 AM +0000",
                  "updated_at": "2026-06-07 10:00 AM +0000",
                  "title": "Uncategorized",
                  "starts_at": "2026-06-07 02:00 PM +0000",
                  "ends_at": "2026-06-07 03:00 PM +0000",
                  "event_category": 99,
                  "linked_to": [],
                  "invitees": [],
                  "custom_fields": []
                }
              ]
            }
            """
        )
        let categories = WBEventCategories([
            WBCategoryMember(id: 2, name: "Review")
        ])

        let enriched = events.enrichedWithCategories(categories)

        #expect(enriched.events[0].eventCategory == 2)
        #expect(enriched.events[0].category?.id == 2)
        #expect(enriched.events[0].category?.name == "Review")
        #expect(enriched.events[1].eventCategory == 99)
        #expect(enriched.events[1].category == nil)
    }

    @Test
    func enrichedEventEncodesEventCategoryAndCategoryObject() throws {
        let event = WBEvent.sample().withCategory(WBCategoryMember(id: 2, name: "Review"))
        let encoded = try String(decoding: JSONEncoder().encode(event), as: UTF8.self)

        #expect(encoded.contains("\"event_category\":2"))
        #expect(encoded.contains("\"category\":"))
        #expect(encoded.contains("\"name\":\"Review\""))
    }
}
