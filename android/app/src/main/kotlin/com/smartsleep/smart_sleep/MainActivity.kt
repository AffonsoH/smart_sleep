package com.smartsleep.smart_sleep

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Activity única do app e porta de entrada do Flutter para a camada nativa.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AlarmContract.METHOD_CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, AlarmContract.EVENT_CHANNEL)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        SleepEventBridge.sink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        SleepEventBridge.sink = null
                    }
                },
            )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getNativeStatus" -> result.success("Native Android layer connected")

            "scheduleWindow" -> {
                val startMs = call.argument<Number>("startMs")?.toLong()
                val endMs = call.argument<Number>("endMs")?.toLong()

                if (startMs == null || endMs == null || endMs <= startMs) {
                    result.error("ARGUMENTOS_INVALIDOS", "startMs e endMs precisam ser válidos e crescentes.", null)
                    return
                }

                AlarmNotifier.ensureChannels(this)
                SleepPrefs.saveWindow(this, startMs, endMs)
                SleepAlarmScheduler.schedule(this, startMs, endMs)

                // Serviço começa com o app em primeiro plano, que é o caminho
                // sem restrição do Android 12+.
                startForegroundService(
                    Intent(this, SleepMonitorService::class.java).setAction(AlarmContract.ACTION_ARM),
                )

                result.success(state())
            }

            "cancelWindow" -> {
                SleepAlarmScheduler.cancelAll(this)
                SleepPrefs.clear(this)
                AlarmNotifier.stopVibration(this)
                AlarmNotifier.cancel(this, AlarmContract.NOTIFICATION_ALARM)
                AlarmNotifier.cancel(this, AlarmContract.NOTIFICATION_MONITOR)
                SleepMonitorService.stop(this)
                result.success(state())
            }

            "stopAlarm" -> {
                AlarmNotifier.stopVibration(this)
                AlarmNotifier.cancel(this, AlarmContract.NOTIFICATION_ALARM)
                SleepAlarmScheduler.cancelAll(this)
                SleepPrefs.clear(this)
                SleepMonitorService.stop(this)
                result.success(state())
            }

            "getState" -> result.success(state())

            "requestPermissions" -> {
                requestMissingPermissions()
                result.success(state())
            }

            else -> result.notImplemented()
        }
    }

    private fun state(): Map<String, Any?> = mapOf(
        "armed" to SleepPrefs.isArmed(this),
        "ringing" to SleepPrefs.isRinging(this),
        "reason" to SleepPrefs.lastReason(this),
        "windowStartMs" to SleepPrefs.windowStart(this),
        "windowEndMs" to SleepPrefs.windowEnd(this),
        "hasAccelerometer" to packageManager.hasSystemFeature(PackageManager.FEATURE_SENSOR_ACCELEROMETER),
        "notificationsAllowed" to notificationsAllowed(),
        "exactAlarmAllowed" to SleepAlarmScheduler.canScheduleExact(this),
        "activityRecognitionGranted" to granted(Manifest.permission.ACTIVITY_RECOGNITION),
    )

    private fun notificationsAllowed(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            granted(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            true
        }

    private fun granted(permission: String): Boolean =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun requestMissingPermissions() {
        val missing = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !granted(Manifest.permission.POST_NOTIFICATIONS)
        ) {
            missing.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        // Não é obrigatória para ler o acelerômetro; serve para o serviço
        // poder rodar como tipo "health" no Android 14+.
        if (!granted(Manifest.permission.ACTIVITY_RECOGNITION)) {
            missing.add(Manifest.permission.ACTIVITY_RECOGNITION)
        }

        if (missing.isNotEmpty()) {
            requestPermissions(missing.toTypedArray(), AlarmContract.REQUEST_PERMISSIONS)
        }
    }
}
