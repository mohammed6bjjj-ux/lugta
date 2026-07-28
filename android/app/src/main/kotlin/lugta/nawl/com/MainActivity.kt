package lugta.nawl.com

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // This app does not expose Android deep links. FlutterActivity otherwise
    // trusts an exported activity's `route` intent extra as the initial route,
    // which lets another app request a protected Flutter screen before
    // bootstrap. Notification taps use the authenticated Dart-side queue and
    // are unaffected by fixing the platform route to the application root.
    override fun getInitialRoute(): String = "/"

    override fun shouldHandleDeeplinking(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                getString(R.string.default_notification_channel_id),
                getString(R.string.default_notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = getString(R.string.default_notification_channel_description)
                enableVibration(true)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }
}
