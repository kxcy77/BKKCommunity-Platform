package za.co.bkkcommunity.app

import android.content.Context
import androidx.room.Room
import za.co.bkkcommunity.app.data.BkkRepository
import za.co.bkkcommunity.app.data.FeatureStore
import za.co.bkkcommunity.app.data.SessionStore
import za.co.bkkcommunity.app.data.local.BkkDatabase
import za.co.bkkcommunity.app.data.remote.ApiClient
import za.co.bkkcommunity.app.notification.ReminderScheduler

class AppContainer(context: Context) {
    private val database = Room.databaseBuilder(context, BkkDatabase::class.java, "bkk-community.db").build()
    val sessionStore = SessionStore(context)
    val featureStore = FeatureStore(context)
    private val api = ApiClient.create(sessionStore)
    val repository = BkkRepository(
        api,
        database.eventDao(),
        database.discountDao(),
        database.localServiceDao(),
        database,
        sessionStore,
        featureStore
    )
    val reminderScheduler = ReminderScheduler(context)
}
