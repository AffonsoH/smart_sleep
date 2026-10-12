import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sleep/services/native/native_bridge.dart';

/// Resposta típica de getState, usada como base nos testes.
Map<String, Object?> stateMap({
  bool armed = false,
  bool ringing = false,
  int windowStartMs = 0,
  int windowEndMs = 0,
}) {
  return <String, Object?>{
    'armed': armed,
    'ringing': ringing,
    'reason': ringing ? 'movimento detectado' : null,
    'windowStartMs': windowStartMs,
    'windowEndMs': windowEndMs,
    'hasAccelerometer': true,
    'notificationsAllowed': false,
    'exactAlarmAllowed': true,
    'activityRecognitionGranted': false,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeBridge.channelName);
  const bridge = NativeBridge();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('devolve a mensagem enviada pela camada nativa', () async {
    String? chamado;
    messenger.setMockMethodCallHandler(channel, (call) async {
      chamado = call.method;
      return 'Native Android layer connected';
    });

    final status = await bridge.getNativeStatus();

    expect(chamado, 'getNativeStatus');
    expect(status, 'Native Android layer connected');
  });

  test('converte PlatformException em NativeBridgeException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'ERRO_NATIVO', message: 'falhou');
    });

    await expectLater(
      bridge.getNativeStatus(),
      throwsA(isA<NativeBridgeException>()),
    );
  });

  test('resposta vazia vira NativeBridgeException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => '');

    await expectLater(
      bridge.getNativeStatus(),
      throwsA(isA<NativeBridgeException>()),
    );
  });

  test('sem camada nativa registrada, o erro é tratado', () async {
    // Nenhum handler registrado: o MethodChannel lança MissingPluginException.
    await expectLater(
      bridge.getNativeStatus(),
      throwsA(isA<NativeBridgeException>()),
    );
  });

  test('getState converte o mapa do nativo', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getState');
      return stateMap(
        armed: true,
        windowStartMs: 1760000000000,
        windowEndMs: 1760001800000,
      );
    });

    final state = await bridge.getState();

    expect(state.armed, isTrue);
    expect(state.ringing, isFalse);
    expect(state.notificationsAllowed, isFalse);
    expect(state.hasAccelerometer, isTrue);
    expect(
      state.windowStart,
      DateTime.fromMillisecondsSinceEpoch(1760000000000),
    );
    expect(state.windowEnd, DateTime.fromMillisecondsSinceEpoch(1760001800000));
  });

  test('janela zerada vira null em vez de 1970', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => stateMap());

    final state = await bridge.getState();

    expect(state.windowStart, isNull);
    expect(state.windowEnd, isNull);
  });

  test('scheduleWindow envia os instantes em milissegundos', () async {
    Map<Object?, Object?>? enviado;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'scheduleWindow');
      enviado = call.arguments as Map<Object?, Object?>?;
      return stateMap(armed: true);
    });

    final start = DateTime(2026, 10, 13, 6, 30);
    final end = DateTime(2026, 10, 13, 7);
    final state = await bridge.scheduleWindow(start: start, end: end);

    expect(enviado?['startMs'], start.millisecondsSinceEpoch);
    expect(enviado?['endMs'], end.millisecondsSinceEpoch);
    expect(state.armed, isTrue);
  });

  test('stopAlarm devolve o estado já desarmado', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'stopAlarm');
      return stateMap();
    });

    final state = await bridge.stopAlarm();

    expect(state.armed, isFalse);
    expect(state.ringing, isFalse);
  });
}
