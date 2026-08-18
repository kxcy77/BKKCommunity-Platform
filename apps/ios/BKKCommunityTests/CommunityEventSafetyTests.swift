import XCTest
@testable import BKKCommunity

final class CommunityEventSafetyTests: XCTestCase {
    func testDemonstrationEventWithServerIDIsBlocked() {
        let event = CommunityEvent(
            id: 42,
            title: "BKK App Demonstration Event - Not a Real Event",
            description: "TEST CONTENT ONLY",
            startAt: "2026-08-15T08:00:00Z",
            endAt: "2026-08-15T09:00:00Z",
            location: "Demonstration only - do not travel",
            directions: nil,
            category: "Demonstration",
            colourHex: "#BF7600",
            isAttending: false
        )

        XCTAssertTrue(event.isDemonstration)
    }

    func testNormalCommunityEventRemainsActionable() {
        let event = CommunityEvent(
            id: 43,
            title: "Community lunch",
            description: "Meet neighbours for lunch.",
            startAt: "2026-08-16T10:00:00Z",
            endAt: "2026-08-16T12:00:00Z",
            location: "BKK Community Hall",
            directions: nil,
            category: "Social",
            colourHex: "#2E75B6",
            isAttending: false
        )

        XCTAssertFalse(event.isDemonstration)
    }
}
