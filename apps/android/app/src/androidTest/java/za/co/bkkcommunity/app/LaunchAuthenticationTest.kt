package za.co.bkkcommunity.app

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.runBlocking
import org.junit.Before
import org.junit.Rule
import org.junit.Test

class LaunchAuthenticationTest {
    @get:Rule
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun clearStoredSession() {
        val application = ApplicationProvider.getApplicationContext<BkkApplication>()
        runBlocking { application.container.sessionStore.clear() }
        composeRule.activityRule.scenario.recreate()
        composeRule.waitForIdle()
    }

    @Test
    fun signedOutUserLandsOnLogin() {
        composeRule.onNodeWithText("Welcome back").assertIsDisplayed()
        composeRule.onNodeWithText("Account sign in").assertIsDisplayed()
        composeRule.onNodeWithText("Sign In").assertIsDisplayed()
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Create an Account"))
        composeRule.onNodeWithText("Create an Account").assertIsDisplayed()
    }

    @Test
    fun recoveryAndRegistrationRemainReachableFromLoginGate() {
        composeRule.onNodeWithText("Forgot your password?").performClick()
        composeRule.onNodeWithText("Reset Your Password").assertIsDisplayed()

        composeRule.onNodeWithContentDescription("Go back").performClick()
        composeRule.waitForIdle()
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Create an Account"))
        composeRule.onNodeWithText("Create an Account").performClick()
        composeRule.waitForIdle()
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Register to RSVP for events and receive reminders."))
        composeRule.onNodeWithText("Register to RSVP for events and receive reminders.").assertIsDisplayed()
    }
}
