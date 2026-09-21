package com.smartsleep.smart_sleep

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Activity única do app.
 *
 * Por enquanto ela só registra o canal de comunicação com o Flutter. Sensores,
 * serviço em background e alarmes entram em etapas seguintes.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_GET_NATIVE_STATUS -> result.success(NATIVE_STATUS_MESSAGE)
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        /** Precisa ser idêntico ao nome usado em lib/services/native/native_bridge.dart. */
        private const val CHANNEL = "com.example.sleepalarm/native"
        private const val METHOD_GET_NATIVE_STATUS = "getNativeStatus"
        private const val NATIVE_STATUS_MESSAGE = "Native Android layer connected"
    }
}
