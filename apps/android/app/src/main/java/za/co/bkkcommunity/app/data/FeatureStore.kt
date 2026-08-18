package za.co.bkkcommunity.app.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import java.io.IOException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import org.json.JSONArray
import org.json.JSONObject
import za.co.bkkcommunity.app.model.CommunityNotice
import za.co.bkkcommunity.app.model.SavedItems

private val Context.featureDataStore by preferencesDataStore(name = "feature_preferences")

class FeatureStore(private val context: Context) {
    val savedItems: Flow<SavedItems> = context.featureDataStore.data
        .catch { error -> if (error is IOException) emit(androidx.datastore.preferences.core.emptyPreferences()) else throw error }
        .map { preferences ->
            SavedItems(
                eventIds = preferences[Keys.SAVED_EVENTS].orEmpty().mapNotNull(String::toLongOrNull).toSet(),
                discountIds = preferences[Keys.SAVED_DISCOUNTS].orEmpty().mapNotNull(String::toLongOrNull).toSet(),
                serviceIds = preferences[Keys.SAVED_SERVICES].orEmpty().mapNotNull(String::toLongOrNull).toSet()
            )
        }

    val notices: Flow<List<CommunityNotice>> = context.featureDataStore.data
        .catch { error -> if (error is IOException) emit(androidx.datastore.preferences.core.emptyPreferences()) else throw error }
        .map { preferences -> decodeNotices(preferences[Keys.NOTICES].orEmpty()) }

    val lastUpdated: Flow<Long?> = context.featureDataStore.data
        .catch { error -> if (error is IOException) emit(androidx.datastore.preferences.core.emptyPreferences()) else throw error }
        .map { it[Keys.LAST_UPDATED] }

    suspend fun toggleSaved(type: String, id: Long) {
        val key = when (type) {
            "event" -> Keys.SAVED_EVENTS
            "discount" -> Keys.SAVED_DISCOUNTS
            "service" -> Keys.SAVED_SERVICES
            else -> return
        }
        context.featureDataStore.edit { preferences ->
            val next = preferences[key].orEmpty().toMutableSet()
            if (!next.add(id.toString())) next.remove(id.toString())
            preferences[key] = next
        }
    }

    suspend fun recordSuccessfulRefresh(at: Long = System.currentTimeMillis()) {
        context.featureDataStore.edit { it[Keys.LAST_UPDATED] = at }
    }

    suspend fun addNotice(notice: CommunityNotice) {
        context.featureDataStore.edit { preferences ->
            val notices = decodeNotices(preferences[Keys.NOTICES].orEmpty())
                .filterNot { it.id == notice.id }
                .toMutableList()
            notices.add(0, notice)
            preferences[Keys.NOTICES] = encodeNotices(notices.take(MAX_NOTICES))
        }
    }

    suspend fun markNoticeRead(id: String) {
        context.featureDataStore.edit { preferences ->
            val updated = decodeNotices(preferences[Keys.NOTICES].orEmpty())
                .map { if (it.id == id) it.copy(isRead = true) else it }
            preferences[Keys.NOTICES] = encodeNotices(updated)
        }
    }

    suspend fun clearNotices() {
        context.featureDataStore.edit { it.remove(Keys.NOTICES) }
    }

    suspend fun removeNotice(id: String) {
        context.featureDataStore.edit { preferences ->
            preferences[Keys.NOTICES] = encodeNotices(
                decodeNotices(preferences[Keys.NOTICES].orEmpty()).filterNot { it.id == id }
            )
        }
    }

    private fun decodeNotices(raw: String): List<CommunityNotice> = runCatching {
        val array = JSONArray(raw.ifBlank { "[]" })
        buildList {
            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                add(
                    CommunityNotice(
                        id = item.getString("id"),
                        title = item.getString("title"),
                        body = item.getString("body"),
                        type = item.optString("type", "general"),
                        itemId = if (item.isNull("itemId")) null else item.optLong("itemId"),
                        receivedAt = item.getLong("receivedAt"),
                        isRead = item.optBoolean("isRead", false)
                    )
                )
            }
        }
    }.getOrDefault(emptyList())

    private fun encodeNotices(items: List<CommunityNotice>): String = JSONArray().apply {
        items.forEach { notice ->
            put(JSONObject().apply {
                put("id", notice.id)
                put("title", notice.title)
                put("body", notice.body)
                put("type", notice.type)
                put("itemId", notice.itemId ?: JSONObject.NULL)
                put("receivedAt", notice.receivedAt)
                put("isRead", notice.isRead)
            })
        }
    }.toString()

    private object Keys {
        val SAVED_EVENTS = stringSetPreferencesKey("saved_events")
        val SAVED_DISCOUNTS = stringSetPreferencesKey("saved_discounts")
        val SAVED_SERVICES = stringSetPreferencesKey("saved_services")
        val NOTICES = stringPreferencesKey("notification_history")
        val LAST_UPDATED = longPreferencesKey("last_successful_refresh")
    }

    private companion object {
        const val MAX_NOTICES = 30
    }
}
