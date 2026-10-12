package com.smartsleep.smart_sleep

import android.content.Context
import android.content.SharedPreferences

/**
 * Estado do alarme em disco.
 *
 * Precisa sobreviver à morte do processo: o receiver do fim da janela pode
 * rodar com o app fechado.
 */
object SleepPrefs {

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(AlarmContract.PREFS, Context.MODE_PRIVATE)

    fun saveWindow(context: Context, startMs: Long, endMs: Long) {
        prefs(context).edit()
            .putLong(AlarmContract.KEY_WINDOW_START, startMs)
            .putLong(AlarmContract.KEY_WINDOW_END, endMs)
            .putBoolean(AlarmContract.KEY_ARMED, true)
            .putBoolean(AlarmContract.KEY_RINGING, false)
            .remove(AlarmContract.KEY_REASON)
            .apply()
    }

    fun clear(context: Context) {
        prefs(context).edit()
            .putBoolean(AlarmContract.KEY_ARMED, false)
            .putBoolean(AlarmContract.KEY_RINGING, false)
            .remove(AlarmContract.KEY_WINDOW_START)
            .remove(AlarmContract.KEY_WINDOW_END)
            .remove(AlarmContract.KEY_REASON)
            .apply()
    }

    fun setRinging(context: Context, ringing: Boolean, reason: String?) {
        val editor = prefs(context).edit().putBoolean(AlarmContract.KEY_RINGING, ringing)
        if (reason != null) editor.putString(AlarmContract.KEY_REASON, reason)
        editor.apply()
    }

    fun windowStart(context: Context): Long =
        prefs(context).getLong(AlarmContract.KEY_WINDOW_START, 0L)

    fun windowEnd(context: Context): Long =
        prefs(context).getLong(AlarmContract.KEY_WINDOW_END, 0L)

    fun isArmed(context: Context): Boolean =
        prefs(context).getBoolean(AlarmContract.KEY_ARMED, false)

    fun isRinging(context: Context): Boolean =
        prefs(context).getBoolean(AlarmContract.KEY_RINGING, false)

    fun lastReason(context: Context): String? =
        prefs(context).getString(AlarmContract.KEY_REASON, null)
}
