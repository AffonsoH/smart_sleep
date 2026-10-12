import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../services/native/native_bridge.dart';
import '../../data/models/alarm_settings.dart';
import '../widgets/time_window_picker.dart';
import 'confirmation_page.dart';

/// Tela principal: configura a janela quando o alarme está desarmado e
/// mostra o monitoramento quando está armado.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.state,
    required this.sampling,
    required this.busy,
    required this.onSchedule,
    required this.onCancel,
    required this.onRequestPermissions,
    this.lastMovement,
    this.errorText,
  });

  final SleepAlarmState state;
  final bool sampling;
  final bool busy;
  final MovementEvent? lastMovement;
  final String? errorText;

  /// Retorna true quando a janela foi realmente agendada no nativo.
  final Future<bool> Function(AlarmSettings settings) onSchedule;
  final Future<void> Function() onCancel;
  final Future<void> Function() onRequestPermissions;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);
  String? _validationError;

  AlarmSettings get _settings => AlarmSettings(
        startTime: _startTime,
        endTime: _endTime,
      );

  void _onStartChanged(TimeOfDay time) {
    setState(() {
      _startTime = time;
      _validationError = null;
    });
  }

  void _onEndChanged(TimeOfDay time) {
    setState(() {
      _endTime = time;
      _validationError = null;
    });
  }

  Future<void> _confirmAlarm() async {
    if (!_settings.isValid) {
      setState(() {
        _validationError =
            'O horário final precisa ser posterior ao horário inicial.';
      });
      return;
    }

    setState(() => _validationError = null);
    final settings = _settings;

    final scheduled = await widget.onSchedule(settings);
    if (!scheduled || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmationPage(settings: settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // Tela de relógio é pequena: sem rolagem o conteúdo estoura o layout.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Smart Sleep',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (widget.state.armed)
                ..._armedSection(colors)
              else
                ..._setupSection(colors),
              ..._warnings(colors),
              if (widget.errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.errorText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- desarmado

  List<Widget> _setupSection(ColorScheme colors) {
    return [
      Text(
        'Escolha a janela em que você deseja acordar.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
      ),
      const SizedBox(height: 16),
      TimeWindowPicker(
        startTime: _startTime,
        endTime: _endTime,
        onStartChanged: _onStartChanged,
        onEndChanged: _onEndChanged,
        errorText: _validationError,
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: widget.busy ? null : () => unawaited(_confirmAlarm()),
        child: widget.busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Iniciar alarme'),
      ),
    ];
  }

  // ---------------------------------------------------------------- armado

  List<Widget> _armedSection(ColorScheme colors) {
    final start = widget.state.windowStart;
    final end = widget.state.windowEnd;
    final label = start != null && end != null
        ? '${_hhmm(start)}  →  ${_hhmm(end)}'
        : _settings.windowLabel;

    return [
      Icon(Icons.bedtime_rounded, size: 34, color: colors.primary),
      const SizedBox(height: 8),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(
        widget.sampling
            ? 'Observando o movimento do pulso.'
            : 'Alarme armado. O monitoramento começa no início da janela.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.3,
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
      ),
      ..._movementIndicator(colors),
      const SizedBox(height: 18),
      OutlinedButton(
        onPressed: widget.busy ? null : () => unawaited(widget.onCancel()),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text('Cancelar alarme'),
      ),
    ];
  }

  List<Widget> _movementIndicator(ColorScheme colors) {
    final movement = widget.lastMovement;
    if (movement == null || movement.threshold <= 0) {
      return const [];
    }

    final ratio =
        (movement.activity / movement.threshold).clamp(0.0, 1.0).toDouble();

    return [
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: ratio,
          minHeight: 6,
          backgroundColor: colors.surface,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Movimento no último minuto: '
        '${movement.activity.toStringAsFixed(1)} '
        '(desperta em ${movement.threshold.toStringAsFixed(0)})',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: colors.onSurface.withValues(alpha: 0.6),
        ),
      ),
    ];
  }

  // --------------------------------------------------------------- avisos

  List<Widget> _warnings(ColorScheme colors) {
    final state = widget.state;
    final messages = <String>[];

    if (!state.hasAccelerometer) {
      messages.add(
        'Sem acelerômetro neste aparelho: só o despertar no fim da janela vai funcionar.',
      );
    }
    if (!state.exactAlarmAllowed) {
      messages.add(
        'Alarme exato não autorizado: o despertar pode atrasar alguns minutos.',
      );
    }

    final widgets = <Widget>[];

    for (final message in messages) {
      widgets.addAll([
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.3,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ]);
    }

    if (!state.notificationsAllowed) {
      widgets.addAll([
        const SizedBox(height: 10),
        Text(
          'Sem permissão de notificação o alarme não aparece na tela.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.3,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed:
              widget.busy ? null : () => unawaited(widget.onRequestPermissions()),
          child: const Text('Conceder permissões'),
        ),
      ]);
    }

    return widgets;
  }

  static String _hhmm(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
