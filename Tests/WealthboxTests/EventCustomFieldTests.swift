import Foundation
import Testing
@testable import Wealthbox

struct EventCustomFieldTests {
    @Test
    func customFieldDefinitionsDecodeOptions() throws {
        let definitions = try WBCustomFieldDefinitions.decode(
            """
            {
              "custom_fields": [
                {
                  "id": 1,
                  "name": "Meeting Type",
                  "document_type": "Event",
                  "field_type": "single_select",
                  "options": [
                    {
                      "id": 10,
                      "label": "Annual Review"
                    }
                  ]
                }
              ]
            }
            """
        )

        let field = try #require(definitions.customFields.first)
        #expect(field.id == 1)
        #expect(field.name == "Meeting Type")
        #expect(field.documentType == "Event")
        #expect(field.fieldType == "single_select")
        #expect(field.options?.first?.id == 10)
        #expect(field.options?.first?.label == "Annual Review")
    }
}
