package za.co.bkkcommunity.app.notification

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

class BkkMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        NotificationWork.registerToken(applicationContext, token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        val type = message.data["type"] ?: "general"
        val noticeId = message.data["notice_id"] ?: message.messageId ?: return
        val input = Data.Builder().putString("notice_id", noticeId)
            .putString("type", type)
            .putString("item_id", message.data[if (type == "event") "event_id" else "discount_id"])
            .putString("recipient_user_id", message.data["recipient_user_id"])
            .putString("title", message.data["title"] ?: message.notification?.title ?: "BKK Community update")
            .putString("body", message.data["body"] ?: message.notification?.body ?: "Open the app for details.")
            .build()
        // FCM callbacks have a short lifetime: persist processing before returning.
        val request = OneTimeWorkRequestBuilder<PushWorker>().setInputData(input)
            .addTag(NotificationWork.PUSH_TAG).build()
        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            "bkk-push-$noticeId", ExistingWorkPolicy.KEEP, request)
    }
}
