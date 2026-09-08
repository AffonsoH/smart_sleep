import 'package:flutter/material.dart';

import '../../data/models/alarm_settings.dart';
import '../widgets/time_window_picker.dart';
import 'confirmation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);
  String? _errorText;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
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
              const Spacer(),
              FilledButton(
                onPressed: _confirmAlarm,
                child: const Text('Iniciar alarme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
