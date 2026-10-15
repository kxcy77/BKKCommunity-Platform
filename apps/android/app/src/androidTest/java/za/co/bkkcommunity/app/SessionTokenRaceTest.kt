package za.co.bkkcommunity.app

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import za.co.bkkcommunity.app.data.SessionStore
import za.co.bkkcommunity.app.model.AuthSession
import za.co.bkkcommunity.app.model.Member

class SessionTokenRaceTest {
    @Test fun delayedRejectionCannotClearNewLogin() = runBlocking {
        val store = SessionStore(ApplicationProvider.getApplicationContext<Context>())
        val member = Member(991, "Session fixture", "session@example.test", null, true, true, true)
        try {
            store.save(AuthSession(member, "old-fixture-token"))
            store.save(AuthSession(member, "new-fixture-token"))
            store.clearIfTokenMatches("old-fixture-token")
            assertEquals("new-fixture-token", store.token())
            assertEquals(member, store.member.first())
            store.clearIfTokenMatches("new-fixture-token")
            assertNull(store.token())
            assertNull(store.member.first())
        } finally { store.clear() }
    }
}
