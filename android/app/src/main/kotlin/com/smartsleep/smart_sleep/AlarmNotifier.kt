package com.smartsleep.smart_sleep

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/** Notificações e vibração do alarme. */
object AlarmNotifier {

    private val PATTERN = longArrayOf(0, 700, 500)

    fun ensureChannels(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return

        val monitor = NotificationChannel(
            AlarmContract.CHANNEL_MONITOR,
            "Monitoramento de sono",
            NotificationManager.IMPORTANCE_LOW,
        )
        monitor.description = "Aviso permanente enquanto o alarme está armado."

        val alarm = NotificationChannel(
            AlarmContract.CHANNEL_ALARM,
            "Alarme",
            NotificationManager.IMPORTANCE_HIGH,
        )
        alarm.description = "Toca na hora de acordar."
        alarm.enableVibration(true)
        alarm.setBypassDnd(true)

        manager.createNotificationChannel(monitor)
        manager.createNotificationChannel(alarm)
    }

    fun monitorNotification(context: Context, text: String): Notification =
        Notification.Builder(context, AlarmContract.CHANNEL_MONITOR)
            .setContentTitle("Smart Sleep")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_alarm_notification)
            .setOngoing(true)
            .setContentIntent(openAppIntent(context, alarmFired = false))
            .build()

    fun alarmNotification(context: Context): Notification {
        val showAlarm = openAppIntent(context, alarmFired = true)

        return Notification.Builder(context, AlarmContract.CHANNEL_ALARM)
            .setContentTitle("Hora de acordar")
            .setContentText("Toque para abrir o Smart Sleep")
            .setSmallIcon(R.drawable.ic_alarm_notification)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(showAlarm)
            .setFullScreenIntent(showAlarm, true)
            .build()
    }

    /**
     * Posta o alarme sem depender do serviço. Usado como rede de segurança
     * quando o serviço não pôde ser iniciado.
     */
    fun notifyAlarm(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.notify(AlarmContract.NOTIFICATION_ALARM, alarmNotification(context))
    }

    fun cancel(context: Context, id: Int) {
        context.getSystemService(NotificationManager::class.java)?.cancel(id)
    }

    fun openAppIntent(context: Context, alarmFired: Boolean): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(AlarmContract.EXTRA_ALARM_FIRED, alarmFired)

        return PendingIntent.getActivity(
            context,
            if (alarmFired) AlarmContract.REQUEST_SHOW_ALARM else 0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    fun startVibration(context: Context) {
        val vibrator = vibrator(context) ?: return
        // repeat = 0: repete o padrão a partir do índice 0 até cancelar.
        vibrator.vibrate(VibrationEffect.createWaveform(PATTERN, 0))
    }

    fun stopVibration(context: Context) {
        vibrator(context)?.cancel()
    }

    private fun vibrator(context: Context): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
}
