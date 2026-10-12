import 'package:flutter/services.dart';

/// Falha na comunicação com a camada nativa, já traduzida para uma mensagem
/// que pode ser exibida ao usuário.
class NativeBridgeException implements Exception {
  const NativeBridgeException(this.message);

  final String message;

  @override
  String toString() => 'NativeBridgeException: $message';
}

/// Estado do alarme como a camada nativa o enxerga.
///
/// É a fonte da verdade: o serviço e o AlarmManager continuam rodando com o
/// app fechado, então o Flutter consulta este estado ao abrir e ao voltar do
/// segundo plano.
class SleepAlarmState {
  const SleepAlarmState({
    required this.armed,
    required this.ringing,
    required this.hasAccelerometer,
    required this.notificationsAllowed,
    required this.exactAlarmAllowed,
    required this.activityRecognitionGranted,
    this.reason,
    this.windowStart,
    this.windowEnd,
  });

  factory SleepAlarmState.fromMap(Map<String, Object?> map) {
    DateTime? toTime(Object? value) {
      final ms = value is int ? value : 0;
      return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    }

    return SleepAlarmState(
      armed: map['armed'] == true,
      ringing: map['ringing'] == true,
      hasAccelerometer: map['hasAccelerometer'] == true,
      notificationsAllowed: map['notificationsAllowed'] == true,
      exactAlarmAllowed: map['exactAlarmAllowed'] == true,
      activityRecognitionGranted: map['activityRecognitionGranted'] == true,
      reason: map['reason'] as String?,
      windowStart: toTime(map['windowStartMs']),
      windowEnd: toTime(map['windowEndMs']),
    );
  }

  /// Estado assumido antes da primeira resposta do nativo.
  static const SleepAlarmState unknown = SleepAlarmState(
    armed: false,
    ringing: false,
    hasAccelerometer: true,
    notificationsAllowed: true,
    exactAlarmAllowed: true,
    activityRecognitionGranted: true,
  );

  final bool armed;
  final bool ringing;
  final bool hasAccelerometer;
  final bool notificationsAllowed;
  final bool exactAlarmAllowed;
  final bool activityRecognitionGranted;

  /// Por que o alarme tocou, preenchido pelo nativo quando [ringing].
  final String? reason;

  final DateTime? windowStart;
  final DateTime? windowEnd;
}

/// Evento vindo da camada nativa enquanto o app está aberto.
sealed class SleepEvent {
  const SleepEvent();
}

/// Movimento agregado de um minuto. Serve para acompanhar e calibrar.
class MovementEvent extends SleepEvent {
  const MovementEvent({required this.activity, required this.threshold});

  final double activity;
  final double threshold;
}

/// O serviço começou ou parou de amostrar o acelerômetro.
class MonitoringEvent extends SleepEvent {
  const MonitoringEvent({required this.sampling});

  final bool sampling;
}

/// O alarme disparou.
class AlarmEvent extends SleepEvent {
  const AlarmEvent({required this.reason});

  final String reason;
}

/// Único ponto de acesso à camada nativa (Kotlin).
///
/// A UI não usa [MethodChannel] nem [EventChannel] diretamente.
class NativeBridge {
  const NativeBridge({
    MethodChannel channel = const MethodChannel(channelName),
    EventChannel events = const EventChannel(eventChannelName),
  })  : _channel = channel,
        _events = events;

  /// Precisa ser idêntico a AlarmContract.METHOD_CHANNEL no Kotlin.
  static const String channelName = 'com.example.sleepalarm/native';

  /// Precisa ser idêntico a AlarmContract.EVENT_CHANNEL no Kotlin.
  static const String eventChannelName = 'com.example.sleepalarm/events';

  static const String _getNativeStatusMethod = 'getNativeStatus';

  final MethodChannel _channel;
  final EventChannel _events;

  /// Confirma que a camada nativa está registrada e respondendo.
  Future<String> getNativeStatus() async {
    try {
      final status = await _channel.invokeMethod<String>(
        _getNativeStatusMethod,
      );

      if (status == null || status.isEmpty) {
        throw const NativeBridgeException(
          'A camada nativa respondeu, mas sem conteúdo.',
        );
      }

      return status;
    } on MissingPluginException {
      throw const NativeBridgeException(
        'Canal nativo não encontrado. Rode em um dispositivo ou emulador '
        'Android e recompile o app após alterar o código Kotlin.',
      );
    } on PlatformException catch (error) {
      throw NativeBridgeException(
        'Erro na camada nativa (${error.code}): '
        '${error.message ?? 'sem detalhes'}',
      );
    }
  }

  Future<SleepAlarmState> getState() => _stateCall('getState');

  /// Arma a janela: agenda os alarmes e sobe o serviço de monitoramento.
  Future<SleepAlarmState> scheduleWindow({
    required DateTime start,
    required DateTime end,
  }) =>
      _stateCall('scheduleWindow', <String, Object?>{
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });

  Future<SleepAlarmState> cancelWindow() => _stateCall('cancelWindow');

  /// Silencia o alarme que está tocando e desarma a janela.
  Future<SleepAlarmState> stopAlarm() => _stateCall('stopAlarm');

  /// Pede notificação e reconhecimento de atividade. Nenhuma das duas é
  /// obrigatória para ler o acelerômetro.
  Future<SleepAlarmState> requestPermissions() =>
      _stateCall('requestPermissions');

  /// Eventos enquanto o app está aberto. Com o app fechado nada é entregue;
  /// o estado que importa fica no lado nativo e é lido por [getState].
  Stream<SleepEvent> get events => _events
      .receiveBroadcastStream()
      .map<SleepEvent?>(_toEvent)
      .where((SleepEvent? event) => event != null)
      .cast<SleepEvent>();

  static SleepEvent? _toEvent(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    switch (raw['type']) {
      case 'movement':
        return MovementEvent(
          activity: (raw['activity'] as num?)?.toDouble() ?? 0.0,
          threshold: (raw['threshold'] as num?)?.toDouble() ?? 0.0,
        );
      case 'monitoring':
        return MonitoringEvent(sampling: raw['sampling'] == true);
      case 'alarm':
        return AlarmEvent(reason: raw['reason'] as String? ?? '');
    }

    return null;
  }

  Future<SleepAlarmState> _stateCall(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        method,
        arguments,
      );

      if (raw == null) {
        throw const NativeBridgeException(
          'A camada nativa respondeu, mas sem conteúdo.',
        );
      }

      return SleepAlarmState.fromMap(raw);
    } on MissingPluginException {
      throw const NativeBridgeException(
        'Canal nativo não encontrado. Rode em um dispositivo ou emulador '
        'Android e recompile o app após alterar o código Kotlin.',
      );
    } on PlatformException catch (error) {
      throw NativeBridgeException(
        'Erro na camada nativa (${error.code}): '
        '${error.message ?? 'sem detalhes'}',
      );
    }
  }
}
