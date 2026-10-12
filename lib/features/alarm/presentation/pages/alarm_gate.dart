import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../services/native/native_bridge.dart';
import '../../data/models/alarm_settings.dart';
import 'alarm_ringing_page.dart';
import 'home_page.dart';

/// Guarda o estado do alarme e decide qual tela mostrar.
///
/// O estado real mora no lado nativo, porque o serviço e o AlarmManager
/// continuam rodando com o app fechado. Aqui ele é lido ao abrir, ao voltar
/// do segundo plano e quando chega um evento.
class AlarmGate extends StatefulWidget {
  const AlarmGate({super.key});

  @override
  State<AlarmGate> createState() => _AlarmGateState();
}

class _AlarmGateState extends State<AlarmGate> with WidgetsBindingObserver {
  static const NativeBridge _bridge = NativeBridge();

  SleepAlarmState _state = SleepAlarmState.unknown;
  StreamSubscription<SleepEvent>? _subscription;
  MovementEvent? _lastMovement;
  bool _sampling = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToNative();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  void _listenToNative() {
    _subscription = _bridge.events.listen(
      (SleepEvent event) {
        if (!mounted) {
          return;
        }

        if (event is MovementEvent) {
          setState(() => _lastMovement = event);
        } else if (event is MonitoringEvent) {
          setState(() => _sampling = event.sampling);
        } else if (event is AlarmEvent) {
          unawaited(_refresh());
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() => _error = 'Falha no canal de eventos: $error');
        }
      },
    );
  }

  Future<void> _refresh() async {
    try {
      final state = await _bridge.getState();
      if (!mounted) {
        return;
      }
      setState(() {
        _state = state;
        _error = null;
      });
    } on NativeBridgeException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    }
  }

  Future<bool> _schedule(AlarmSettings settings) async {
    final window = settings.nextWindow(DateTime.now());
    setState(() => _busy = true);

    try {
      final state = await _bridge.scheduleWindow(
        start: window.start,
        end: window.end,
      );
      if (!mounted) {
        return false;
      }
      setState(() {
        _state = state;
        _error = null;
        _busy = false;
        _lastMovement = null;
      });
      return true;
    } on NativeBridgeException catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _error = error.message;
        _busy = false;
      });
      return false;
    }
  }

  Future<void> _runStateCall(Future<SleepAlarmState> Function() call) async {
    setState(() => _busy = true);

    try {
      final state = await call();
      if (!mounted) {
        return;
      }
      setState(() {
        _state = state;
        _error = null;
        _busy = false;
        _sampling = false;
        _lastMovement = null;
      });
    } on NativeBridgeException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state.ringing) {
      return AlarmRingingPage(
        reason: _state.reason,
        dismissing: _busy,
        onDismiss: () => unawaited(_runStateCall(_bridge.stopAlarm)),
      );
    }

    return HomePage(
      state: _state,
      sampling: _sampling,
      busy: _busy,
      lastMovement: _lastMovement,
      errorText: _error,
      onSchedule: _schedule,
      onCancel: () => _runStateCall(_bridge.cancelWindow),
      onRequestPermissions: () => _runStateCall(_bridge.requestPermissions),
    );
  }
}
