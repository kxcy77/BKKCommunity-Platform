package za.co.bkkcommunity.app.notification

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import za.co.bkkcommunity.app.BkkApplication
import za.co.bkkcommunity.app.MainActivity
import za.co.bkkcommunity.app.R
import za.co.bkkcommunity.app.model.CommunityNotice

class BkkMessagingService : FirebaseMessagingService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        val repository = (application as BkkApplication).container.repository
        scope.launch { repository.registerDevice(token) }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        val type = message.data["type"]
        val id = message.data[if (type == "event") "event_id" else "discount_id"]
        val title = message.notification?.title ?: "BKK Community update"
        val body = message.notification?.body ?: "Open the app for details."
        scope.launch {
            (application as BkkApplication).container.featureStore.addNotice(
                CommunityNotice(
                    id = message.messageId ?: "${System.currentTimeMillis()}-${type.orEmpty()}-${id.orEmpty()}",
                    title = title,
                    body = body,
                    type = type ?: "general",
                    itemId = id?.toLongOrNull(),
                    receivedAt = System.currentTimeMillis(),
                    isRead = false
                )
            )
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED) return
        val destination = when (type) {
            "event" -> id?.let { "bkk://event/$it" }
            "discount" -> id?.let { "bkk://discount/$it" }
            else -> null
        }
        val intent = destination?.let { Intent(Intent.ACTION_VIEW, it.toUri(), this, MainActivity::class.java) }
            ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            id?.toIntOrNull() ?: 0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, "bkk_updates")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        getSystemService(NotificationManager::class.java).notify(message.messageId?.hashCode() ?: 1, notification)
    }
}
