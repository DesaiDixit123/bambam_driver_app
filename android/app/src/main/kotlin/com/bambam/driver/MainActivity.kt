package com.bambam.driver

import android.app.ActivityManager
import android.app.DownloadManager
import android.app.KeyguardManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bambam.driver/overlay"
    private var wakeLock: PowerManager.WakeLock? = null
    private var pendingActionData: Map<String, Any?>? = null

    companion object {
        var isAlertActive = false
    }

    private fun extractPendingAction(intent: Intent?) {
        if (intent == null) return
        val action = intent.getStringExtra("action")
        if (action != null) {
            val map = mutableMapOf<String, Any?>()
            map["action"] = action
            val bundle = intent.extras
            if (bundle != null) {
                for (key in bundle.keySet()) {
                    map[key] = bundle.get(key)
                }
            }
            pendingActionData = map
        }
    }

    private fun isRideAlertIntent(intent: Intent?): Boolean {
        if (intent == null) return false
        if (intent.getBooleanExtra("is_ride_alert", false)) return true
        if (intent.hasExtra("bookingId") || intent.hasExtra("booking_id")) return true
        if (intent.getStringExtra("type")?.contains("ride") == true) return true
        val payload = intent.getStringExtra("payload")
        if (payload != null && (payload.contains("booking") || payload.contains("ride"))) return true
        return false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractPendingAction(intent)
        if (isAlertActive || isRideAlertIntent(intent)) {
            enableLockScreenAlert()
        } else {
            disableLockScreenAlert()
        }
    }

    override fun onResume() {
        super.onResume()
        if (isAlertActive || isRideAlertIntent(intent)) {
            enableLockScreenAlert()
        } else {
            disableLockScreenAlert()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractPendingAction(intent)
        if (isRideAlertIntent(intent)) {
            enableLockScreenAlert()
        }
    }

    private fun enableLockScreenAlert() {
        isAlertActive = true
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (wakeLock == null || wakeLock?.isHeld == false) {
                @Suppress("DEPRECATION")
                wakeLock = powerManager?.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                    "bambam:ride_alert_wake"
                )
                wakeLock?.acquire(30000)
            }
        } catch (_: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
    }

    private fun disableLockScreenAlert() {
        isAlertActive = false
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }
        @Suppress("DEPRECATION")
        window.clearFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        try {
            intent?.removeExtra("is_ride_alert")
            intent?.removeExtra("bookingId")
            intent?.removeExtra("booking_id")
            intent?.removeExtra("type")
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingAction" -> {
                    val data = pendingActionData
                    pendingActionData = null
                    result.success(data)
                }
                "bringToForeground" -> {
                    try {
                        enableLockScreenAlert()
                        val args = call.arguments as? Map<*, *>

                        try {
                            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                            activityManager?.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
                        } catch (_: Exception) {}

                        val launchIntent = (packageManager.getLaunchIntentForPackage(packageName) ?: Intent(applicationContext, MainActivity::class.java)).apply {
                            putExtra("is_ride_alert", true)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            if (args != null) {
                                for ((k, v) in args) {
                                    putExtra(k.toString(), v?.toString())
                                }
                            }
                        }
                        try {
                            val pi = android.app.PendingIntent.getActivity(
                                applicationContext,
                                0,
                                launchIntent,
                                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                            )
                            pi.send()
                        } catch (e: Exception) {
                            startActivity(launchIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "disableLockScreenAlert" -> {
                    disableLockScreenAlert()
                    result.success(true)
                }
                "isDeviceLocked" -> {
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    result.success(keyguardManager?.isKeyguardLocked ?: false)
                }
                "requestUnlockDevice" -> {
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && keyguardManager != null && keyguardManager.isKeyguardLocked) {
                        keyguardManager.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                            override fun onDismissSucceeded() {
                                super.onDismissSucceeded()
                                disableLockScreenAlert()
                                result.success(true)
                            }

                            override fun onDismissCancelled() {
                                super.onDismissCancelled()
                                result.success(false)
                            }

                            override fun onDismissError() {
                                super.onDismissError()
                                disableLockScreenAlert()
                                result.success(true)
                            }
                        })
                    } else {
                        disableLockScreenAlert()
                        result.success(true)
                    }
                }
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        }
                    }
                    result.success(true)
                }
                "saveToDownloads" -> {
                    try {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName") ?: "BamBam_Car_Rent_Agreement.png"
                        val mimeType = call.argument<String>("mimeType") ?: "image/png"

                        if (bytes == null) {
                            result.error("INVALID_ARGS", "Bytes cannot be null", null)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val resolver = applicationContext.contentResolver
                            val contentValues = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                put(MediaStore.MediaColumns.IS_PENDING, 1)
                            }
                            val collection = if (mimeType.contains("pdf")) {
                                MediaStore.Downloads.EXTERNAL_CONTENT_URI
                            } else {
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                            }
                            val uri = resolver.insert(collection, contentValues)
                            if (uri != null) {
                                resolver.openOutputStream(uri)?.use { out ->
                                    out.write(bytes)
                                }
                                contentValues.clear()
                                contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                                resolver.update(uri, contentValues, null, null)
                                result.success(uri.toString())
                            } else {
                                result.error("INSERT_FAILED", "Could not create MediaStore entry", null)
                            }
                        } else {
                            val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            if (!downloadDir.exists()) downloadDir.mkdirs()
                            val file = File(downloadDir, fileName)
                            FileOutputStream(file).use { out ->
                                out.write(bytes)
                            }
                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(file.absolutePath),
                                arrayOf(mimeType),
                                null
                            )
                            result.success(file.absolutePath)
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                "startDownloadManager" -> {
                    try {
                        val url = call.argument<String>("url")
                        val fileName = call.argument<String>("fileName") ?: "BamBam_Car_Rent_Agreement.png"
                        val mimeType = call.argument<String>("mimeType") ?: "image/png"
                        if (url != null) {
                            val dm = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                            val request = DownloadManager.Request(Uri.parse(url)).apply {
                                setTitle(fileName)
                                setDescription("Downloading Car Rent Agreement...")
                                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                                setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
                                setMimeType(mimeType)
                            }
                            dm.enqueue(request)
                            result.success(true)
                        } else {
                            result.error("INVALID_URL", "URL is null", null)
                        }
                    } catch (e: Exception) {
                        result.error("DOWNLOAD_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
