package za.co.bkkcommunity.app

import android.os.Bundle
import android.content.Intent
import android.net.Uri
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import za.co.bkkcommunity.app.ui.BkkApp
import za.co.bkkcommunity.app.ui.theme.BkkTheme

class MainActivity : ComponentActivity() {
    private var deepLink by mutableStateOf<Uri?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        deepLink = intent?.data
        val container = (application as BkkApplication).container
        setContent {
            BkkTheme { BkkApp(container = container, deepLink = deepLink) }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deepLink = intent.data
    }
}
