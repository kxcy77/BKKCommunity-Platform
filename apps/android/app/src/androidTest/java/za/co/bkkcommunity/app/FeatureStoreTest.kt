package za.co.bkkcommunity.app

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import java.util.UUID
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import za.co.bkkcommunity.app.data.FeatureStore
import za.co.bkkcommunity.app.model.CommunityNotice

@RunWith(AndroidJUnit4::class)
class FeatureStoreTest {
    @Test fun savedItemsAndNotificationHistoryPersist() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = FeatureStore(context)
        val eventId = System.currentTimeMillis()
        val noticeId = "test-${UUID.randomUUID()}"

        store.toggleSaved("event", eventId)
        assertTrue(eventId in store.savedItems.first().eventIds)

        store.addNotice(
            CommunityNotice(noticeId, "Test update", "Test body", "event", eventId, System.currentTimeMillis(), false)
        )
        assertTrue(store.notices.first().any { it.id == noticeId && !it.isRead })

        store.markNoticeRead(noticeId)
        assertTrue(store.notices.first().first { it.id == noticeId }.isRead)

        store.toggleSaved("event", eventId)
        store.removeNotice(noticeId)
    }
}
