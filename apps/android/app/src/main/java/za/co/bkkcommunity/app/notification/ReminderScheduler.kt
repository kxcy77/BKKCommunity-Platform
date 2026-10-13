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
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import za.co.bkkcommunity.app.MainActivity
import za.co.bkkcommunity.app.BkkApplication
import za.co.bkkcommunity.app.R
import za.co.bkkcommunity.app.model.CommunityEvent
import java.time.Instant
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import java.util.concurrent.TimeUnit

class ReminderScheduler(private val context: Context) {
    fun schedule(event: CommunityEvent) {
        val delay = NotificationRules.reminderDelay(event.startAt) ?: return
        val input = Data.Builder()
            .putLong(ReminderWorker.EVENT_ID, event.id)
            .putString(ReminderWorker.EVENT_TITLE, event.title)
            .putString(ReminderWorker.EVENT_LOCATION, event.location)
            .putString(ReminderWorker.EVENT_START, event.startAt)
            .build()
        val request = OneTimeWorkRequestBuilder<ReminderWorker>()
            .addTag(REMINDER_TAG)
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(input)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(workName(event.id), ExistingWorkPolicy.REPLACE, request)
    }

    fun cancel(eventId: Long) {
        WorkManager.getInstance(context).cancelUniqueWork(workName(eventId))
        context.getSystemService(NotificationManager::class.java).cancel((10_000 + eventId).toInt())
    }

    fun cancelReminders() {
        WorkManager.getInstance(context).cancelAllWorkByTag(REMINDER_TAG)
    }

    fun cancelAllPersonalNotifications() {
        cancelReminders()
        WorkManager.getInstance(context).cancelAllWorkByTag(NotificationWork.PUSH_TAG)
        context.getSystemService(NotificationManager::class.java).cancelAll()
    }

    private fun workName(eventId: Long) = "event-reminder-$eventId"

    fun registerDevice(token: String) = NotificationWork.registerToken(context, token)

    companion object { const val REMINDER_TAG = "bkk-event-reminders" }
}

class ReminderWorker(context: Context, parameters: WorkerParameters) : Worker(context, parameters) {
    override fun doWork(): Result {
        if (!NotificationRules.permissionAllows(Build.VERSION.SDK_INT,
                ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.POST_NOTIFICATIONS)
                    == PackageManager.PERMISSION_GRANTED)) return Result.success()
        val eventId = inputData.getLong(EVENT_ID, -1)
        if (eventId <= 0) return Result.failure()
        val container = (applicationContext as BkkApplication).container
        // Worker runs off the UI thread. Never notify a signed-out user or a cancelled RSVP.
        val eligible = runBlocking {
            val member = container.sessionStore.member.first() ?: return@runBlocking false
            if (!member.notificationsEnabled || !member.eventRemindersEnabled) return@runBlocking false
            val event = container.repository.eventStream.first().firstOrNull { it.id == eventId }
                ?: return@runBlocking false
            event.isAttending &&
                event.startAt == inputData.getString(EVENT_START) &&
                runCatching { Instant.parse(event.startAt).isAfter(Instant.now()) }.getOrDefault(false)
        }
        if (!eligible) return Result.success()
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
            .setContentTitle("Upcoming event: $title")
            .setContentText(location)
            .setStyle(NotificationCompat.BigTextStyle().bigText("$title at $location. Open BKK Community for the date and time."))
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
        const val EVENT_START = "event_start"
    }
}
