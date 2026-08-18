package za.co.bkkcommunity.app.ui.screens

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.ContactMail
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.EventAvailable
import androidx.compose.material.icons.filled.Directions
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.LocalOffer
import androidx.compose.material.icons.filled.LocationCity
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockReset
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Store
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import za.co.bkkcommunity.app.model.CommunityEvent
import za.co.bkkcommunity.app.model.CommunityNotice
import za.co.bkkcommunity.app.model.Discount
import za.co.bkkcommunity.app.model.ValidationRules
import za.co.bkkcommunity.app.ui.BkkUiState
import za.co.bkkcommunity.app.ui.Routes
import za.co.bkkcommunity.app.ui.components.ActionTile
import za.co.bkkcommunity.app.ui.components.BkkTopBar
import za.co.bkkcommunity.app.ui.components.DemoContentNotice
import za.co.bkkcommunity.app.ui.components.DiscountCard
import za.co.bkkcommunity.app.ui.components.EmptyPane
import za.co.bkkcommunity.app.ui.components.EventCard
import za.co.bkkcommunity.app.ui.components.LoadingPane
import za.co.bkkcommunity.app.ui.components.SectionTitle
import za.co.bkkcommunity.app.ui.components.ServiceCard
import za.co.bkkcommunity.app.ui.components.categoryColour
import za.co.bkkcommunity.app.ui.components.formatLongDate
import za.co.bkkcommunity.app.ui.components.formatTime
import za.co.bkkcommunity.app.ui.theme.BkkBlue
import za.co.bkkcommunity.app.ui.theme.BkkDeepNavy
import za.co.bkkcommunity.app.ui.theme.BkkGold
import za.co.bkkcommunity.app.ui.theme.BkkGoldSurface
import za.co.bkkcommunity.app.ui.theme.BkkGreen
import za.co.bkkcommunity.app.ui.theme.BkkGreenSurface
import za.co.bkkcommunity.app.ui.theme.BkkLightBlue
import za.co.bkkcommunity.app.ui.theme.BkkLine
import za.co.bkkcommunity.app.ui.theme.BkkMuted
import za.co.bkkcommunity.app.ui.theme.BkkNavy
import za.co.bkkcommunity.app.ui.theme.BkkRed
import za.co.bkkcommunity.app.ui.theme.BkkRedSurface
import za.co.bkkcommunity.app.ui.theme.BkkTeal
import za.co.bkkcommunity.app.ui.theme.BkkTealSurface
import za.co.bkkcommunity.app.ui.theme.BkkWarmSurface
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun HomeScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onNavigate: (String) -> Unit,
    onRefresh: () -> Unit,
    onAttendance: (CommunityEvent, Boolean) -> Unit,
    onToggleSaved: (String, Long) -> Unit = { _, _ -> }
) {
    val todayEvents = remember(state.events) { state.events.filter(::isToday) }
    Column(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("BKK Community")
        LazyColumn(contentPadding = PaddingValues(bottom = 24.dp)) {
            item {
                val name = state.member?.fullName?.substringBefore(' ') ?: "there"
                val todayCount = state.events.count(::isToday)
                Box(
                    Modifier.fillMaxWidth().background(
                        Brush.verticalGradient(listOf(BkkNavy, BkkDeepNavy))
                    )
                ) {
                    Column(Modifier.padding(horizontal = 22.dp, vertical = 26.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text("YOUR COMMUNITY TODAY", style = MaterialTheme.typography.labelMedium, color = Color(0xFFFFD88A), fontWeight = FontWeight.Bold)
                        Text("${greetingForHour(LocalTime.now(ZoneId.of("Africa/Johannesburg")).hour)}, $name", style = MaterialTheme.typography.headlineLarge, color = Color.White)
                        Surface(color = Color.White.copy(alpha = .13f), shape = RoundedCornerShape(16.dp)) {
                            Text(
                                "You have $todayCount ${if (todayCount == 1) "event" else "events"} today",
                                Modifier.padding(horizontal = 14.dp, vertical = 8.dp), color = Color.White, style = MaterialTheme.typography.bodyLarge
                            )
                        }
                        Button(
                            onClick = { onNavigate(Routes.EVENTS_TODAY) },
                            modifier = Modifier.fillMaxWidth().heightIn(min = 58.dp),
                            shape = RoundedCornerShape(17.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = BkkNavy)
                        ) {
                            Icon(Icons.Default.EventAvailable, contentDescription = null)
                            Text("View today's events", Modifier.padding(start = 10.dp))
                        }
                    }
                }
            }
            state.discounts.firstOrNull()?.let { discount ->
                item {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = BkkGoldSurface),
                        shape = RoundedCornerShape(22.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, BkkGold.copy(alpha = .28f)),
                        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp),
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp)
                    ) {
                        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Surface(color = BkkGold.copy(alpha = .14f), shape = RoundedCornerShape(15.dp)) {
                                Icon(Icons.Default.Notifications, contentDescription = null, tint = BkkGold, modifier = Modifier.padding(11.dp))
                            }
                            Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
                                Text("New saving for you", style = MaterialTheme.typography.titleMedium, color = Color(0xFF5E3900))
                                Text("${discount.storeName}: ${discount.title}", style = MaterialTheme.typography.bodyMedium, color = Color(0xFF5E3900))
                            }
                            Button(
                                onClick = { onNavigate(Routes.discount(discount.id)) },
                                colors = ButtonDefaults.buttonColors(containerColor = BkkGold),
                                shape = RoundedCornerShape(14.dp)
                            ) {
                                Text("View")
                            }
                        }
                    }
                }
            }
            item {
                Column(
                    Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    SectionTitle("What would you like to do?")
                    Text("Choose one option. You can always return to Home.", color = BkkMuted)
                    TextButton(onClick = onRefresh, modifier = Modifier.heightIn(min = 48.dp)) {
                        Text("Refresh information")
                    }
                }
                Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    ActionTile("Events", "See activities", Icons.Default.CalendarMonth, BkkBlue, BkkLightBlue,
                        { onNavigate(Routes.EVENTS) }, Modifier.weight(1f))
                    ActionTile("Discounts", "Find savings", Icons.Default.LocalOffer, BkkGreen, BkkGreenSurface,
                        { onNavigate(Routes.DISCOUNTS) }, Modifier.weight(1f))
                }
                Spacer(Modifier.height(14.dp))
                Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    ActionTile("Local services", "Phone numbers and places", Icons.Default.LocationCity, BkkTeal, BkkTealSurface,
                        { onNavigate(Routes.INFO) }, Modifier.weight(1f))
                    ActionTile("Contact BKK", "Ask for help", Icons.Default.ContactMail, BkkRed, BkkRedSurface,
                        { onNavigate(Routes.CONTACT) }, Modifier.weight(1f))
                }
            }
            if (state.events.any { it.id < 0 }) item { DemoContentNotice(Modifier.padding(20.dp)) }
            item { DataFreshnessNotice(state.lastUpdated, state.events.any { it.id < 0 }, state.dataWarning) }
            item { SectionTitle("Today's Schedule", Modifier.padding(horizontal = 20.dp, vertical = 18.dp)) }
            if (state.loading && state.events.isEmpty()) item { LoadingPane() }
            else if (todayEvents.isEmpty()) item { EmptyPane("No events today", "Open Events to see what is coming up next.") }
            else items(todayEvents.take(1), key = { it.id }) { event ->
                EventCard(
                    event,
                    { onNavigate(Routes.event(event.id)) },
                    { onAttendance(event, it) },
                    Modifier.padding(horizontal = 20.dp, vertical = 7.dp),
                    isSaved = event.id in state.savedItems.eventIds,
                    onToggleSaved = { onToggleSaved("event", event.id) }
                )
            }
        }
    }
}

@Composable
fun EventsScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onProfile: () -> Unit,
    onOpen: (Long) -> Unit,
    onAttendance: (CommunityEvent, Boolean) -> Unit,
    initialPeriod: String = "All",
    onToggleSaved: (String, Long) -> Unit = { _, _ -> }
) {
    var category by rememberSaveable { mutableStateOf("All") }
    var period by rememberSaveable(initialPeriod) { mutableStateOf(initialPeriod) }
    var query by rememberSaveable { mutableStateOf("") }
    val categories = listOf("All") + state.events.map { it.category }.distinct()
    val filtered = state.events.filter { event ->
        (category == "All" || event.category == category) &&
            eventMatchesPeriod(event, period) &&
            (query.isBlank() || listOf(event.title, event.description, event.location, event.category)
                .any { it.contains(query.trim(), ignoreCase = true) })
    }
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Community Events", onProfile = onProfile)
        LazyColumn(contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            item { ScreenIntro("Find your next event", "Friendly activities, health talks and social gatherings near you.") }
            item {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    label = { Text("Search events") },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            item {
                Text("When", fontWeight = FontWeight.Bold, color = BkkNavy)
                CategoryFilterRow(listOf("All", "Today", "This week", "Later"), period, Modifier.padding(top = 8.dp)) { period = it }
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Browse by category", fontWeight = FontWeight.Bold, color = BkkNavy)
                    CategoryFilterRow(categories, category) { category = it }
                }
            }
            if (state.events.any { it.id < 0 }) item { DemoContentNotice() }
            if (state.loading && filtered.isEmpty()) item { LoadingPane() }
            else if (filtered.isEmpty()) item { EmptyPane("No matching events", "Choose another category or check again later.") }
            else items(filtered, key = { it.id }) { event ->
                EventCard(
                    event,
                    { onOpen(event.id) },
                    { onAttendance(event, it) },
                    isSaved = event.id in state.savedItems.eventIds,
                    onToggleSaved = { onToggleSaved("event", event.id) }
                )
            }
        }
    }
}

@Composable
fun EventDetailScreen(
    event: CommunityEvent?,
    padding: PaddingValues,
    onBack: () -> Unit,
    onAttendance: (CommunityEvent, Boolean) -> Unit,
    loading: Boolean = false,
    isSaved: Boolean = false,
    onToggleSaved: () -> Unit = {},
    onReport: () -> Unit = {}
) {
    val context = LocalContext.current
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Event Details", onBack = onBack)
        if (event == null) {
            Box(Modifier.fillMaxSize().padding(20.dp), contentAlignment = Alignment.Center) {
                if (loading) LoadingPane("Loading event details")
                else EmptyPane("Event unavailable", "The event may have been removed or could not be loaded.")
            }
            return@Column
        }
        Column(Modifier.padding(22.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Surface(color = categoryColour(event.category), contentColor = Color.White, shape = RoundedCornerShape(18.dp)) {
                Text(event.category, Modifier.padding(horizontal = 16.dp, vertical = 8.dp), fontWeight = FontWeight.Bold)
            }
            Text(event.title, style = MaterialTheme.typography.headlineLarge, color = BkkNavy)
            DetailLine(Icons.Default.CalendarMonth, "${formatLongDate(event.startAt)} at ${formatTime(event.startAt)}")
            DetailLine(Icons.Default.LocationCity, event.location)
            HorizontalDivider()
            SectionTitle("About this event")
            Text(event.description)
            event.directions?.let { SectionTitle("Directions"); Text(it) }
            SectionTitle("Accessibility and practical needs")
            Text("Contact BKK before attending if you need wheelchair access, transport help, carer access, cost information or a list of what to bring.")
            if (event.isDemonstration) {
                Surface(
                    color = BkkGoldSurface,
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.fillMaxWidth().semantics { contentDescription = "Test event only. Attendance and travel actions are unavailable." }
                ) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Test event only", fontWeight = FontWeight.Bold, color = Color(0xFF5E3900))
                        Text("Attendance, calendar, directions and sharing are unavailable because this is not a real event.", color = Color(0xFF5E3900))
                    }
                }
            } else {
                Button(
                    onClick = { onAttendance(event, !event.isAttending) },
                    modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = if (event.isAttending) BkkGreen else BkkBlue)
                ) { Text(if (event.isAttending) "Cancel attendance" else "I will attend") }
                OutlinedButton(onClick = onToggleSaved, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Icon(Icons.Default.Bookmark, contentDescription = null)
                    Text(if (isSaved) "Remove from saved" else "Save event", Modifier.padding(start = 8.dp))
                }
                OutlinedButton(onClick = { addEventToCalendar(context, event) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Icon(Icons.Default.CalendarMonth, contentDescription = null)
                    Text("Add to phone calendar", Modifier.padding(start = 8.dp))
                }
                OutlinedButton(onClick = { openDirections(context, event.location) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Icon(Icons.Default.Directions, contentDescription = null)
                    Text("Open directions", Modifier.padding(start = 8.dp))
                }
                OutlinedButton(onClick = { shareEvent(context, event) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Icon(Icons.Default.Share, contentDescription = null)
                    Text("Share event", Modifier.padding(start = 8.dp))
                }
            }
            TextButton(onClick = onReport, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                Text("Report incorrect information")
            }
            if (event.id < 0 && !event.isDemonstration) DemoContentNotice()
        }
    }
}

@Composable
fun DiscountsScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onProfile: () -> Unit,
    onOpen: (Long) -> Unit,
    onToggleSaved: (String, Long) -> Unit = { _, _ -> }
) {
    var category by rememberSaveable { mutableStateOf("All") }
    val categories = listOf("All") + state.discounts.map { it.category }.distinct()
    val filtered = state.discounts.filter { category == "All" || it.category == category }
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Senior Discounts", onProfile = onProfile)
        LazyColumn(contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            item { ScreenIntro("Save more every day", "Trusted savings for pensioners and community members aged 60+.") }
            item {
                Text("Browse by category", fontWeight = FontWeight.Bold, color = BkkNavy)
                CategoryFilterRow(categories, category, Modifier.padding(top = 8.dp)) { category = it }
            }
            if (state.discounts.any { it.id < 0 }) item { DemoContentNotice() }
            if (state.loading && filtered.isEmpty()) item { LoadingPane() }
            else if (filtered.isEmpty()) item { EmptyPane("No matching discounts", "Choose another category or check again later.") }
            else items(filtered, key = { it.id }) { discount ->
                DiscountCard(
                    discount,
                    { onOpen(discount.id) },
                    isSaved = discount.id in state.savedItems.discountIds,
                    onToggleSaved = { onToggleSaved("discount", discount.id) }
                )
            }
        }
    }
}

@Composable
fun DiscountDetailScreen(
    discount: Discount?,
    padding: PaddingValues,
    onBack: () -> Unit,
    loading: Boolean = false,
    isSaved: Boolean = false,
    onToggleSaved: () -> Unit = {},
    onReport: () -> Unit = {}
) {
    val context = LocalContext.current
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Discount Details", onBack = onBack)
        if (discount == null) {
            Box(Modifier.fillMaxSize().padding(20.dp), contentAlignment = Alignment.Center) {
                if (loading) LoadingPane("Loading discount details")
                else EmptyPane("Discount unavailable", "This offer may have expired or could not be loaded.")
            }
            return@Column
        }
        Column(Modifier.padding(22.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Surface(color = categoryColour(discount.category).copy(alpha = .14f), shape = RoundedCornerShape(18.dp)) {
                Text(discount.category, Modifier.padding(horizontal = 16.dp, vertical = 8.dp), color = categoryColour(discount.category), fontWeight = FontWeight.Bold)
            }
            Text(discount.storeName, style = MaterialTheme.typography.headlineLarge, color = BkkNavy)
            Text(discount.title, style = MaterialTheme.typography.titleLarge)
            Text(discount.details)
            HorizontalDivider()
            SectionTitle("Who qualifies?")
            Text(discount.eligibility)
            SectionTitle("How to claim")
            Text(discount.claimInstructions)
            discount.validUntil?.let { Text("Valid until ${formatLongDate(it)}", color = BkkMuted) }
            OutlinedButton(onClick = onToggleSaved, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                Icon(Icons.Default.Bookmark, contentDescription = null)
                Text(if (isSaved) "Remove from saved" else "Save discount", Modifier.padding(start = 8.dp))
            }
            OutlinedButton(onClick = { shareDiscount(context, discount) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                Icon(Icons.Default.Share, contentDescription = null)
                Text("Share discount", Modifier.padding(start = 8.dp))
            }
            TextButton(onClick = onReport, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                Text("Report expired or incorrect information")
            }
            if (discount.id < 0) DemoContentNotice()
        }
    }
}

@Composable
fun InfoScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onProfile: () -> Unit,
    onToggleSaved: (String, Long) -> Unit = { _, _ -> }
) {
    val context = LocalContext.current
    var type by rememberSaveable { mutableStateOf("All") }
    val types = listOf("All") + state.services.map { it.type.replaceFirstChar { char -> char.uppercase() } }.distinct()
    val filtered = state.services.filter { type == "All" || it.type.equals(type, true) }
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Local Information", onProfile = onProfile)
        LazyColumn(contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            item { ScreenIntro("Local help, made simple", "Clinics, pharmacies, shops and community support with the details you need.") }
            item {
                Text("Browse by service", fontWeight = FontWeight.Bold, color = BkkNavy)
                CategoryFilterRow(types, type, Modifier.padding(top = 8.dp)) { type = it }
            }
            if (state.services.any { it.id < 0 }) item { DemoContentNotice() }
            if (filtered.isEmpty()) item { EmptyPane("No services found", "Choose another category or check again later.") }
            else items(filtered, key = { it.id }) { service ->
                ServiceCard(
                    service,
                    onCall = { callPhone(context, service.phone) },
                    onDirections = { openDirections(context, service.address) },
                    isSaved = service.id in state.savedItems.serviceIds,
                    onToggleSaved = { onToggleSaved("service", service.id) }
                )
            }
        }
    }
}

@Composable
fun ContactScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onBack: () -> Unit,
    onSubmit: (String, String, String, () -> Unit) -> Unit
) {
    var name by rememberSaveable(state.member?.id) { mutableStateOf(state.member?.fullName.orEmpty()) }
    var email by rememberSaveable(state.member?.id) { mutableStateOf(state.member?.email.orEmpty()) }
    var message by rememberSaveable { mutableStateOf("") }
    var sent by rememberSaveable { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Contact BKK", onBack = onBack)
        Column(Modifier.padding(22.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Icon(Icons.Default.ContactMail, null, Modifier.size(52.dp), tint = BkkRed)
            SectionTitle("How can we help?")
            Text("Send a question about events, discounts or local services. We only collect the information needed to reply.")
            if (sent) Surface(color = BkkGreenSurface, shape = RoundedCornerShape(12.dp)) {
                Text("Thank you. Your message was sent successfully.", Modifier.padding(18.dp), color = BkkGreen, fontWeight = FontWeight.Bold)
            }
            OutlinedTextField(name, { name = it }, label = { Text("Full name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(email, { email = it }, label = { Text("Email address") }, singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next), modifier = Modifier.fillMaxWidth())
            OutlinedTextField(message, { if (it.length <= 3000) message = it }, label = { Text("Your message") },
                minLines = 5, supportingText = { Text("${message.length}/3000 characters") }, modifier = Modifier.fillMaxWidth())
            Button(
                onClick = { onSubmit(name, email, message) { sent = true; message = "" } },
                enabled = !state.working && ValidationRules.isContactValid(name, email, message),
                modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp)
            ) { Text(if (state.working) "Sending…" else "Submit enquiry") }
        }
    }
}

@Composable
fun MeScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onLogin: () -> Unit,
    onContact: () -> Unit,
    onNotifications: () -> Unit,
    onOpenInbox: () -> Unit,
    onOpenSchedule: () -> Unit,
    onOpenSaved: () -> Unit,
    onCallBkk: () -> Unit,
    onRefreshAttendance: () -> Unit,
    onUpdateProfile: (String, String, String?) -> Unit,
    onUpdatePreferences: (Boolean, Boolean, Boolean) -> Unit,
    onLogout: () -> Unit,
    onDelete: () -> Unit
) {
    val member = state.member
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar(
            "My Account",
            onNotifications = onOpenInbox,
            unreadCount = state.notices.count { !it.isRead }
        )
        if (member == null) {
            Column(Modifier.padding(22.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
                Icon(Icons.Default.Person, null, Modifier.size(72.dp), tint = BkkBlue)
                Text("Browse as a guest", style = MaterialTheme.typography.headlineMedium, color = BkkNavy)
                Text("You can view public information without an account. Sign in to confirm attendance and keep reminders synced.", textAlign = TextAlign.Center)
                Button(onClick = onLogin, modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp)) { Text("Log in or create an account") }
                OutlinedButton(onClick = onOpenSaved, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("View saved information") }
                OutlinedButton(onClick = onCallBkk, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Call BKK support") }
                OutlinedButton(onClick = onContact, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Contact BKK") }
            }
            return@Column
        }
        var name by rememberSaveable(member.id) { mutableStateOf(member.fullName) }
        var email by rememberSaveable(member.id) { mutableStateOf(member.email) }
        var phone by rememberSaveable(member.id) { mutableStateOf(member.phone.orEmpty()) }
        var notifications by rememberSaveable(member.id) { mutableStateOf(member.notificationsEnabled) }
        var reminders by rememberSaveable(member.id) { mutableStateOf(member.eventRemindersEnabled) }
        var discountAlerts by rememberSaveable(member.id) { mutableStateOf(member.discountAlertsEnabled) }
        var confirmDelete by rememberSaveable { mutableStateOf(false) }

        Column(Modifier.padding(22.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            SectionTitle("My community")
            Button(onClick = onOpenSchedule, modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp)) { Text("Open my schedule") }
            OutlinedButton(onClick = onOpenSaved, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Saved events, deals and services") }
            OutlinedButton(onClick = onOpenInbox, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                Text("Notification inbox${state.notices.count { !it.isRead }.takeIf { it > 0 }?.let { " ($it new)" }.orEmpty()}")
            }
            HorizontalDivider()
            SectionTitle("Profile")
            OutlinedTextField(name, { name = it }, label = { Text("Full name") }, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(email, { email = it }, label = { Text("Email") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email), modifier = Modifier.fillMaxWidth())
            OutlinedTextField(phone, { phone = it }, label = { Text("Phone number (optional)") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone), modifier = Modifier.fillMaxWidth())
            Button(onClick = { onUpdateProfile(name, email, phone) }, enabled = !state.working, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                Text("Save profile")
            }
            HorizontalDivider()
            SectionTitle("Attendance history")
            when {
                state.historyLoading -> Text("Loading your confirmed events…")
                state.attendanceHistory.isEmpty() -> Text("You have no confirmed events yet.")
                else -> state.attendanceHistory.forEach { event ->
                    Card(colors = CardDefaults.cardColors(containerColor = BkkLightBlue), modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(event.title, style = MaterialTheme.typography.titleMedium, color = BkkNavy)
                            Text("${formatLongDate(event.startAt)} at ${formatTime(event.startAt)}")
                            Text(event.location)
                        }
                    }
                }
            }
            OutlinedButton(onClick = onRefreshAttendance, enabled = !state.historyLoading,
                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Refresh attendance history") }
            HorizontalDivider()
            SectionTitle("Notifications")
            PreferenceRow("Allow notifications", "Master switch for BKK updates", notifications) {
                notifications = it
                if (it) onNotifications()
            }
            PreferenceRow("Event reminders", "Remind me before events I attend", reminders, notifications) { reminders = it }
            PreferenceRow("Discount alerts", "Tell me when new savings are added", discountAlerts, notifications) { discountAlerts = it }
            Button(onClick = { onUpdatePreferences(notifications, reminders, discountAlerts) }, enabled = !state.working,
                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Save notification settings") }
            HorizontalDivider()
            OutlinedButton(onClick = onCallBkk, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Call BKK support") }
            OutlinedButton(onClick = onContact, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Contact BKK") }
            OutlinedButton(onClick = onLogout, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Log out") }
            TextButton(onClick = { confirmDelete = true }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp), colors = ButtonDefaults.textButtonColors(contentColor = BkkRed)) {
                Text("Delete my account")
            }
        }
        if (confirmDelete) AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete your account?") },
            text = { Text("This permanently removes your account and attendance history. This cannot be undone.") },
            confirmButton = { TextButton(onClick = { confirmDelete = false; onDelete() }) { Text("Delete permanently", color = BkkRed) } },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Keep account") } }
        )
    }
}

@Composable
fun MyScheduleScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onBack: () -> Unit,
    onOpen: (Long) -> Unit,
    onAttendance: (CommunityEvent, Boolean) -> Unit,
    onRefresh: () -> Unit,
    onToggleSaved: (String, Long) -> Unit
) {
    val confirmed = (state.attendanceHistory + state.events.filter { it.isAttending }).distinctBy { it.id }
    val now = Instant.now()
    val upcoming = confirmed.filter { runCatching { Instant.parse(it.endAt).isAfter(now) }.getOrDefault(true) }
        .sortedBy { it.startAt }
    val past = confirmed.filterNot { it in upcoming }.sortedByDescending { it.startAt }
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("My Schedule", onBack = onBack)
        LazyColumn(contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            item { ScreenIntro("Your plans in one place", "Review upcoming events, cancel attendance or adjust your phone calendar.") }
            if (state.historyLoading) item { LoadingPane("Loading your schedule") }
            if (!state.historyLoading && confirmed.isEmpty()) {
                item { EmptyPane("No confirmed events", "Choose an event and tap ‘I will attend’ to add it here.") }
            }
            if (upcoming.isNotEmpty()) item { SectionTitle("Coming up") }
            items(upcoming, key = { "upcoming-${it.id}" }) { event ->
                EventCard(
                    event,
                    { onOpen(event.id) },
                    { onAttendance(event, it) },
                    isSaved = event.id in state.savedItems.eventIds,
                    onToggleSaved = { onToggleSaved("event", event.id) }
                )
            }
            if (past.isNotEmpty()) item { SectionTitle("Past events") }
            items(past, key = { "past-${it.id}" }) { event ->
                Card(colors = CardDefaults.cardColors(containerColor = BkkLightBlue), modifier = Modifier.fillMaxWidth().clickable { onOpen(event.id) }) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(event.title, style = MaterialTheme.typography.titleMedium, color = BkkNavy)
                        Text("${formatLongDate(event.startAt)} at ${formatTime(event.startAt)}")
                        Text(event.location)
                    }
                }
            }
            item {
                OutlinedButton(onClick = onRefresh, enabled = !state.historyLoading, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Text("Refresh my schedule")
                }
            }
        }
    }
}

@Composable
fun SavedItemsScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onBack: () -> Unit,
    onOpenEvent: (Long) -> Unit,
    onOpenDiscount: (Long) -> Unit,
    onAttendance: (CommunityEvent, Boolean) -> Unit,
    onToggleSaved: (String, Long) -> Unit
) {
    val context = LocalContext.current
    val savedEvents = state.events.filter { it.id in state.savedItems.eventIds }
    val savedDiscounts = state.discounts.filter { it.id in state.savedItems.discountIds }
    val savedServices = state.services.filter { it.id in state.savedItems.serviceIds }
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Saved Information", onBack = onBack)
        LazyColumn(contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            item { ScreenIntro("Easy to find again", "Saved information stays available when your connection is unreliable.") }
            if (savedEvents.isEmpty() && savedDiscounts.isEmpty() && savedServices.isEmpty()) {
                item { EmptyPane("Nothing saved yet", "Use the bookmark button on an event, discount or local service.") }
            }
            if (savedEvents.isNotEmpty()) item { SectionTitle("Events") }
            items(savedEvents, key = { "saved-event-${it.id}" }) { event ->
                EventCard(event, { onOpenEvent(event.id) }, { onAttendance(event, it) }, isSaved = true,
                    onToggleSaved = { onToggleSaved("event", event.id) })
            }
            if (savedDiscounts.isNotEmpty()) item { SectionTitle("Discounts") }
            items(savedDiscounts, key = { "saved-discount-${it.id}" }) { discount ->
                DiscountCard(discount, { onOpenDiscount(discount.id) }, isSaved = true,
                    onToggleSaved = { onToggleSaved("discount", discount.id) })
            }
            if (savedServices.isNotEmpty()) item { SectionTitle("Local services") }
            items(savedServices, key = { "saved-service-${it.id}" }) { service ->
                ServiceCard(
                    service,
                    onCall = { callPhone(context, service.phone) },
                    onDirections = { openDirections(context, service.address) },
                    isSaved = true,
                    onToggleSaved = { onToggleSaved("service", service.id) }
                )
            }
        }
    }
}

@Composable
fun NotificationInboxScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onBack: () -> Unit,
    onOpen: (CommunityNotice) -> Unit,
    onClear: () -> Unit
) {
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("Notifications", onBack = onBack)
        LazyColumn(contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            item { ScreenIntro("Community updates", "Event reminders and new savings remain here after the phone notification is dismissed.") }
            if (state.notices.isEmpty()) item { EmptyPane("No notifications yet", "New BKK reminders and discount alerts will appear here.") }
            items(state.notices, key = { it.id }) { notice ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = if (notice.isRead) Color.White else BkkLightBlue),
                    border = androidx.compose.foundation.BorderStroke(1.dp, BkkLine),
                    modifier = Modifier.fillMaxWidth().clickable { onOpen(notice) }
                ) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(notice.title, style = MaterialTheme.typography.titleMedium, color = BkkNavy)
                        Text(notice.body)
                        Text(formatNoticeTime(notice.receivedAt), style = MaterialTheme.typography.bodyMedium, color = BkkMuted)
                        if (!notice.isRead) Text("NEW", color = BkkBlue, fontWeight = FontWeight.Bold)
                    }
                }
            }
            if (state.notices.isNotEmpty()) item {
                TextButton(onClick = onClear, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("Clear notification history") }
            }
        }
    }
}

@Composable
fun LoginScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onLogin: (String, String) -> Unit,
    onRegister: () -> Unit,
    onForgot: () -> Unit
) {
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var passwordVisible by rememberSaveable { mutableStateOf(false) }
    val validEmail = ValidationRules.isEmail(email.trim())
    val canSubmit = validEmail && password.isNotEmpty() && !state.working
    val fieldColors = OutlinedTextFieldDefaults.colors(
        focusedBorderColor = BkkBlue,
        unfocusedBorderColor = BkkLine,
        focusedLabelColor = BkkNavy,
        cursorColor = BkkBlue,
        focusedContainerColor = Color.White,
        unfocusedContainerColor = Color.White
    )

    Column(
        Modifier.fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(bottom = padding.calculateBottomPadding())
    ) {
        BkkTopBar("BKK Community")
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 32.dp)
        ) {
            item {
                Box(
                    Modifier.fillMaxWidth().background(
                        Brush.verticalGradient(listOf(BkkNavy, BkkDeepNavy))
                    )
                ) {
                    Column(
                        Modifier.fillMaxWidth().padding(start = 22.dp, top = 22.dp, end = 22.dp, bottom = 48.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Surface(
                            color = Color.White.copy(alpha = .14f),
                            shape = RoundedCornerShape(22.dp),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = .22f))
                        ) {
                            Icon(
                                Icons.Default.Person,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.padding(15.dp).size(34.dp)
                            )
                        }
                        Text(
                            "Welcome back",
                            style = MaterialTheme.typography.headlineLarge,
                            color = Color.White,
                            textAlign = TextAlign.Center
                        )
                        Text(
                            "Sign in to your BKK Community account",
                            style = MaterialTheme.typography.bodyLarge,
                            color = Color.White.copy(alpha = .88f),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    shape = RoundedCornerShape(28.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, BkkLine),
                    elevation = CardDefaults.cardElevation(defaultElevation = 7.dp),
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 18.dp)
                ) {
                    Column(
                        Modifier.padding(horizontal = 20.dp, vertical = 24.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                            Text("Account sign in", style = MaterialTheme.typography.titleLarge, color = BkkNavy)
                            Text(
                                "Use the email address you registered with.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = BkkMuted
                            )
                        }

                        OutlinedTextField(
                            value = email,
                            onValueChange = { email = it },
                            label = { Text("Email address") },
                            placeholder = { Text("name@example.com") },
                            leadingIcon = { Icon(Icons.Default.Email, contentDescription = null, tint = BkkBlue) },
                            singleLine = true,
                            isError = email.isNotBlank() && !validEmail,
                            supportingText = {
                                if (email.isNotBlank() && !validEmail) Text("Enter a valid email address")
                            },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next),
                            shape = RoundedCornerShape(16.dp),
                            colors = fieldColors,
                            modifier = Modifier.fillMaxWidth().heightIn(min = 64.dp)
                        )
                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it },
                            label = { Text("Password") },
                            leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, tint = BkkBlue) },
                            trailingIcon = {
                                IconButton(
                                    onClick = { passwordVisible = !passwordVisible },
                                    modifier = Modifier.semantics {
                                        contentDescription = if (passwordVisible) "Hide password" else "Show password"
                                    }
                                ) {
                                    Icon(
                                        if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                        contentDescription = null,
                                        tint = BkkMuted
                                    )
                                }
                            },
                            singleLine = true,
                            visualTransformation = if (passwordVisible) androidx.compose.ui.text.input.VisualTransformation.None else PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                            shape = RoundedCornerShape(16.dp),
                            colors = fieldColors,
                            modifier = Modifier.fillMaxWidth().heightIn(min = 64.dp)
                        )

                        TextButton(
                            onClick = onForgot,
                            modifier = Modifier.align(Alignment.End).heightIn(min = 48.dp)
                        ) {
                            Text("Forgot your password?", color = BkkBlue)
                        }

                        Button(
                            onClick = { onLogin(email.trim(), password) },
                            enabled = canSubmit,
                            shape = RoundedCornerShape(17.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = BkkBlue),
                            modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp)
                        ) {
                            if (state.working) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(24.dp),
                                    color = Color.White,
                                    strokeWidth = 3.dp
                                )
                                Text("Signing in…", Modifier.padding(start = 12.dp))
                            } else {
                                Text("Sign In")
                                Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, Modifier.padding(start = 10.dp))
                            }
                        }

                        Row(
                            Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            HorizontalDivider(Modifier.weight(1f), color = BkkLine)
                            Text("NEW TO BKK?", style = MaterialTheme.typography.labelMedium, color = BkkMuted)
                            HorizontalDivider(Modifier.weight(1f), color = BkkLine)
                        }
                        OutlinedButton(
                            onClick = onRegister,
                            shape = RoundedCornerShape(17.dp),
                            border = androidx.compose.foundation.BorderStroke(1.5.dp, BkkBlue),
                            modifier = Modifier.fillMaxWidth().heightIn(min = 58.dp)
                        ) {
                            Text("Create an Account", color = BkkNavy)
                        }
                    }
                }
            }
            item {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 30.dp, vertical = 18.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(Icons.Default.Shield, contentDescription = null, tint = BkkGreen, modifier = Modifier.size(22.dp))
                    Text(
                        "Secure sign-in. Your password is never stored on this device.",
                        Modifier.padding(start = 9.dp),
                        style = MaterialTheme.typography.bodyMedium,
                        color = BkkMuted,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
fun RegisterScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onBack: () -> Unit,
    onRegister: (String, String, String?, String, () -> Unit) -> Unit
) {
    var name by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    var phone by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var confirm by rememberSaveable { mutableStateOf("") }
    var privacy by rememberSaveable { mutableStateOf(false) }
    AuthFrame("Create an Account", "Register to RSVP for events and receive reminders.", padding, onBack) {
        OutlinedTextField(name, { name = it }, label = { Text("Full name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(email, { email = it }, label = { Text("Email address") }, singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email), modifier = Modifier.fillMaxWidth())
        OutlinedTextField(phone, { phone = it }, label = { Text("Phone number (optional)") }, singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone), modifier = Modifier.fillMaxWidth())
        OutlinedTextField(password, { password = it }, label = { Text("Password — at least 8 characters") }, singleLine = true,
            visualTransformation = PasswordVisualTransformation(), modifier = Modifier.fillMaxWidth())
        OutlinedTextField(confirm, { confirm = it }, label = { Text("Confirm password") }, singleLine = true,
            visualTransformation = PasswordVisualTransformation(), isError = confirm.isNotEmpty() && confirm != password, modifier = Modifier.fillMaxWidth())
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(privacy, { privacy = it })
            Text("I understand that BKK stores my details only for attendance and reminders.", Modifier.weight(1f))
        }
        Button(onClick = { onRegister(name, email, phone, password, onBack) },
            enabled = !state.working && ValidationRules.isRegistrationValid(name, email, password, confirm, privacy),
            modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp)) { Text(if (state.working) "Creating account…" else "Create Account") }
    }
}

@Composable
fun ForgotPasswordScreen(
    state: BkkUiState,
    padding: PaddingValues,
    onBack: () -> Unit,
    onSubmit: (String) -> Unit
) {
    var email by rememberSaveable { mutableStateOf("") }
    AuthFrame("Reset Your Password", "Enter your email address to request a 6-digit reset code.", padding, onBack) {
        Icon(Icons.Default.LockReset, null, Modifier.align(Alignment.CenterHorizontally).size(52.dp), tint = BkkBlue)
        OutlinedTextField(email, { email = it }, label = { Text("Email address") }, singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email), modifier = Modifier.fillMaxWidth())
        Button(onClick = { onSubmit(email) }, enabled = !state.working && ValidationRules.isEmail(email),
            modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp)) { Text("Get 6-Digit Reset Code") }
    }
}

@Composable
fun ResetPasswordScreen(
    state: BkkUiState,
    padding: PaddingValues,
    email: String,
    onBack: () -> Unit,
    onSubmit: (String, String, String) -> Unit
) {
    var code by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var confirmation by rememberSaveable { mutableStateOf("") }
    AuthFrame("Reset Your Password", "Enter your 6-digit reset code and choose a new password.", padding, onBack) {
        Icon(Icons.Default.LockReset, null, Modifier.align(Alignment.CenterHorizontally).size(52.dp), tint = BkkBlue)
        OutlinedTextField(email, {}, readOnly = true, label = { Text("Account email") },
            singleLine = true, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(code, { value -> code = value.filter(Char::isDigit).take(6) }, label = { Text("6-Digit Reset Code (e.g. 123456)") },
            singleLine = true, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number), modifier = Modifier.fillMaxWidth())
        OutlinedTextField(password, { password = it }, label = { Text("New password — at least 8 characters") },
            singleLine = true, visualTransformation = PasswordVisualTransformation(), modifier = Modifier.fillMaxWidth())
        OutlinedTextField(confirmation, { confirmation = it }, label = { Text("Confirm new password") },
            singleLine = true, visualTransformation = PasswordVisualTransformation(),
            isError = confirmation.isNotEmpty() && confirmation != password, modifier = Modifier.fillMaxWidth())
        Button(onClick = { onSubmit(email, code, password) },
            enabled = !state.working && code.length == 6 &&
                ValidationRules.isPassword(password) && password == confirmation,
            modifier = Modifier.fillMaxWidth().heightIn(min = 60.dp)) {
            Text(if (state.working) "Updating password…" else "Update Password")
        }
    }
}

@Composable
private fun AuthFrame(title: String, subtitle: String, padding: PaddingValues, onBack: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(Modifier.fillMaxSize().padding(bottom = padding.calculateBottomPadding())) {
        BkkTopBar("BKK Community", onBack = onBack)
        Column(Modifier.fillMaxSize().padding(22.dp).verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally) {
            Card(colors = CardDefaults.cardColors(containerColor = Color.White), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text(title, style = MaterialTheme.typography.headlineMedium, color = BkkNavy, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
                    Text(subtitle, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
                    content()
                }
            }
        }
    }
}

@Composable
private fun PreferenceRow(title: String, subtitle: String, checked: Boolean, enabled: Boolean = true, onChecked: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().heightIn(min = 72.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(subtitle, style = MaterialTheme.typography.bodyMedium)
        }
        Switch(checked, onChecked, enabled = enabled)
    }
}

@Composable
private fun DetailLine(icon: ImageVector, text: String) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Icon(icon, contentDescription = null, tint = BkkBlue, modifier = Modifier.size(26.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
private fun ScreenIntro(title: String, subtitle: String) {
    Card(
        colors = CardDefaults.cardColors(containerColor = BkkWarmSurface),
        border = androidx.compose.foundation.BorderStroke(1.dp, BkkLine),
        shape = RoundedCornerShape(24.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("BKK COMMUNITY", style = MaterialTheme.typography.labelMedium, color = BkkGold, fontWeight = FontWeight.Bold)
            Text(title, style = MaterialTheme.typography.headlineMedium, color = BkkNavy)
            Text(subtitle, style = MaterialTheme.typography.bodyLarge, color = BkkMuted)
        }
    }
}

@Composable
private fun CategoryFilterRow(
    items: List<String>,
    selected: String,
    modifier: Modifier = Modifier,
    onSelected: (String) -> Unit
) {
    Row(
        modifier = modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items.forEach { item ->
            FilterChip(
                selected = selected == item,
                onClick = { onSelected(item) },
                label = { Text(item) },
                shape = RoundedCornerShape(14.dp)
            )
        }
    }
}

@Composable
private fun DataFreshnessNotice(lastUpdated: Long?, isDemo: Boolean, warning: String?) {
    val text = when {
        !warning.isNullOrBlank() -> warning
        isDemo -> "Demonstration information is shown until the BKK server is connected."
        lastUpdated != null -> {
            val updated = Instant.ofEpochMilli(lastUpdated).atZone(ZoneId.of("Africa/Johannesburg"))
                .format(DateTimeFormatter.ofPattern("d MMM yyyy 'at' HH:mm"))
            "Information last updated $updated."
        }
        else -> "Saved information is available. Pull fresh information when you are connected."
    }
    Surface(
        color = BkkLightBlue,
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 4.dp)
    ) {
        Text(text, Modifier.padding(14.dp), color = BkkNavy, style = MaterialTheme.typography.bodyMedium)
    }
}

private fun isToday(event: CommunityEvent): Boolean = runCatching {
    Instant.parse(event.startAt).atZone(ZoneId.of("Africa/Johannesburg")).toLocalDate() == LocalDate.now(ZoneId.of("Africa/Johannesburg"))
}.getOrDefault(false)

fun greetingForHour(hour: Int): String = when (hour.coerceIn(0, 23)) {
    in 5..11 -> "Good morning"
    in 12..17 -> "Good afternoon"
    else -> "Good evening"
}

fun eventMatchesPeriod(event: CommunityEvent, period: String, today: LocalDate = LocalDate.now(ZoneId.of("Africa/Johannesburg"))): Boolean {
    val date = runCatching { Instant.parse(event.startAt).atZone(ZoneId.of("Africa/Johannesburg")).toLocalDate() }.getOrNull()
        ?: return period == "All"
    return when (period) {
        "Today" -> date == today
        "This week" -> !date.isBefore(today) && !date.isAfter(today.plusDays(6))
        "Later" -> date.isAfter(today.plusDays(6))
        else -> true
    }
}

private fun addEventToCalendar(context: Context, event: CommunityEvent) {
    val start = runCatching { Instant.parse(event.startAt).toEpochMilli() }.getOrNull() ?: return
    val end = runCatching { Instant.parse(event.endAt).toEpochMilli() }.getOrNull() ?: return
    val intent = Intent(Intent.ACTION_INSERT).setData(CalendarContract.Events.CONTENT_URI)
        .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
        .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
        .putExtra(CalendarContract.Events.TITLE, event.title)
        .putExtra(CalendarContract.Events.DESCRIPTION, event.description)
        .putExtra(CalendarContract.Events.EVENT_LOCATION, event.location)
    runCatching { context.startActivity(intent) }
}

private fun openDirections(context: Context, place: String) {
    val geoIntent = Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=${Uri.encode(place)}"))
    val fallback = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encode(place)}"))
    runCatching { context.startActivity(geoIntent) }.recoverCatching { context.startActivity(fallback) }
}

private fun callPhone(context: Context, phone: String) {
    val safePhone = phone.filter { it.isDigit() || it == '+' }
    runCatching { context.startActivity(Intent(Intent.ACTION_DIAL, "tel:$safePhone".toUri())) }
}

private fun shareEvent(context: Context, event: CommunityEvent) {
    val text = buildString {
        append(event.title)
        append("\n${formatLongDate(event.startAt)} at ${formatTime(event.startAt)}")
        append("\n${event.location}")
        event.directions?.let { append("\nDirections: $it") }
    }
    shareText(context, "Share BKK event", text)
}

private fun shareDiscount(context: Context, discount: Discount) {
    val text = buildString {
        append("${discount.storeName}: ${discount.title}")
        append("\n${discount.details}")
        append("\nWho qualifies: ${discount.eligibility}")
        append("\nHow to claim: ${discount.claimInstructions}")
    }
    shareText(context, "Share BKK discount", text)
}

private fun shareText(context: Context, chooserTitle: String, text: String) {
    val intent = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
    runCatching { context.startActivity(Intent.createChooser(intent, chooserTitle)) }
}

private fun formatNoticeTime(epochMillis: Long): String = runCatching {
    Instant.ofEpochMilli(epochMillis).atZone(ZoneId.of("Africa/Johannesburg"))
        .format(DateTimeFormatter.ofPattern("d MMM yyyy 'at' HH:mm"))
}.getOrDefault("Recently")
