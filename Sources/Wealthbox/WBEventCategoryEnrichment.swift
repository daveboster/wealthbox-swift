import Foundation

public extension WBEvent {
    func withCategory(_ category: WBCategoryMember?) -> WBEvent {
        WBEvent(
            json: json,
            id: id,
            creator: creator,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            startsAt: startsAt,
            endsAt: endsAt,
            repeats: repeats,
            eventCategory: eventCategory,
            allDay: allDay,
            location: location,
            description: description,
            state: state,
            visibleTo: visibleTo,
            emailInvitees: emailInvitees,
            linkedTo: linkedTo,
            invitees: invitees,
            customFields: customFields,
            category: category
        )
    }
}

public extension WBEvents {
    func enrichedWithCategories(_ categories: WBEventCategories) -> WBEvents {
        let categoriesById = Dictionary(
            uniqueKeysWithValues: categories.eventCategories.map { ($0.id, $0) }
        )

        return WBEvents(events.map { event in
            guard let eventCategory = event.eventCategory else {
                return event.withCategory(nil)
            }
            return event.withCategory(categoriesById[eventCategory])
        })
    }
}
