package za.co.bkkcommunity.app

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test
import za.co.bkkcommunity.app.model.CommunityEvent
import za.co.bkkcommunity.app.model.Discount
import za.co.bkkcommunity.app.ui.BkkUiState
import za.co.bkkcommunity.app.ui.screens.HomeScreen
import za.co.bkkcommunity.app.ui.screens.EventDetailScreen
import za.co.bkkcommunity.app.ui.theme.BkkTheme
import java.time.ZoneId
import java.time.ZonedDateTime

class HomeScreenTest {
    @get:Rule val composeRule = createComposeRule()

    @Test fun documentedHomeStructureIsVisibleAndActionable() {
        val state = BkkUiState(
            loading = false,
            events = listOf(CommunityEvent(1, "Morning Exercise", "Gentle exercise", "2026-08-01T07:00:00Z",
                "2026-08-01T07:45:00Z", "Community Hall", null, "Exercise", "#315C24", false)),
            discounts = listOf(Discount(1, "Clicks", "10% off selected prescriptions", "Selected items", "60+", "Show ID", "Pharmacy", null, null))
        )
        composeRule.setContent {
            BkkTheme {
                HomeScreen(state, PaddingValues(0.dp), {}, {}, { _, _ -> })
            }
        }
        composeRule.onNodeWithText("BKK Community").assertIsDisplayed()
        composeRule.onNodeWithText("What would you like to do?").assertIsDisplayed()
        composeRule.onNodeWithText("Events").assertIsDisplayed().assertHasClickAction()
        composeRule.onNodeWithText("Discounts").assertIsDisplayed().assertHasClickAction()
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Local services"))
        composeRule.onNodeWithText("Local services").assertIsDisplayed().assertHasClickAction()
        composeRule.onNodeWithText("Contact BKK").assertIsDisplayed().assertHasClickAction()
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Today's Schedule"))
        composeRule.onNodeWithText("Today's Schedule").assertIsDisplayed()
    }

    @Test fun demonstrationEventCannotOfferAttendanceOrTravelActions() {
        val event = CommunityEvent(
            42, "BKK App Demonstration Event - Not a Real Event", "TEST CONTENT ONLY",
            "2026-08-15T08:00:00Z", "2026-08-15T09:00:00Z",
            "Demonstration only - do not travel", null, "Demonstration", "#BF7600", false
        )
        composeRule.setContent {
            BkkTheme { EventDetailScreen(event, PaddingValues(0.dp), {}, { _, _ -> }) }
        }

        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Test event only"))
        composeRule.onNodeWithText("Test event only").assertIsDisplayed()
        composeRule.onNodeWithText("I will attend").assertDoesNotExist()
        composeRule.onNodeWithText("Open directions").assertDoesNotExist()
        composeRule.onNodeWithText("Add to phone calendar").assertDoesNotExist()
    }

    @Test fun todayScheduleDoesNotShowFutureEvents() {
        val zone = ZoneId.of("Africa/Johannesburg")
        val today = ZonedDateTime.now(zone).withHour(9).withMinute(0).withSecond(0).withNano(0)
        val tomorrow = today.plusDays(1)
        val state = BkkUiState(
            loading = false,
            events = listOf(
                CommunityEvent(11, "Today only", "Today", today.toInstant().toString(), today.plusHours(1).toInstant().toString(),
                    "Community Hall", null, "Social", "#2E75B6", false),
                CommunityEvent(12, "Tomorrow only", "Tomorrow", tomorrow.toInstant().toString(), tomorrow.plusHours(1).toInstant().toString(),
                    "Community Hall", null, "Social", "#2E75B6", false)
            )
        )
        composeRule.setContent {
            BkkTheme { HomeScreen(state, PaddingValues(0.dp), {}, {}, { _, _ -> }) }
        }
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText("Today only"))
        composeRule.onNodeWithText("Today only").assertIsDisplayed()
        composeRule.onAllNodesWithText("Tomorrow only").assertCountEquals(0)
    }
}
