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

  /// Próxima ocorrência da janela a partir de [from].
  ///
  /// Se o horário de início já passou hoje, a janela é a de amanhã.
  ({DateTime start, DateTime end}) nextWindow(DateTime from) {
    var start = DateTime(
      from.year,
      from.month,
      from.day,
      startTime.hour,
      startTime.minute,
    );

    if (!start.isAfter(from)) {
      start = start.add(const Duration(days: 1));
    }

    var end = DateTime(
      start.year,
      start.month,
      start.day,
      endTime.hour,
      endTime.minute,
    );

    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    return (start: start, end: end);
  }
}
