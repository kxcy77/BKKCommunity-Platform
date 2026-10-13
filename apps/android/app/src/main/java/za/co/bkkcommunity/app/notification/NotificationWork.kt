package za.co.bkkcommunity.app.notification

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import androidx.work.*
import kotlinx.coroutines.flow.first
import za.co.bkkcommunity.app.BkkApplication
import za.co.bkkcommunity.app.MainActivity
import za.co.bkkcommunity.app.R
import za.co.bkkcommunity.app.model.CommunityNotice

object NotificationWork {
    const val PUSH_TAG = "bkk-cloud-notices"
    fun registerToken(context: Context, token: String) {
        val request = OneTimeWorkRequestBuilder<DeviceTokenWorker>()
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .setInputData(Data.Builder().putString("token", token).build()).build()
        WorkManager.getInstance(context).enqueueUniqueWork("bkk-device-token", ExistingWorkPolicy.REPLACE, request)
    }
}

class DeviceTokenWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val token = inputData.getString("token") ?: return Result.failure()
        val container = (applicationContext as BkkApplication).container
        if (container.sessionStore.token() == null) return Result.success()
        return if (container.repository.registerDevice(token).isSuccess) Result.success()
        else if (runAttemptCount < 4) Result.retry() else Result.failure()
    }
}

class PushWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val container = (applicationContext as BkkApplication).container
        val member = container.sessionStore.member.first() ?: return Result.success()
        if (!NotificationRules.recipientAllows(inputData.getString("recipient_user_id"), member.id)) return Result.success()
        val type = inputData.getString("type")
        if (!NotificationRules.preferenceAllows(member.notificationsEnabled,
                member.eventRemindersEnabled, member.discountAlertsEnabled, type)) return Result.success()
        val noticeId = inputData.getString("notice_id") ?: return Result.failure()
        if (container.featureStore.notices.first().any { it.id == noticeId }) return Result.success()
        val id = inputData.getString("item_id")?.toLongOrNull()
        if (type in setOf("event", "discount") && (id == null || id <= 0)) return Result.failure()
        if (type == "event") {
            val history = container.repository.attendanceHistory().getOrNull()
                ?: return if (runAttemptCount < 4) Result.retry() else Result.failure()
            if (history.none { it.id == id && it.isAttending }) return Result.success()
            container.reminderScheduler.cancel(requireNotNull(id))
        }
        if (container.sessionStore.token() == null) return Result.success()
        val title = inputData.getString("title") ?: "BKK Community update"
        val body = inputData.getString("body") ?: "Open the app for details."
        container.featureStore.addNotice(CommunityNotice(noticeId, title, body, type ?: "general",
            id, System.currentTimeMillis(), false))
        if (!NotificationRules.permissionAllows(Build.VERSION.SDK_INT,
                ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.POST_NOTIFICATIONS)
                    == PackageManager.PERMISSION_GRANTED)) return Result.success()
        val destination = when (type) {
            "event" -> "bkk://event/$id"
            "discount" -> "bkk://discount/$id"
            else -> null
        }
        val intent = destination?.let { Intent(Intent.ACTION_VIEW, it.toUri(), applicationContext, MainActivity::class.java) }
            ?: Intent(applicationContext, MainActivity::class.java)
        val pending = PendingIntent.getActivity(applicationContext, noticeId.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(applicationContext, "bkk_updates")
            .setSmallIcon(R.drawable.ic_notification).setContentTitle(title).setContentText(body)
            .setContentIntent(pending).setAutoCancel(true).build()
        applicationContext.getSystemService(NotificationManager::class.java).notify(noticeId.hashCode(), notification)
        return Result.success()
    }
}
