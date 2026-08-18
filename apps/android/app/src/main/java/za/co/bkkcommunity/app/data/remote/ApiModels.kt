package za.co.bkkcommunity.app.data.remote

import com.squareup.moshi.Json
import za.co.bkkcommunity.app.data.local.DiscountEntity
import za.co.bkkcommunity.app.data.local.EventEntity
import za.co.bkkcommunity.app.data.local.LocalServiceEntity
import za.co.bkkcommunity.app.model.Member

data class ApiEnvelope<T>(val data: T)

data class EventDto(
    val id: Long,
    val title: String,
    val description: String,
    @Json(name = "start_at") val startAt: String,
    @Json(name = "end_at") val endAt: String,
    val location: String,
    val directions: String?,
    val category: String,
    @Json(name = "colour_hex") val colourHex: String,
    @Json(name = "is_attending") val isAttending: Boolean,
    @Json(name = "is_demo") val isDemo: Boolean? = null
) {
    fun toEntity() = EventEntity(
        id, title, description, startAt, endAt, location, directions, category, colourHex, isAttending,
        isDemo ?: category.equals("Demonstration", ignoreCase = true)
    )
}

data class DiscountDto(
    val id: Long,
    @Json(name = "store_name") val storeName: String,
    val title: String,
    val details: String,
    val eligibility: String,
    @Json(name = "claim_instructions") val claimInstructions: String,
    val category: String,
    @Json(name = "valid_from") val validFrom: String?,
    @Json(name = "valid_until") val validUntil: String?
) {
    fun toEntity() = DiscountEntity(
        id, storeName, title, details, eligibility, claimInstructions, category, validFrom, validUntil
    )
}

data class LocalServiceDto(
    val id: Long,
    val type: String,
    val name: String,
    val address: String,
    val phone: String,
    val directions: String?,
    @Json(name = "opening_hours") val openingHours: String?
) {
    fun toEntity() = LocalServiceEntity(id, type, name, address, phone, directions, openingHours)
}

data class MemberDto(
    val id: Long,
    @Json(name = "full_name") val fullName: String,
    val email: String,
    val phone: String?,
    @Json(name = "notifications_enabled") val notificationsEnabled: Boolean,
    @Json(name = "event_reminders_enabled") val eventRemindersEnabled: Boolean,
    @Json(name = "discount_alerts_enabled") val discountAlertsEnabled: Boolean
) {
    fun toDomain() = Member(id, fullName, email, phone, notificationsEnabled, eventRemindersEnabled, discountAlertsEnabled)
}

data class AuthDto(val user: MemberDto, val token: String)
data class RegisterRequest(@Json(name = "full_name") val fullName: String, val email: String, val phone: String?, val password: String)
data class LoginRequest(val email: String, val password: String)
data class ForgotPasswordRequest(val email: String)
data class ResetPasswordRequest(val email: String, val token: String, val password: String)
data class AttendanceRequest(val status: String)
data class AttendanceDto(@Json(name = "event_id") val eventId: Long, val status: String)
data class ContactRequest(val name: String, val email: String, val message: String)
data class ContactResult(val id: Long, val message: String)
data class DeviceRequest(
    @Json(name = "fcm_token") val fcmToken: String,
    @Json(name = "notifications_enabled") val enabled: Boolean,
    val platform: String = "android"
)
data class PreferencesRequest(
    @Json(name = "notifications_enabled") val notificationsEnabled: Boolean,
    @Json(name = "event_reminders_enabled") val eventRemindersEnabled: Boolean,
    @Json(name = "discount_alerts_enabled") val discountAlertsEnabled: Boolean
)
data class ProfileRequest(@Json(name = "full_name") val fullName: String, val email: String, val phone: String?)
