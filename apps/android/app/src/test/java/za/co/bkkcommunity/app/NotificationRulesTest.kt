package za.co.bkkcommunity.app

import org.junit.Assert.*
import org.junit.Test
import java.time.Instant
import za.co.bkkcommunity.app.notification.NotificationRules

class NotificationRulesTest {
    @Test fun legacyAndroidDoesNotRequireAndroid13Permission() {
        for (sdk in 26..32) assertTrue(NotificationRules.permissionAllows(sdk, false))
    }
    @Test fun modernAndroidHonoursPermissionDenial() {
        for (sdk in 33..36) {
            assertFalse(NotificationRules.permissionAllows(sdk, false))
            assertTrue(NotificationRules.permissionAllows(sdk, true))
        }
    }
    @Test fun expiredAndInvalidEventsNeverSchedule() {
        val now = Instant.parse("2026-10-12T10:00:00Z")
        assertNull(NotificationRules.reminderDelay("bad", now))
        assertNull(NotificationRules.reminderDelay(now.toString(), now))
        assertNull(NotificationRules.reminderDelay("2026-10-11T10:00:00Z", now))
        assertEquals(86_400_000L, NotificationRules.reminderDelay("2026-10-14T10:00:00Z", now))
        assertEquals(1_000L, NotificationRules.reminderDelay("2026-10-12T11:00:00Z", now))
    }
    @Test fun preferencesGateBothMessageTypes() {
        assertFalse(NotificationRules.preferenceAllows(false, true, true, "event"))
        assertFalse(NotificationRules.preferenceAllows(true, false, true, "event"))
        assertFalse(NotificationRules.preferenceAllows(true, true, false, "discount"))
        assertTrue(NotificationRules.preferenceAllows(true, false, true, "discount"))
    }
}
