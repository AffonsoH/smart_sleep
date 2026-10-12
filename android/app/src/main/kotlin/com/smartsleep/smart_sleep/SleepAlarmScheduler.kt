package com.smartsleep.smart_sleep

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Agenda os dois instantes da janela no AlarmManager.
 *
 * O fim da janela usa `setAlarmClock`, que é a única categoria que o sistema
 * nunca adia e que acorda o aparelho do Doze. É essa chamada que garante o
 * despertar mesmo se o serviço de monitoramento for morto.
 */
object SleepAlarmScheduler {

    fun schedule(context: Context, windowStartMs: Long, windowEndMs: Long) {
        val manager = context.getSystemService(AlarmManager::class.java) ?: return

        // Início da janela: só liga o acelerômetro, não precisa ser alarm clock.
        set(
            context = context,
            manager = manager,
            triggerAtMs = windowStartMs,
            alarmClock = false,
            pending = pendingIntent(
                context,
                AlarmContract.ACTION_WINDOW_START,
                AlarmContract.REQUEST_WINDOW_START,
            ),
        )

        // Fim da janela: despertar obrigatório.
        set(
            context = context,
            manager = manager,
            triggerAtMs = windowEndMs,
            alarmClock = true,
            pending = pendingIntent(
                context,
                AlarmContract.ACTION_WINDOW_END,
                AlarmContract.REQUEST_WINDOW_END,
            ),
        )
    }

    fun cancelAll(context: Context) {
        val manager = context.getSystemService(AlarmManager::class.java) ?: return
        manager.cancel(pendingIntent(context, AlarmContract.ACTION_WINDOW_START, AlarmContract.REQUEST_WINDOW_START))
        manager.cancel(pendingIntent(context, AlarmContract.ACTION_WINDOW_END, AlarmContract.REQUEST_WINDOW_END))
    }

    fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val manager = context.getSystemService(AlarmManager::class.java) ?: return false
        return manager.canScheduleExactAlarms()
    }

    private fun set(
        context: Context,
        manager: AlarmManager,
        triggerAtMs: Long,
        alarmClock: Boolean,
        pending: PendingIntent,
    ) {
        val exact = canScheduleExact(context)

        when {
            alarmClock && exact -> manager.setAlarmClock(
                AlarmManager.AlarmClockInfo(triggerAtMs, AlarmNotifier.openAppIntent(context, alarmFired = false)),
                pending,
            )
            exact -> manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pending)
            // Sem permissão de alarme exato o disparo pode atrasar alguns minutos.
            else -> manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pending)
        }
    }

    private fun pendingIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, SleepAlarmReceiver::class.java).setAction(action)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
