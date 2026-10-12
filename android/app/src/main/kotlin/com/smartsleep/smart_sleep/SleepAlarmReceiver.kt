package com.smartsleep.smart_sleep

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/** Recebe os dois instantes agendados no AlarmManager. */
class SleepAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        AlarmNotifier.ensureChannels(context)

        when (intent.action) {
            AlarmContract.ACTION_WINDOW_START ->
                startService(context, AlarmContract.ACTION_START_SAMPLING, null)

            AlarmContract.ACTION_WINDOW_END -> {
                // Posta o alarme antes de tentar o serviço: se o início do
                // serviço em background for recusado, o despertar acontece
                // mesmo assim (notificação de alta prioridade com full-screen
                // intent, e o canal já vibra).
                AlarmNotifier.notifyAlarm(context)
                SleepPrefs.setRinging(context, true, AlarmContract.REASON_WINDOW_END)
                startService(context, AlarmContract.ACTION_FIRE_ALARM, AlarmContract.REASON_WINDOW_END)
            }
        }
    }

    private fun startService(context: Context, action: String, reason: String?) {
        val serviceIntent = Intent(context, SleepMonitorService::class.java)
            .setAction(action)
            .apply { if (reason != null) putExtra(AlarmContract.EXTRA_REASON, reason) }

        try {
            context.startForegroundService(serviceIntent)
        } catch (error: Exception) {
            // Android 12+ pode recusar iniciar serviço em primeiro plano a
            // partir do background. O alarme do fim da janela já foi postado.
            Log.w("SleepAlarmReceiver", "Não foi possível iniciar o serviço: $action", error)
        }
    }
}
