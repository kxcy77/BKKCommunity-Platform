package za.co.bkkcommunity.app.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import za.co.bkkcommunity.app.model.AuthSession
import za.co.bkkcommunity.app.model.Member

private val Context.sessionDataStore by preferencesDataStore(name = "session")

class SessionStore(private val context: Context) {
    private val secureTokens = SecureTokenStore(context.applicationContext)
    @Volatile private var tokenSnapshot: String? = secureTokens.read()

    val member: Flow<Member?> = context.sessionDataStore.data.map { preferences ->
        // Profile data without its matching secure token is not an authenticated session.
        if (tokenSnapshot == null) return@map null
        val id = preferences[Keys.ID] ?: return@map null
        Member(
            id = id,
            fullName = preferences[Keys.NAME].orEmpty(),
            email = preferences[Keys.EMAIL].orEmpty(),
            phone = preferences[Keys.PHONE],
            notificationsEnabled = preferences[Keys.NOTIFICATIONS] ?: true,
            eventRemindersEnabled = preferences[Keys.EVENT_REMINDERS] ?: true,
            discountAlertsEnabled = preferences[Keys.DISCOUNT_ALERTS] ?: true
        )
    }

    fun token(): String? = tokenSnapshot

    suspend fun save(session: AuthSession) {
        saveMember(session.member, session.token)
    }

    suspend fun saveMember(member: Member, token: String? = null) {
        if (token != null) {
            secureTokens.write(token)
            tokenSnapshot = token
        }
        context.sessionDataStore.edit { preferences ->
            preferences[Keys.ID] = member.id
            preferences[Keys.NAME] = member.fullName
            preferences[Keys.EMAIL] = member.email
            member.phone?.let { preferences[Keys.PHONE] = it } ?: preferences.remove(Keys.PHONE)
            preferences[Keys.NOTIFICATIONS] = member.notificationsEnabled
            preferences[Keys.EVENT_REMINDERS] = member.eventRemindersEnabled
            preferences[Keys.DISCOUNT_ALERTS] = member.discountAlertsEnabled
        }
    }

    suspend fun savePreferences(notifications: Boolean, eventReminders: Boolean, discountAlerts: Boolean) {
        context.sessionDataStore.edit { preferences ->
            preferences[Keys.NOTIFICATIONS] = notifications
            preferences[Keys.EVENT_REMINDERS] = eventReminders
            preferences[Keys.DISCOUNT_ALERTS] = discountAlerts
        }
    }

    suspend fun clear() {
        context.sessionDataStore.edit { it.clear() }
        secureTokens.clear()
        tokenSnapshot = null
    }

    private object Keys {
        val ID = longPreferencesKey("member_id")
        val NAME = stringPreferencesKey("full_name")
        val EMAIL = stringPreferencesKey("email")
        val PHONE = stringPreferencesKey("phone")
        val NOTIFICATIONS = booleanPreferencesKey("notifications")
        val EVENT_REMINDERS = booleanPreferencesKey("event_reminders")
        val DISCOUNT_ALERTS = booleanPreferencesKey("discount_alerts")
    }
}
