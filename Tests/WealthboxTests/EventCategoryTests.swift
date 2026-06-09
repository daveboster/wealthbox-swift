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
}
