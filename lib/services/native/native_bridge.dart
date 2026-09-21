import 'package:flutter/services.dart';

/// Falha na comunicação com a camada nativa, já traduzida para uma mensagem
/// que pode ser exibida ao usuário.
class NativeBridgeException implements Exception {
  const NativeBridgeException(this.message);

  final String message;

  @override
  String toString() => 'NativeBridgeException: $message';
}

/// Único ponto de acesso ao canal nativo (Kotlin).
///
/// A UI não deve usar [MethodChannel] diretamente: mantendo o canal aqui, a
/// tela só conhece [getNativeStatus] e [NativeBridgeException].
class NativeBridge {
  const NativeBridge({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  /// Precisa ser idêntico ao CHANNEL em MainActivity.kt.
  static const String channelName = 'com.example.sleepalarm/native';

  static const String _getNativeStatusMethod = 'getNativeStatus';

  final MethodChannel _channel;

  /// Confirma que a camada nativa está registrada e respondendo.
  ///
  /// Lança [NativeBridgeException] quando o canal não existe ou o lado nativo
  /// devolve erro.
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
}
