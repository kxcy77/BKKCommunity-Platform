package za.co.bkkcommunity.app.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import za.co.bkkcommunity.app.data.ContentSection
import za.co.bkkcommunity.app.data.ContentSyncStatus
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun ContentSyncBanner(statuses: Map<ContentSection, ContentSyncStatus>, sections: List<ContentSection>, busy: Boolean, onRefresh: () -> Unit) {
    Surface(color = MaterialTheme.colorScheme.surfaceVariant) {
        Column(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 16.dp, vertical = 4.dp)) {
            sections.forEach { section ->
                val status = statuses[section]
                val updated = status?.lastUpdated?.let {
                    Instant.ofEpochMilli(it).atZone(ZoneId.of("Africa/Johannesburg"))
                        .format(DateTimeFormatter.ofPattern("d MMM, HH:mm:ss"))
                }
                Text(
                    "${section.label}: ${updated?.let { "updated $it" } ?: "waiting for a server update"}" +
                        if (status?.warning != null) ". Cannot update now; showing saved information." else "",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            TextButton(onClick = onRefresh, enabled = !busy) {
                Text(if (sections.any { statuses[it]?.warning != null }) "Retry update" else "Refresh information")
            }
        }
    }
}
