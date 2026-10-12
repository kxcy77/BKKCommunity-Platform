package za.co.bkkcommunity.app.model

data class CommunityEvent(
    val id: Long,
    val title: String,
    val description: String,
    val startAt: String,
    val endAt: String,
    val location: String,
    val directions: String?,
    val category: String,
    val colourHex: String,
    val isAttending: Boolean,
    val isDemo: Boolean = false
) {
    val isDemonstration: Boolean
        get() = isDemo ||
            category.equals("Demonstration", ignoreCase = true) ||
            title.contains("not a real event", ignoreCase = true) ||
            description.contains("test content only", ignoreCase = true) ||
            location.contains("do not travel", ignoreCase = true)
}

data class Discount(
    val id: Long,
    val storeName: String,
    val title: String,
    val details: String,
    val eligibility: String,
    val claimInstructions: String,
    val category: String,
    val validFrom: String?,
    val validUntil: String?,
    val isDemo: Boolean = false
) {
    val isDemonstration: Boolean
        get() = isDemo || id < 0 ||
            (storeName == "Clicks" && title == "10% off selected prescriptions" && details == "Selected prescription items qualify for a pensioner discount.") ||
            (storeName == "Checkers" && title == "Tuesday senior savings" && details == "Save 5% on qualifying grocery purchases every Tuesday.") ||
            (storeName == "Wimpy" && title == "Senior breakfast special" && details == "A reduced-price breakfast before 10:00 on weekdays.")
}

data class LocalService(
    val id: Long,
    val type: String,
    val name: String,
    val address: String,
    val phone: String,
    val directions: String?,
    val openingHours: String?,
    val isDemo: Boolean = false
) {
    val isDemonstration: Boolean
        get() = isDemo || id < 0 ||
            (name == "BKK Community Clinic" && address == "12 Main Road, BKK" && phone == "011 555 0101") ||
            (name == "Community Pharmacy" && address == "18 Main Road, BKK" && phone == "011 555 0102") ||
            (name == "BKK Community Support Desk" && address == "BKK Community Hall, Main Road" && phone == "072 888 5030")
}

data class Member(
    val id: Long,
    val fullName: String,
    val email: String,
    val phone: String?,
    val notificationsEnabled: Boolean,
    val eventRemindersEnabled: Boolean,
    val discountAlertsEnabled: Boolean
)

data class AuthSession(val member: Member, val token: String)

data class SavedItems(
    val eventIds: Set<Long> = emptySet(),
    val discountIds: Set<Long> = emptySet(),
    val serviceIds: Set<Long> = emptySet()
)

data class CommunityNotice(
    val id: String,
    val title: String,
    val body: String,
    val type: String,
    val itemId: Long?,
    val receivedAt: Long,
    val isRead: Boolean
)
