package com.example.datasolids_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity


class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Register the "datasolids_default" notification channel that
        // the backend's FCM dispatcher targets. Without this, Android
        // 8+ silently drops every push when the app is backgrounded —
        // the notification just never appears in the status bar.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "datasolids_default",
                "Datasolids notifications",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Lab results, sync updates, and security alerts from Datasolids."
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}
