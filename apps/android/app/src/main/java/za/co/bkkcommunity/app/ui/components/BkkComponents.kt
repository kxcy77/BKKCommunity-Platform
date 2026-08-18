package za.co.bkkcommunity.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.LocalOffer
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import za.co.bkkcommunity.app.model.CommunityEvent
import za.co.bkkcommunity.app.model.Discount
import za.co.bkkcommunity.app.model.LocalService
import za.co.bkkcommunity.app.ui.theme.BkkBlue
import za.co.bkkcommunity.app.ui.theme.BkkDeepNavy
import za.co.bkkcommunity.app.ui.theme.BkkGold
import za.co.bkkcommunity.app.ui.theme.BkkGoldSurface
import za.co.bkkcommunity.app.ui.theme.BkkGreen
import za.co.bkkcommunity.app.ui.theme.BkkLightBlue
import za.co.bkkcommunity.app.ui.theme.BkkLine
import za.co.bkkcommunity.app.ui.theme.BkkMuted
import za.co.bkkcommunity.app.ui.theme.BkkNavy
import za.co.bkkcommunity.app.ui.theme.BkkSky
import za.co.bkkcommunity.app.ui.theme.BkkTeal
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun BkkTopBar(
    title: String,
    onBack: (() -> Unit)? = null,
    onProfile: (() -> Unit)? = null,
    onNotifications: (() -> Unit)? = null,
    unreadCount: Int = 0
) {
    Box(
        modifier = Modifier.fillMaxWidth().background(
            Brush.horizontalGradient(listOf(BkkDeepNavy, BkkNavy, BkkBlue))
        )
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().heightIn(min = 82.dp).padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (onBack != null) {
                IconButton(onClick = onBack, modifier = Modifier.size(56.dp)) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Go back", tint = Color.White)
                }
            } else {
                Surface(shape = RoundedCornerShape(14.dp), color = Color.White.copy(alpha = .16f), contentColor = Color.White) {
                    Icon(Icons.Default.Groups, contentDescription = null, modifier = Modifier.padding(11.dp).size(28.dp))
                }
                Spacer(Modifier.width(12.dp))
            }
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.weight(1f),
                color = Color.White
            )
            if (onNotifications != null) {
                IconButton(onClick = onNotifications, modifier = Modifier.size(52.dp)) {
                    BadgedBox(badge = {
                        if (unreadCount > 0) Badge { Text(if (unreadCount > 9) "9+" else unreadCount.toString()) }
                    }) {
                        Icon(Icons.Default.Notifications, contentDescription = "Open notifications", tint = Color.White)
                    }
                }
            }
            if (onProfile != null) {
                Surface(shape = CircleShape, color = Color.White.copy(alpha = .14f)) {
                    IconButton(onClick = onProfile, modifier = Modifier.size(52.dp)) {
                        Icon(Icons.Default.AccountCircle, contentDescription = "Open my account", tint = Color.White)
                    }
                }
            } else if (onNotifications == null) {
                Spacer(Modifier.size(56.dp))
            }
        }
    }
}

@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Row(modifier.semantics { heading() }, verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(5.dp).height(28.dp).background(BkkGold, RoundedCornerShape(4.dp)))
        Text(text, style = MaterialTheme.typography.titleLarge, color = BkkNavy, modifier = Modifier.padding(start = 10.dp))
    }
}

@Composable
fun DemoContentNotice(modifier: Modifier = Modifier) {
    Card(
        colors = CardDefaults.cardColors(containerColor = BkkGoldSurface),
        border = BorderStroke(1.dp, BkkGold.copy(alpha = .28f)),
        shape = RoundedCornerShape(18.dp),
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = CircleShape, color = BkkGold.copy(alpha = .14f)) {
                Icon(Icons.Default.CloudOff, contentDescription = null, tint = Color(0xFF6A4000), modifier = Modifier.padding(10.dp))
            }
            Text(
                "Demo information — connect the BKK server for live updates.",
                Modifier.padding(start = 12.dp), color = Color(0xFF5E3900), style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

@Composable
fun LoadingPane(label: String = "Loading information") {
    Box(Modifier.fillMaxWidth().padding(48.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            CircularProgressIndicator()
            Text(label)
        }
    }
}

@Composable
fun EmptyPane(title: String, message: String) {
    Card(
        colors = CardDefaults.cardColors(containerColor = BkkSky),
        shape = RoundedCornerShape(20.dp),
        border = BorderStroke(1.dp, BkkLine),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium, color = BkkNavy)
            Text(message)
        }
    }
}

@Composable
fun ActionTile(
    title: String,
    subtitle: String,
    icon: ImageVector,
    colour: Color,
    surface: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.heightIn(min = 154.dp).clickable(role = Role.Button, onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = surface),
        border = BorderStroke(1.dp, colour.copy(alpha = .28f)),
        shape = RoundedCornerShape(24.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp, pressedElevation = 1.dp)
    ) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Surface(shape = RoundedCornerShape(16.dp), color = colour, contentColor = Color.White) {
                    Icon(icon, contentDescription = null, modifier = Modifier.padding(12.dp).size(28.dp))
                }
                Spacer(Modifier.weight(1f))
                Surface(shape = CircleShape, color = Color.White.copy(alpha = .68f)) {
                    Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, tint = colour, modifier = Modifier.padding(8.dp).size(20.dp))
                }
            }
            Text(title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = BkkMuted, maxLines = 2, overflow = TextOverflow.Ellipsis)
        }
    }
}

@Composable
fun EventCard(
    event: CommunityEvent,
    onOpen: () -> Unit,
    onAttendance: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    isSaved: Boolean = false,
    onToggleSaved: (() -> Unit)? = null
) {
    val date = formatDate(event.startAt)
    val time = formatTime(event.startAt)
    val endTime = formatTime(event.endAt)
    val colour = parseColour(event.colourHex, BkkBlue)
    Card(
        modifier = modifier.fillMaxWidth().clickable(role = Role.Button, onClick = onOpen),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, BkkLine),
        shape = RoundedCornerShape(24.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp, pressedElevation = 1.dp)
    ) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Surface(color = colour, contentColor = Color.White, shape = RoundedCornerShape(18.dp)) {
                    Column(Modifier.padding(horizontal = 14.dp, vertical = 12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(date.first.uppercase(), fontWeight = FontWeight.ExtraBold)
                        Text(date.second, style = MaterialTheme.typography.labelMedium)
                    }
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                    Text(event.title, style = MaterialTheme.typography.titleMedium)
                    Surface(color = colour.copy(alpha = .12f), shape = RoundedCornerShape(12.dp)) {
                        Text(event.category, Modifier.padding(horizontal = 10.dp, vertical = 5.dp), color = colour, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelMedium)
                    }
                }
                if (onToggleSaved != null) {
                    IconButton(onClick = onToggleSaved, modifier = Modifier.size(48.dp)) {
                        Icon(
                            if (isSaved) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                            contentDescription = if (isSaved) "Remove saved event" else "Save event",
                            tint = BkkBlue
                        )
                    }
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Schedule, null, Modifier.size(22.dp), tint = BkkNavy)
                Text("$time – $endTime", Modifier.padding(start = 8.dp), style = MaterialTheme.typography.bodyMedium)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.LocationOn, null, Modifier.size(22.dp), tint = BkkNavy)
                Text(event.location, Modifier.padding(start = 8.dp), style = MaterialTheme.typography.bodyMedium)
            }
            HorizontalDivider(color = BkkLine)
            if (event.isDemonstration) {
                Surface(color = BkkGoldSurface, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Demonstration only", fontWeight = FontWeight.Bold, color = Color(0xFF5E3900))
                        Text("Attendance is unavailable for this test event.", color = Color(0xFF5E3900))
                    }
                }
            } else {
                Button(
                    onClick = { onAttendance(!event.isAttending) },
                    modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = if (event.isAttending) BkkGreen else BkkBlue)
                ) {
                    Text(if (event.isAttending) "Attending ✓" else "I will attend")
                }
            }
        }
    }
}

@Composable
fun DiscountCard(
    discount: Discount,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isSaved: Boolean = false,
    onToggleSaved: (() -> Unit)? = null
) {
    Card(
        modifier = modifier.fillMaxWidth().clickable(role = Role.Button, onClick = onClick),
        border = BorderStroke(1.dp, BkkLine),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        shape = RoundedCornerShape(22.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp, pressedElevation = 1.dp)
    ) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Surface(shape = RoundedCornerShape(14.dp), color = categoryColour(discount.category).copy(alpha = .13f)) {
                    Icon(Icons.Default.LocalOffer, null, tint = categoryColour(discount.category), modifier = Modifier.padding(10.dp).size(24.dp))
                }
                Text(discount.storeName, style = MaterialTheme.typography.titleLarge, modifier = Modifier.weight(1f).padding(start = 12.dp))
                if (onToggleSaved != null) {
                    IconButton(onClick = onToggleSaved, modifier = Modifier.size(48.dp)) {
                        Icon(
                            if (isSaved) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                            contentDescription = if (isSaved) "Remove saved discount" else "Save discount",
                            tint = BkkBlue
                        )
                    }
                }
                Surface(color = categoryColour(discount.category).copy(alpha = .14f), shape = RoundedCornerShape(18.dp)) {
                    Text(discount.category, Modifier.padding(horizontal = 12.dp, vertical = 6.dp), color = categoryColour(discount.category), fontWeight = FontWeight.Bold)
                }
            }
            Text(discount.title, style = MaterialTheme.typography.titleMedium)
            Text(discount.details, color = BkkMuted, maxLines = 3, overflow = TextOverflow.Ellipsis)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
                Text("View details", color = BkkBlue, fontWeight = FontWeight.Bold)
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = BkkBlue)
            }
        }
    }
}

@Composable
fun ServiceCard(
    service: LocalService,
    onCall: () -> Unit,
    modifier: Modifier = Modifier,
    onDirections: (() -> Unit)? = null,
    isSaved: Boolean = false,
    onToggleSaved: (() -> Unit)? = null
) {
    Card(
        modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, BkkLine),
        shape = RoundedCornerShape(22.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(service.type.replaceFirstChar { it.uppercase() }, color = BkkTeal, fontWeight = FontWeight.Bold)
                    Text(service.name, style = MaterialTheme.typography.titleLarge)
                }
                if (onToggleSaved != null) {
                    IconButton(onClick = onToggleSaved, modifier = Modifier.size(48.dp)) {
                        Icon(
                            if (isSaved) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                            contentDescription = if (isSaved) "Remove saved service" else "Save service",
                            tint = BkkTeal
                        )
                    }
                }
            }
            Row(verticalAlignment = Alignment.Top) {
                Icon(Icons.Default.LocationOn, null, Modifier.size(22.dp), tint = BkkNavy)
                Text(service.address, Modifier.padding(start = 8.dp))
            }
            service.openingHours?.let {
                Row(verticalAlignment = Alignment.Top) {
                    Icon(Icons.Default.Schedule, null, Modifier.size(22.dp), tint = BkkNavy)
                    Text(it, Modifier.padding(start = 8.dp))
                }
            }
            OutlinedButton(onClick = onCall, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                Text("Call ${service.phone}")
            }
            val context = androidx.compose.ui.platform.LocalContext.current
            OutlinedButton(
                onClick = {
                    val rawDigits = service.phone.filter { it.isDigit() }
                    val safePhone = if (rawDigits.startsWith("0")) "27" + rawDigits.drop(1) else rawDigits
                    val text = android.net.Uri.encode("Hello ${service.name}, I am inquiring via BKK Community app.")
                    runCatching { context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("https://wa.me/$safePhone?text=$text"))) }
                },
                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
            ) {
                Text("Chat on WhatsApp")
            }
            if (onDirections != null) {
                OutlinedButton(onClick = onDirections, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Text("Open directions")
                }
            }
        }
    }
}

fun formatDate(iso: String): Pair<String, String> = runCatching {
    val local = Instant.parse(iso).atZone(ZoneId.of("Africa/Johannesburg"))
    local.format(DateTimeFormatter.ofPattern("dd MMM")) to local.format(DateTimeFormatter.ofPattern("EEE"))
}.getOrDefault("Date" to "")

fun formatLongDate(iso: String): String = runCatching {
    Instant.parse(iso).atZone(ZoneId.of("Africa/Johannesburg"))
        .format(DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy"))
}.getOrDefault(iso)

fun formatTime(iso: String): String = runCatching {
    Instant.parse(iso).atZone(ZoneId.of("Africa/Johannesburg")).format(DateTimeFormatter.ofPattern("HH:mm"))
}.getOrDefault("--:--")

fun parseColour(hex: String, fallback: Color): Color = runCatching { Color(hex.toColorInt()) }.getOrDefault(fallback)

fun categoryColour(category: String): Color = when (category.lowercase()) {
    "pharmacy", "social" -> BkkBlue
    "grocery", "exercise" -> BkkGreen
    "restaurant", "health" -> Color(0xFFB00020)
    else -> Color(0xFF8A5500)
}
