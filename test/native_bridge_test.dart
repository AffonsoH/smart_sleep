import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sleep/services/native/native_bridge.dart';

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
}
