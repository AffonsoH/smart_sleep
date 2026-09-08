import 'package:flutter/material.dart';

import '../../../../core/utils/time_of_day_ext.dart';

/// Configurações da janela de despertar.
///
/// O alarme deve disparar em algum momento entre [startTime] e [endTime].
/// Se nenhum momento de sono leve for encontrado (futuro), dispara em [endTime].
class AlarmSettings {
  const AlarmSettings({
    required this.startTime,
    required this.endTime,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// Horário final precisa ser posterior ao inicial (mesma madrugada/dia).
  bool get isValid => endTime.isAfter(startTime);

  String get windowLabel =>
      '${startTime.formatted}  →  ${endTime.formatted}';
}
