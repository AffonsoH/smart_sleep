package com.smartsleep.smart_sleep

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * Caminho de ida do nativo para o Flutter.
 *
 * O serviço continua rodando com o app fechado; nesse caso não há sink e os
 * eventos são simplesmente descartados. O estado que importa fica no
 * [SleepPrefs] e o Flutter consulta ao voltar.
 */
object SleepEventBridge {

    private val handler = Handler(Looper.getMainLooper())

    @Volatile
    var sink: EventChannel.EventSink? = null

    fun send(event: Map<String, Any?>) {
        val target = sink ?: return
        handler.post {
            try {
                target.success(event)
            } catch (error: Exception) {
                Log.w("SleepEventBridge", "Falha ao enviar evento ao Flutter", error)
            }
        }
    }

    fun movement(activity: Double, threshold: Double) {
        send(
            mapOf(
                "type" to "movement",
                "activity" to activity,
                "threshold" to threshold,
            ),
        )
    }

    fun monitoring(sampling: Boolean) {
        send(mapOf("type" to "monitoring", "sampling" to sampling))
    }

    fun alarm(reason: String) {
        send(mapOf("type" to "alarm", "reason" to reason))
    }
}
