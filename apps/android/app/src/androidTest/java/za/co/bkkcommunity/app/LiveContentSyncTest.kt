package za.co.bkkcommunity.app

import android.graphics.Bitmap
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.core.app.ApplicationProvider
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.FormBody
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test
import java.io.File

/** Opt-in end-to-end test: use only a temporary administrator approved for verification. */
class LiveContentSyncTest {
    @get:Rule val compose = createAndroidComposeRule<MainActivity>()

    @Test fun adminChangesReachVisibleAndroidWithoutManualRefresh() {
        val args = InstrumentationRegistry.getArguments()
        val email = args.getString("syncEmail")
        val password = args.getString("syncPassword")
        assumeTrue("Requires a temporary verification administrator", !email.isNullOrBlank() && !password.isNullOrBlank())
        val app = ApplicationProvider.getApplicationContext<BkkApplication>()
        val repository = app.container.repository
        val base = BuildConfig.API_BASE_URL.removeSuffix("api/v1/")
        val cookies = mutableListOf<Cookie>()
        val client = OkHttpClient.Builder().cookieJar(object : CookieJar {
            override fun saveFromResponse(url: HttpUrl, values: List<Cookie>) {
                values.forEach { cookie -> cookies.removeAll { it.name == cookie.name }; cookies.add(cookie) }
            }
            override fun loadForRequest(url: HttpUrl) = cookies.filter { it.matches(url) }
        }).build()
        fun get(path: String): String = client.newCall(Request.Builder().url(base + path).build()).execute().use {
            check(it.isSuccessful) { "Verification GET failed: ${it.code}" }; it.body!!.string()
        }
        fun csrf(html: String) = Regex("name=\"csrf_token\" value=\"([^\"]+)\"").find(html)!!.groupValues[1]
        fun post(page: String, values: Map<String, String>): String {
            val body = FormBody.Builder().add("csrf_token", csrf(get(page)))
            values.forEach { (key, value) -> body.add(key, value) }
            return client.newCall(Request.Builder().url(base + "actions.php").post(body.build()).build()).execute().use {
                check(it.isSuccessful) { "Verification POST failed: ${it.code}" }; it.body!!.string()
            }
        }
        post("login.php", mapOf("action" to "login", "email" to email!!, "password" to password!!))
        check(get("admin/users.php").contains("Registered users"))
        runBlocking { repository.login(email, password).getOrThrow(); repository.refreshAll().getOrThrow() }
        compose.waitUntil(15_000) { compose.onAllNodesWithText("Events", useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty() }
        val marker = "Sync Verification ${System.currentTimeMillis()}"
        val event = mapOf("title" to marker, "date" to "2099-10-20", "time" to "10:00", "end_time" to "11:00", "location" to "Verification only", "category" to "Exercise", "tone" to "blue", "description" to "Temporary automated verification record. Not a scheduled community activity.", "directions" to "Verification only")
        val discount = mapOf("store_name" to marker, "category" to "Grocery", "title" to marker, "deal" to "Temporary verification offer; not redeemable.", "eligibility" to "Verification only", "claim_instructions" to "Not redeemable; automated verification only.", "tone" to "gold", "valid_from" to "", "valid_until" to "")
        val service = mapOf("type" to "support", "name" to marker, "address" to "Verification only", "phone" to "0000000000", "directions" to "Verification only", "opening_hours" to "Verification only")
        var eventId: Long? = null
        var discountId: Long? = null
        var serviceId: Long? = null
        fun archive(kind: String, id: Long?) {
            if (id != null) post("admin/${if (kind == "service") "services" else kind + "s"}.php",
                mapOf("action" to "admin_set_${kind}_archived", "id" to id.toString(), "archived" to "1", "reason" to "Automated verification complete"))
        }
        fun screenshot(name: String) {
            val directory = File(app.filesDir, "sync-evidence").apply { mkdirs() }
            File(directory, "$name.png").outputStream().use {
                InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot().compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        }
        try {
            post("admin/events.php", event + ("action" to "admin_create_event"))
            post("admin/discounts.php", discount + ("action" to "admin_create_discount"))
            post("admin/services.php", service + ("action" to "admin_create_service"))
            compose.onNodeWithText("Events", useUnmergedTree = true).performClick()
            compose.waitUntil(35_000) { runBlocking { repository.eventStream.first().any { it.title == marker } && repository.discountStream.first().any { it.storeName == marker } && repository.serviceStream.first().any { it.name == marker } } }
            eventId = runBlocking { repository.eventStream.first().first { it.title == marker }.id }
            discountId = runBlocking { repository.discountStream.first().first { it.storeName == marker }.id }
            serviceId = runBlocking { repository.serviceStream.first().first { it.name == marker }.id }
            assertTrue(get("events.php").contains(marker))
            assertTrue(get("discounts.php").contains(marker))
            assertTrue(get("info.php").contains(marker))
            compose.onNode(hasScrollAction()).performScrollToNode(hasText("Search events"))
            compose.onNodeWithText("Search events").performTextInput(marker)
            androidx.test.espresso.Espresso.closeSoftKeyboard()
            compose.onNode(hasScrollAction()).performScrollToNode(hasText(marker))
            screenshot("android-event-before")
            fun version(page: String) = Regex("name=\"version\" value=\"([^\"]+)\"").find(get(page))!!.groupValues[1]
            post("admin/events.php", event + mapOf("action" to "admin_update_event", "id" to eventId.toString(), "version" to version("admin/events.php?edit=$eventId"), "title" to "$marker Updated"))
            post("admin/discounts.php", discount + mapOf("action" to "admin_update_discount", "id" to discountId.toString(), "version" to version("admin/discounts.php?edit=$discountId"), "title" to "$marker Updated"))
            post("admin/services.php", service + mapOf("action" to "admin_update_service", "id" to serviceId.toString(), "version" to version("admin/services.php?edit=$serviceId"), "name" to "$marker Updated"))
            val started = System.currentTimeMillis()
            compose.waitUntil(35_000) { runBlocking { repository.eventStream.first().any { it.title == "$marker Updated" } && repository.discountStream.first().any { it.title == "$marker Updated" } && repository.serviceStream.first().any { it.name == "$marker Updated" } } }
            assertTrue("Foreground refresh exceeded 35 seconds including network time", System.currentTimeMillis() - started < 35_000)
            compose.onNodeWithText("$marker Updated").assertIsDisplayed()
            assertTrue(get("events.php").contains("$marker Updated"))
            assertTrue(get("discounts.php").contains("$marker Updated"))
            assertTrue(get("info.php").contains("$marker Updated"))
            screenshot("android-event-updated")
            compose.onNodeWithText("$marker Updated").performClick()
            compose.waitForIdle()
            screenshot("android-event-detail")
            archive("event", eventId)
            archive("discount", discountId)
            archive("service", serviceId)
            compose.waitUntil(35_000) { runBlocking { repository.eventStream.first().none { it.id == eventId } && repository.discountStream.first().none { it.id == discountId } && repository.serviceStream.first().none { it.id == serviceId } } }
            compose.waitUntil(5_000) { compose.onAllNodesWithText("$marker Updated").fetchSemanticsNodes().isEmpty() }
            assertFalse(get("events.php").contains(marker))
            assertFalse(get("discounts.php").contains(marker))
            assertFalse(get("info.php").contains(marker))
            screenshot("android-event-withdrawn")
        } finally {
            archive("event", eventId)
            archive("discount", discountId)
            archive("service", serviceId)
        }
    }
}
