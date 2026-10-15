package za.co.bkkcommunity.app

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import za.co.bkkcommunity.app.data.ContentSection
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import za.co.bkkcommunity.app.data.BkkRepository
import za.co.bkkcommunity.app.data.FeatureStore
import za.co.bkkcommunity.app.data.SessionStore
import za.co.bkkcommunity.app.data.local.BkkDatabase
import za.co.bkkcommunity.app.data.remote.*
import java.io.IOException

/** Runs on Android with real Room/DataStore, but controlled server snapshots. */
class ContentRefreshTest {
    private lateinit var database: BkkDatabase
    private lateinit var repository: BkkRepository
    private lateinit var features: FeatureStore
    private lateinit var api: SnapshotApi

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, BkkDatabase::class.java).build()
        val sessions = SessionStore(context)
        features = FeatureStore(context)
        api = SnapshotApi(ApiClient.create(sessions))
        repository = BkkRepository(api, database.eventDao(), database.discountDao(),
            database.localServiceDao(), database, sessions, features)
    }

    @After
    fun close() { database.close() }

    @Test
    fun adminEditsReplaceAllThreeCachedContentTypes() = runBlocking {
        repository.refreshAll().getOrThrow()
        api.eventRows = listOf(api.eventRows.single().copy(title = "Updated event", location = "New hall"))
        api.discountRows = listOf(api.discountRows.single().copy(title = "Updated offer", details = "Separate updated details"))
        api.serviceRows = listOf(api.serviceRows.single().copy(name = "Updated clinic", address = "New address"))
        repository.refreshAll().getOrThrow()
        assertEquals("Updated event", repository.eventStream.first().single().title)
        assertEquals("New hall", repository.eventStream.first().single().location)
        assertEquals("Updated offer", repository.discountStream.first().single().title)
        assertEquals("Separate updated details", repository.discountStream.first().single().details)
        assertEquals("Updated clinic", repository.serviceStream.first().single().name)
        assertEquals("New address", repository.serviceStream.first().single().address)
    }

    @Test
    fun archivedServerRecordsDisappearFromCache() = runBlocking {
        repository.refreshAll().getOrThrow()
        api.eventRows = emptyList()
        api.discountRows = emptyList()
        api.serviceRows = emptyList()
        repository.refreshAll().getOrThrow()
        assertTrue(repository.eventStream.first().isEmpty())
        assertTrue(repository.discountStream.first().isEmpty())
        assertTrue(repository.serviceStream.first().isEmpty())
    }

    @Test
    fun partialNetworkFailureOnlyPreservesFailedSection() = runBlocking {
        repository.refreshAll().getOrThrow()
        val before = features.lastUpdated.first()
        api.eventRows = emptyList()
        api.serviceRows = emptyList()
        api.failDiscountRead = true
        assertTrue(repository.refreshAll().isFailure)
        assertTrue(repository.eventStream.first().isEmpty())
        assertEquals("Original offer", repository.discountStream.first().single().title)
        assertTrue(repository.serviceStream.first().isEmpty())
        assertEquals(before, features.lastUpdated.first())
        assertNotNull(repository.syncStatus.value[ContentSection.DISCOUNTS]?.warning)
        assertNull(repository.syncStatus.value[ContentSection.EVENTS]?.warning)
        api.failDiscountRead = false
        repository.refreshAll().getOrThrow()
        assertNull(repository.syncStatus.value[ContentSection.DISCOUNTS]?.warning)
    }

    @Test
    fun concurrentRefreshesShareRequests() = runBlocking {
        api.readDelay = 100
        val first = async { repository.refreshAll() }
        val second = async { repository.refreshAll() }
        first.await().getOrThrow()
        second.await().getOrThrow()
        assertEquals(1, api.eventReads)
    }

    @Test
    fun offlineRsvpNeverClaimsSuccessOrChangesAttendance() = runBlocking {
        repository.refreshAll().getOrThrow()
        assertTrue(repository.setAttendance(991, true).isFailure)
        assertFalse(repository.eventStream.first().single().isAttending)
    }

    @Test
    fun restartingOfflineDoesNotResurrectArchivedDemoRecords() = runBlocking {
        api.eventRows = emptyList()
        api.discountRows = emptyList()
        api.serviceRows = emptyList()
        repository.refreshAll().getOrThrow()
        api.failDiscountRead = true
        assertNotNull(repository.initialize())
        assertTrue(repository.eventStream.first().isEmpty())
        assertTrue(repository.discountStream.first().isEmpty())
        assertTrue(repository.serviceStream.first().isEmpty())
    }

    private class SnapshotApi(delegate: BkkApi) : BkkApi by delegate {
        var eventRows = listOf(EventDto(991, "Original event", "Test description",
            "2099-10-01T08:00:00Z", "2099-10-01T09:00:00Z", "Original hall",
            null, "Community", "#1F4E79", false, false))
        var discountRows = listOf(DiscountDto(992, "Fixture shop", "Original offer", "Original details",
            "All members", "Ask at counter", "Grocery", null, null))
        var serviceRows = listOf(LocalServiceDto(993, "clinic", "Original clinic",
            "Original address", "0115550101", null, "09:00–17:00"))
        var failDiscountRead = false
        var readDelay = 0L
        var eventReads = 0
        override suspend fun events(category: String?): ApiEnvelope<List<EventDto>> {
            eventReads++
            delay(readDelay)
            return ApiEnvelope(eventRows)
        }
        override suspend fun discounts(category: String?): ApiEnvelope<List<DiscountDto>> {
            if (failDiscountRead) throw IOException("Controlled offline fixture")
            return ApiEnvelope(discountRows)
        }
        override suspend fun localServices(type: String?) = ApiEnvelope(serviceRows)
        override suspend fun setAttendance(id: Long, request: AttendanceRequest): ApiEnvelope<AttendanceDto> {
            throw IOException("Controlled offline RSVP fixture")
        }
    }
}
