package za.co.bkkcommunity.app

import android.graphics.Bitmap
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ApplicationProvider
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import za.co.bkkcommunity.app.data.ContentSection
import za.co.bkkcommunity.app.data.ContentSyncStatus
import za.co.bkkcommunity.app.ui.ContentSyncBanner
import za.co.bkkcommunity.app.ui.theme.BkkTheme
import java.io.File

class ContentSyncBannerTest {
    @get:Rule val compose = createComposeRule()

    @Test fun failedSectionShowsSavedDataWarningAndWorkingRetryAction() {
        var retried = false
        compose.setContent {
            BkkTheme {
                ContentSyncBanner(mapOf(ContentSection.EVENTS to ContentSyncStatus(1_792_054_800_000, "Controlled connection failure")),
                    listOf(ContentSection.EVENTS), false) { retried = true }
            }
        }
        compose.onNodeWithText("Cannot update now; showing saved information.", substring = true).assertIsDisplayed()
        compose.onNodeWithText("Retry update").assertIsDisplayed().performClick()
        assertTrue(retried)
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val directory = File(context.filesDir, "sync-evidence").apply { mkdirs() }
        File(directory, "connection-warning-controlled-ui.png").outputStream().use {
            InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot().compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }
}
