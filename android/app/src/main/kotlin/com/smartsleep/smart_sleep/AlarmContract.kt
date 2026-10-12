package com.smartsleep.smart_sleep

/** Nomes e constantes compartilhados entre Flutter, serviço e receiver. */
object AlarmContract {
    /** Precisa ser idêntico ao channelName em lib/services/native/native_bridge.dart. */
    const val METHOD_CHANNEL = "com.example.sleepalarm/native"
    const val EVENT_CHANNEL = "com.example.sleepalarm/events"

    const val ACTION_WINDOW_START = "com.smartsleep.smart_sleep.WINDOW_START"
    const val ACTION_WINDOW_END = "com.smartsleep.smart_sleep.WINDOW_END"

    const val ACTION_ARM = "com.smartsleep.smart_sleep.ARM"
    const val ACTION_START_SAMPLING = "com.smartsleep.smart_sleep.START_SAMPLING"
    const val ACTION_FIRE_ALARM = "com.smartsleep.smart_sleep.FIRE_ALARM"

    const val EXTRA_ALARM_FIRED = "alarm_fired"
    const val EXTRA_REASON = "reason"

    const val REASON_WINDOW_END = "fim da janela"
    const val REASON_MOVEMENT = "movimento detectado"

    const val PREFS = "smart_sleep"
    const val KEY_WINDOW_START = "window_start_ms"
    const val KEY_WINDOW_END = "window_end_ms"
    const val KEY_ARMED = "armed"
    const val KEY_RINGING = "ringing"
    const val KEY_REASON = "last_reason"

    const val REQUEST_WINDOW_START = 1001
    const val REQUEST_WINDOW_END = 1002
    const val REQUEST_SHOW_ALARM = 1003
    const val REQUEST_PERMISSIONS = 2001

    const val CHANNEL_MONITOR = "smart_sleep_monitor"
    const val CHANNEL_ALARM = "smart_sleep_alarm"
    const val NOTIFICATION_MONITOR = 1
    const val NOTIFICATION_ALARM = 2
}
