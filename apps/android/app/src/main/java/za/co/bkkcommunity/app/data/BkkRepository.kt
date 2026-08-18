package za.co.bkkcommunity.app.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.json.JSONObject
import androidx.room.withTransaction
import retrofit2.HttpException
import za.co.bkkcommunity.app.data.local.BkkDatabase
import za.co.bkkcommunity.app.data.local.DiscountDao
import za.co.bkkcommunity.app.data.local.DiscountEntity
import za.co.bkkcommunity.app.data.local.EventDao
import za.co.bkkcommunity.app.data.local.EventEntity
import za.co.bkkcommunity.app.data.local.LocalServiceDao
import za.co.bkkcommunity.app.data.local.LocalServiceEntity
import za.co.bkkcommunity.app.data.local.toDomain
import za.co.bkkcommunity.app.data.remote.AttendanceRequest
import za.co.bkkcommunity.app.data.remote.BkkApi
import za.co.bkkcommunity.app.data.remote.ContactRequest
import za.co.bkkcommunity.app.data.remote.DeviceRequest
import za.co.bkkcommunity.app.data.remote.ForgotPasswordRequest
import za.co.bkkcommunity.app.data.remote.LoginRequest
import za.co.bkkcommunity.app.data.remote.PreferencesRequest
import za.co.bkkcommunity.app.data.remote.ProfileRequest
import za.co.bkkcommunity.app.data.remote.RegisterRequest
import za.co.bkkcommunity.app.model.AuthSession
import za.co.bkkcommunity.app.model.CommunityEvent
import za.co.bkkcommunity.app.model.Discount
import za.co.bkkcommunity.app.model.LocalService
import za.co.bkkcommunity.app.model.Member
import java.io.IOException
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class BkkRepository(
    private val api: BkkApi,
    private val events: EventDao,
    private val discounts: DiscountDao,
    private val services: LocalServiceDao,
    private val database: BkkDatabase,
    private val sessionStore: SessionStore,
    private val featureStore: FeatureStore
) {
    val eventStream: Flow<List<CommunityEvent>> = events.observeAll().map { rows -> rows.map { it.toDomain() } }
    val discountStream: Flow<List<Discount>> = discounts.observeAll().map { rows -> rows.map { it.toDomain() } }
    val serviceStream: Flow<List<LocalService>> = services.observeAll().map { rows -> rows.map { it.toDomain() } }
    val memberStream: Flow<Member?> = sessionStore.member

    suspend fun initialize(): String? {
        seedDemoIfEmpty()
        return refreshAll().exceptionOrNull()?.let(::messageFor)
    }

    suspend fun refreshAll(): Result<Unit> = runCatching {
        val remoteEvents = api.events().data.map { it.toEntity() }
        val remoteDiscounts = api.discounts().data.map { it.toEntity() }
        val remoteServices = api.localServices().data.map { it.toEntity() }
        database.withTransaction {
            events.clear()
            discounts.clear()
            services.clear()
            events.replaceAll(remoteEvents)
            discounts.replaceAll(remoteDiscounts)
            services.replaceAll(remoteServices)
        }
        featureStore.recordSuccessfulRefresh()
    }

    suspend fun eventDetail(id: Long): Result<CommunityEvent> = runCatching {
        val remote = api.event(id).data.toEntity()
        events.replaceAll(listOf(remote))
        remote.toDomain()
    }

    suspend fun discountDetail(id: Long): Result<Discount> = runCatching {
        val remote = api.discount(id).data.toEntity()
        discounts.replaceAll(listOf(remote))
        remote.toDomain()
    }

    suspend fun login(email: String, password: String): Result<Member> = runCatching {
        val auth = api.login(LoginRequest(email.trim(), password)).data
        val member = auth.user.toDomain()
        sessionStore.save(AuthSession(member, auth.token))
        member
    }

    suspend fun register(name: String, email: String, phone: String?, password: String): Result<Member> = runCatching {
        val auth = api.register(RegisterRequest(name.trim(), email.trim(), phone?.trim()?.ifBlank { null }, password)).data
        val member = auth.user.toDomain()
        sessionStore.save(AuthSession(member, auth.token))
        member
    }

    suspend fun forgotPassword(email: String): Result<String> = runCatching {
        api.forgotPassword(ForgotPasswordRequest(email.trim())).data["message"]
            ?: "If the account exists, reset instructions have been sent."
    }

    suspend fun resetPassword(email: String, token: String, password: String): Result<String> = runCatching {
        api.resetPassword(za.co.bkkcommunity.app.data.remote.ResetPasswordRequest(email.trim(), token, password)).data["message"]
            ?: "Your password has been updated."
    }

    suspend fun attendanceHistory(): Result<List<CommunityEvent>> = runCatching {
        api.attendanceHistory().data.map { it.toEntity().toDomain() }
    }

    suspend fun beginLogout(): String? {
        val token = sessionStore.token()
        sessionStore.clear()
        return token
    }

    suspend fun revokeSession(token: String?) {
        // Local sign-out is the safety boundary. Keep server revocation
        // best-effort so an offline or slow request cannot leave the user
        // inside the app or restore their secure token.
        runCatching { api.logout(token?.let { "Bearer $it" }) }
    }

    suspend fun setAttendance(eventId: Long, attending: Boolean): Result<Unit> = runCatching {
        api.setAttendance(eventId, AttendanceRequest(if (attending) "attending" else "cancelled"))
        events.setAttendance(eventId, attending)
    }

    suspend fun submitContact(name: String, email: String, message: String): Result<String> = runCatching {
        api.contact(ContactRequest(name.trim(), email.trim(), message.trim())).data.message
    }

    suspend fun registerDevice(token: String, enabled: Boolean = true): Result<Unit> = runCatching {
        if (sessionStore.token() != null) api.registerDevice(DeviceRequest(token, enabled))
    }

    suspend fun updateProfile(name: String, email: String, phone: String?): Result<Member> = runCatching {
        api.updateProfile(ProfileRequest(name.trim(), email.trim(), phone?.trim()?.ifBlank { null })).data
            .toDomain().also { sessionStore.saveMember(it) }
    }

    suspend fun updatePreferences(notifications: Boolean, reminders: Boolean, discounts: Boolean): Result<Member> = runCatching {
        api.updatePreferences(PreferencesRequest(notifications, reminders, discounts)).data
            .toDomain().also { sessionStore.saveMember(it) }
    }

    suspend fun deleteAccount(): Result<Unit> = runCatching {
        api.deleteAccount()
        sessionStore.clear()
    }

    fun errorMessage(error: Throwable): String = messageFor(error)

    private suspend fun seedDemoIfEmpty() {
        val zone = ZoneId.of("Africa/Johannesburg")
        val base = LocalDate.now(zone)
        fun iso(dayOffset: Long, hour: Int, minute: Int): String = base.plusDays(dayOffset)
            .atTime(hour, minute).atZone(zone).toInstant().toString()

        if (events.count() == 0) {
            events.replaceAll(listOf(
                EventEntity(-1, "Morning Exercise", "A gentle exercise session suitable for all mobility levels.",
                    iso(0, 9, 0), iso(0, 9, 45), "Community Hall", "Use the Block B entrance.", "Exercise", "#315C24", false, true),
                EventEntity(-2, "Social Lunch Gathering", "Share lunch and connect with other community members.",
                    iso(2, 12, 0), iso(2, 13, 30), "BKK Hall", "Main Road entrance.", "Social", "#2E75B6", false, true),
                EventEntity(-3, "Health Talk: Managing Diabetes", "Practical information with time for questions.",
                    iso(4, 14, 0), iso(4, 15, 30), "Clinic Room 2", "Use the reception entrance.", "Health", "#B00020", false, true)
            ))
        }
        if (discounts.count() == 0) {
            discounts.replaceAll(listOf(
                DiscountEntity(-1, "Clicks", "10% off selected prescriptions", "Selected prescriptions qualify.",
                    "Customers aged 60+ with valid ID.", "Show your ID at the pharmacy counter.", "Pharmacy", null, null, true),
                DiscountEntity(-2, "Checkers", "Tuesday senior savings", "Save 5% on qualifying groceries.",
                    "Customers aged 60+.", "Present ID before payment.", "Grocery", null, null, true),
                DiscountEntity(-3, "Wimpy", "Senior breakfast special", "Reduced-price breakfast before 10:00.",
                    "Customers aged 60+.", "Ask for the senior menu.", "Restaurant", null, null, true)
            ))
        }
        if (services.count() == 0) {
            services.replaceAll(listOf(
                LocalServiceEntity(-1, "clinic", "BKK Community Clinic", "12 Main Road, BKK", "011 555 0101",
                    "Opposite the community hall.", "Mon–Fri 08:00–16:00", true),
                LocalServiceEntity(-2, "pharmacy", "Community Pharmacy", "18 Main Road, BKK", "011 555 0102",
                    "Next to the grocery store.", "Mon–Sat 08:00–18:00", true),
                LocalServiceEntity(-3, "support", "BKK Community Support Desk", "BKK Community Hall", "072 888 5030",
                    "Reception desk inside the main entrance.", "Weekdays 09:00–15:00", true)
            ))
        }
    }

    private fun messageFor(error: Throwable): String = when (error) {
        is IOException -> "No connection to the BKK server. Please check your internet connection and try again."
        is HttpException -> runCatching {
            val raw = error.response()?.errorBody()?.string().orEmpty()
            JSONObject(raw).optJSONObject("error")?.optString("message")
        }.getOrNull().takeUnless { it.isNullOrBlank() } ?: "The server could not complete that request."
        else -> error.message ?: "Something went wrong. Please try again."
    }
}
