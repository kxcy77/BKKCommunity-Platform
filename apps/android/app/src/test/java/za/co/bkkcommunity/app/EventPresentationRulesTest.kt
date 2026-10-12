package za.co.bkkcommunity.app

import java.time.LocalDate
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.assertEquals
import org.junit.Test
import za.co.bkkcommunity.app.model.CommunityEvent
import za.co.bkkcommunity.app.model.Discount
import za.co.bkkcommunity.app.model.LocalService
import za.co.bkkcommunity.app.ui.screens.eventMatchesPeriod
import za.co.bkkcommunity.app.ui.screens.greetingForHour

class EventPresentationRulesTest {
    private val today = LocalDate.of(2026, 8, 2)

    @Test fun greetingMatchesSouthAfricanTimeOfDay() {
        assertEquals("Good morning", greetingForHour(8))
        assertEquals("Good afternoon", greetingForHour(14))
        assertEquals("Good evening", greetingForHour(21))
    }

    @Test fun eventPeriodFiltersAreMutuallyUseful() {
        val todayEvent = event(1, "2026-08-02T08:00:00Z")
        val weekEvent = event(2, "2026-08-06T08:00:00Z")
        val laterEvent = event(3, "2026-08-15T08:00:00Z")

        assertTrue(eventMatchesPeriod(todayEvent, "Today", today))
        assertFalse(eventMatchesPeriod(weekEvent, "Today", today))
        assertTrue(eventMatchesPeriod(weekEvent, "This week", today))
        assertFalse(eventMatchesPeriod(laterEvent, "This week", today))
        assertTrue(eventMatchesPeriod(laterEvent, "Later", today))
        assertTrue(eventMatchesPeriod(todayEvent, "All", today))
    }

    @Test fun demonstrationEventsAreRecognisedEvenWithARealServerId() {
        val event = event(42, "2026-08-15T08:00:00Z").copy(
            title = "BKK App Demonstration Event - Not a Real Event",
            category = "Demonstration",
            location = "Demonstration only - do not travel"
        )

        assertTrue(event.isDemonstration)
        assertTrue(event(-1, "2026-08-15T08:00:00Z").isDemonstration)
        assertFalse(event(43, "2026-08-15T08:00:00Z").isDemonstration)
    }

    @Test fun demoDiscountAndServiceCannotLookLikeVerifiedLiveContent() {
        val discount = Discount(42, "Clicks", "10% off selected prescriptions",
            "Selected prescription items qualify for a pensioner discount.", "Aged 60+", "Ask in store",
            "Pharmacy", null, null)
        val service = LocalService(43, "clinic", "BKK Community Clinic", "12 Main Road, BKK",
            "011 555 0101", null, null)
        assertTrue(discount.isDemonstration)
        assertTrue(service.isDemonstration)
        assertFalse(discount.copy(details = "Approved terms supplied by the business").isDemonstration)
        assertFalse(service.copy(address = "Verified BKK clinic address").isDemonstration)
        assertTrue(discount.copy(storeName = "New business", isDemo = true).isDemonstration)
        assertTrue(service.copy(name = "New service", isDemo = true).isDemonstration)
    }

    private fun event(id: Long, start: String) = CommunityEvent(
        id = id,
        title = "Community event",
        description = "Description",
        startAt = start,
        endAt = start,
        location = "BKK Hall",
        directions = null,
        category = "Social",
        colourHex = "#2E75B6",
        isAttending = false
    )
}
