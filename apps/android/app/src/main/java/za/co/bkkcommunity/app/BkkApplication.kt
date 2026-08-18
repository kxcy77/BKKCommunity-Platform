package za.co.bkkcommunity.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager

class BkkApplication : Application() {
    val container by lazy { AppContainer(this) }

    override fun onCreate() {
        super.onCreate()
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(
            "bkk_updates",
            "BKK community updates",
            NotificationManager.IMPORTANCE_HIGH
        ).apply { description = "Event reminders and new senior discount alerts" })
        manager.createNotificationChannel(NotificationChannel(
            "bkk_personal_reminders",
            "Personal event reminders",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply { description = "Reminders you set for individual community events" })
    }
}
