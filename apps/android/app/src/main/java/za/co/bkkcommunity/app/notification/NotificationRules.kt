package za.co.bkkcommunity.app.notification

import java.time.Duration
import java.time.Instant

/** Pure decisions shared by both notification paths and covered by JVM tests. */
object NotificationRules {
    fun permissionAllows(sdk: Int, runtimePermissionGranted: Boolean): Boolean =
        sdk < 33 || runtimePermissionGranted

    fun reminderDelay(startAt: String, now: Instant = Instant.now()): Long? {
        val start = runCatching { Instant.parse(startAt) }.getOrNull() ?: return null
        if (!start.isAfter(now)) return null
        return Duration.between(now, start.minus(Duration.ofHours(24))).toMillis().coerceAtLeast(1_000)
    }

    fun preferenceAllows(notifications: Boolean, reminders: Boolean, discounts: Boolean, type: String?): Boolean =
        notifications && when (type) {
            "event" -> reminders
            "discount" -> discounts
            else -> true
        }
}
