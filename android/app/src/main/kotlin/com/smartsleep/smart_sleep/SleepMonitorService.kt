package com.smartsleep.smart_sleep

import android.Manifest
import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Serviço em primeiro plano que observa o movimento durante a janela e
 * decide a hora de despertar.
 *
 * Divisão de responsabilidade: este serviço é a parte *otimista* (acordar
 * mais cedo num momento de movimento). A garantia de despertar no fim da
 * janela não depende dele — está no AlarmManager, veja [SleepAlarmScheduler].
 *
 * Os limiares abaixo são um ponto de partida, não um valor calibrado. Os
 * valores de cada minuto são enviados ao Flutter para permitir ajuste com
 * dados reais.
 */
class SleepMonitorService : Service(), SensorEventListener {

    companion object {
        /** Janela de agregação do movimento. */
        private const val BUCKET_MS = 60_000L

        /** Variação por amostra, em m/s², abaixo da qual tratamos como ruído. */
        private const val NOISE_FLOOR = 0.15

        /** Soma de movimento num minuto que consideramos "mexeu de verdade". */
        private const val ACTIVITY_THRESHOLD = 12.0

        /** Peso da média móvel que estima a gravidade. */
        private const val GRAVITY_ALPHA = 0.05

        /** Teto do wake lock: a janela não deveria passar disso. */
        private const val WAKE_LOCK_TIMEOUT_MS = 2 * 60 * 60 * 1000L

        private const val TAG = "SleepMonitorService"

        fun stop(context: Context) {
            context.stopService(Intent(context, SleepMonitorService::class.java))
        }
    }

    private var sampling = false
    private var ringing = false
    private var windowStartMs = 0L
    private var windowEndMs = 0L

    private var gravity = 0.0
    private var samplesSeen = 0L
    private var bucketStartMs = 0L
    private var bucketSum = 0.0

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        AlarmNotifier.ensureChannels(this)
        windowStartMs = SleepPrefs.windowStart(this)
        windowEndMs = SleepPrefs.windowEnd(this)

        when (intent?.action) {
            AlarmContract.ACTION_FIRE_ALARM -> {
                fireAlarm(intent.getStringExtra(AlarmContract.EXTRA_REASON) ?: AlarmContract.REASON_WINDOW_END)
            }

            AlarmContract.ACTION_START_SAMPLING -> {
                goForeground()
                startSampling()
            }

            AlarmContract.ACTION_ARM -> {
                // Rearmar depois de um alarme reaproveita a mesma instância.
                ringing = false
                goForeground()
                restoreState()
            }

            // Recriação pelo sistema (intent nulo) cai aqui.
            else -> {
                goForeground()
                restoreState()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        stopSampling()
        AlarmNotifier.stopVibration(this)
        releaseWakeLock()
        super.onDestroy()
    }

    // ---------------------------------------------------------------- estado

    private fun restoreState() {
        if (SleepPrefs.isRinging(this)) {
            fireAlarm(SleepPrefs.lastReason(this) ?: AlarmContract.REASON_WINDOW_END)
            return
        }

        if (!SleepPrefs.isArmed(this)) {
            stopSelf()
            return
        }

        val now = System.currentTimeMillis()
        if (now >= windowEndMs && windowEndMs > 0L) {
            fireAlarm(AlarmContract.REASON_WINDOW_END)
        } else if (now >= windowStartMs && windowStartMs > 0L) {
            startSampling()
        }
    }

    private fun goForeground() {
        startForegroundCompat(AlarmContract.NOTIFICATION_MONITOR, AlarmNotifier.monitorNotification(this, statusText()))
    }

    private fun statusText(): String {
        if (windowEndMs <= 0L) return "Alarme armado"
        val format = SimpleDateFormat("HH:mm", Locale.getDefault())
        val start = format.format(Date(windowStartMs))
        val end = format.format(Date(windowEndMs))
        return if (sampling) "Observando o sono até $end" else "Alarme armado para $start–$end"
    }

    private fun startForegroundCompat(id: Int, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val type = if (hasPermission(Manifest.permission.ACTIVITY_RECOGNITION)) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
            } else {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            }
            startForeground(id, notification, type)
        } else {
            startForeground(id, notification)
        }
    }

    private fun hasPermission(permission: String): Boolean =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    // -------------------------------------------------------------- sensores

    private fun startSampling() {
        if (sampling || ringing) return

        val sensorManager = getSystemService(SensorManager::class.java)
        val sensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (sensor == null) {
            // Sem acelerômetro resta o despertar garantido do fim da janela.
            Log.w(TAG, "Acelerômetro indisponível; só o alarme do fim da janela vai valer.")
            return
        }

        acquireWakeLock()
        sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        sampling = true
        gravity = 0.0
        samplesSeen = 0L
        bucketSum = 0.0
        bucketStartMs = System.currentTimeMillis()

        SleepEventBridge.monitoring(true)
        goForeground()
    }

    private fun stopSampling() {
        if (!sampling) return
        getSystemService(SensorManager::class.java)?.unregisterListener(this)
        sampling = false
        releaseWakeLock()
        SleepEventBridge.monitoring(false)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onSensorChanged(event: SensorEvent) {
        if (!sampling) return

        val now = System.currentTimeMillis()
        if (windowEndMs > 0L && now >= windowEndMs) {
            fireAlarm(AlarmContract.REASON_WINDOW_END)
            return
        }

        val x = event.values[0].toDouble()
        val y = event.values[1].toDouble()
        val z = event.values[2].toDouble()
        val magnitude = sqrt(x * x + y * y + z * z)

        // Média móvel isola a gravidade; o resto é movimento.
        gravity = if (samplesSeen == 0L) magnitude else gravity + (magnitude - gravity) * GRAVITY_ALPHA
        samplesSeen++

        val movement = abs(magnitude - gravity)
        if (movement > NOISE_FLOOR) bucketSum += movement

        if (now - bucketStartMs >= BUCKET_MS) closeBucket(now)
    }

    private fun closeBucket(now: Long) {
        val activity = bucketSum
        bucketSum = 0.0
        bucketStartMs = now

        SleepEventBridge.movement(activity, ACTIVITY_THRESHOLD)

        val insideWindow = windowStartMs in 1..now
        if (insideWindow && activity >= ACTIVITY_THRESHOLD) {
            fireAlarm(AlarmContract.REASON_MOVEMENT)
        }
    }

    // ---------------------------------------------------------------- alarme

    private fun fireAlarm(reason: String) {
        if (ringing) return
        ringing = true

        stopSampling()
        SleepAlarmScheduler.cancelAll(this)
        SleepPrefs.setRinging(this, true, reason)

        AlarmNotifier.cancel(this, AlarmContract.NOTIFICATION_MONITOR)
        startForegroundCompat(AlarmContract.NOTIFICATION_ALARM, AlarmNotifier.alarmNotification(this))
        AlarmNotifier.startVibration(this)

        SleepEventBridge.alarm(reason)
    }

    // ------------------------------------------------------------- wake lock

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val power = getSystemService(PowerManager::class.java) ?: return
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "SmartSleep::monitor").apply {
            setReferenceCounted(false)
            acquire(WAKE_LOCK_TIMEOUT_MS)
        }
    }

    private fun releaseWakeLock() {
        val lock = wakeLock ?: return
        if (lock.isHeld) lock.release()
        wakeLock = null
    }
}
