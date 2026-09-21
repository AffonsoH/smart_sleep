import 'package:flutter/material.dart';

import '../../../../services/native/native_bridge.dart';
import '../../data/models/alarm_settings.dart';
import '../widgets/time_window_picker.dart';
import 'confirmation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const NativeBridge _nativeBridge = NativeBridge();

  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);
  String? _errorText;

  // Estado do teste temporário de comunicação com o Kotlin.
  String? _nativeMessage;
  bool _nativeFailed = false;
  bool _testingNative = false;

  AlarmSettings get _settings => AlarmSettings(
        startTime: _startTime,
        endTime: _endTime,
      );

  void _onStartChanged(TimeOfDay time) {
    setState(() {
      _startTime = time;
      _errorText = null;
    });
  }

  void _onEndChanged(TimeOfDay time) {
    setState(() {
      _endTime = time;
      _errorText = null;
    });
  }

  void _confirmAlarm() {
    if (!_settings.isValid) {
      setState(() {
        _errorText =
            'O horário final precisa ser posterior ao horário inicial.';
      });
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmationPage(settings: _settings),
      ),
    );
  }

  /// Teste temporário: confirma que o Flutter conversa com a camada Kotlin.
  /// Deve sair da tela quando a integração real com os sensores existir.
  Future<void> _testNativeConnection() async {
    setState(() {
      _testingNative = true;
      _nativeMessage = null;
    });

    String message;
    bool failed;

    try {
      message = await _nativeBridge.getNativeStatus();
      failed = false;
    } on NativeBridgeException catch (error) {
      message = error.message;
      failed = true;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _testingNative = false;
      _nativeMessage = message;
      _nativeFailed = failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // Tela de relógio é pequena: sem rolagem o conteúdo estoura o layout.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Smart Sleep',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha a janela em que você deseja acordar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 36),
              TimeWindowPicker(
                startTime: _startTime,
                endTime: _endTime,
                onStartChanged: _onStartChanged,
                onEndChanged: _onEndChanged,
                errorText: _errorText,
              ),
              const SizedBox(height: 36),
              FilledButton(
                onPressed: _confirmAlarm,
                child: const Text('Iniciar alarme'),
              ),
              const SizedBox(height: 12),
              // Botão temporário: existe só para validar o Platform Channel.
              OutlinedButton(
                onPressed: _testingNative ? null : _testNativeConnection,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _testingNative
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Testar conexão nativa'),
              ),
              if (_nativeMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _nativeMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: _nativeFailed ? colors.error : colors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
