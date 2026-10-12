import 'package:flutter/material.dart';

import '../../../../core/utils/time_of_day_ext.dart';

/// Editor de horário dimensionado para a tela do relógio.
///
/// O `showTimePicker` do Material não serve aqui: o diálogo dele exige no
/// mínimo 238x326 dp (`_kTimePickerMinPortraitSize`) e a tela útil de um
/// Galaxy Watch tem cerca de 225 dp, o que estourava o layout.
class TimeEditorPage extends StatefulWidget {
  const TimeEditorPage({
    super.key,
    required this.title,
    required this.initialTime,
  });

  final String title;
  final TimeOfDay initialTime;

  @override
  State<TimeEditorPage> createState() => _TimeEditorPageState();
}

class _TimeEditorPageState extends State<TimeEditorPage> {
  /// Minutos andam de 5 em 5: menos toques numa tela pequena.
  static const int _minuteStep = 5;

  int _hour = 0;
  int _minute = 0;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = (widget.initialTime.minute ~/ _minuteStep) * _minuteStep;
  }

  void _changeHour(int steps) {
    setState(() => _hour = (_hour + steps + 24) % 24);
  }

  void _changeMinute(int steps) {
    setState(() => _minute = (_minute + steps * _minuteStep + 60) % 60);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = TimeOfDay(hour: _hour, minute: _minute);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time.formatted,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              _StepperRow(
                label: 'Hora',
                onMinus: () => _changeHour(-1),
                onPlus: () => _changeHour(1),
              ),
              const SizedBox(height: 10),
              _StepperRow(
                label: 'Minuto',
                onMinus: () => _changeMinute(-1),
                onPlus: () => _changeMinute(1),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(time),
                child: const Text('Salvar'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(icon: Icons.remove_rounded, onPressed: onMinus),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        _RoundButton(icon: Icons.add_rounded, onPressed: onPlus),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: colors.primary, size: 22),
        ),
      ),
    );
  }
}
