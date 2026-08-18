package za.co.bkkcommunity.app.notification

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import za.co.bkkcommunity.app.MainActivity
import za.co.bkkcommunity.app.R
import za.co.bkkcommunity.app.model.CommunityEvent
import java.time.Duration
import java.time.Instant
import java.util.concurrent.TimeUnit

class ReminderScheduler(private val context: Context) {
    fun schedule(event: CommunityEvent) {
        val eventStart = runCatching { Instant.parse(event.startAt) }.getOrNull() ?: return
        val triggerAt = eventStart.minus(Duration.ofHours(24))
        val delay = Duration.between(Instant.now(), triggerAt).toMillis().coerceAtLeast(1_000)
        val input = Data.Builder()
            .putLong(ReminderWorker.EVENT_ID, event.id)
            .putString(ReminderWorker.EVENT_TITLE, event.title)
            .putString(ReminderWorker.EVENT_LOCATION, event.location)
            .build()
        val request = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(input)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(workName(event.id), ExistingWorkPolicy.REPLACE, request)
    }

    fun cancel(eventId: Long) {
        WorkManager.getInstance(context).cancelUniqueWork(workName(eventId))
    }

    private fun workName(eventId: Long) = "event-reminder-$eventId"
}

class ReminderWorker(context: Context, parameters: WorkerParameters) : Worker(context, parameters) {
    override fun doWork(): Result {
        if (ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED) return Result.success()
        val eventId = inputData.getLong(EVENT_ID, -1)
        val title = inputData.getString(EVENT_TITLE) ?: return Result.failure()
        val location = inputData.getString(EVENT_LOCATION).orEmpty()
        val intent = Intent(Intent.ACTION_VIEW, "bkk://event/$eventId".toUri(), applicationContext, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            eventId.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(applicationContext, "bkk_personal_reminders")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Event tomorrow: $title")
            .setContentText(location)
            .setStyle(NotificationCompat.BigTextStyle().bigText("$title is tomorrow at $location. Open BKK Community for details."))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        applicationContext.getSystemService(NotificationManager::class.java).notify((10_000 + eventId).toInt(), notification)
        return Result.success()
    }

    companion object {
        const val EVENT_ID = "event_id"
        const val EVENT_TITLE = "event_title"
        const val EVENT_LOCATION = "event_location"
    }
}
