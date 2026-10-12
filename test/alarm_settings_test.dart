import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sleep/features/alarm/data/models/alarm_settings.dart';

void main() {
  const settings = AlarmSettings(
    startTime: TimeOfDay(hour: 6, minute: 30),
    endTime: TimeOfDay(hour: 7, minute: 0),
  );

  test('usa a janela de hoje quando o início ainda não passou', () {
    final window = settings.nextWindow(DateTime(2026, 10, 12, 5));

    expect(window.start, DateTime(2026, 10, 12, 6, 30));
    expect(window.end, DateTime(2026, 10, 12, 7));
  });

  test('vai para amanhã quando o início já passou', () {
    final window = settings.nextWindow(DateTime(2026, 10, 12, 23));

    expect(window.start, DateTime(2026, 10, 13, 6, 30));
    expect(window.end, DateTime(2026, 10, 13, 7));
  });

  test('o fim é sempre posterior ao início', () {
    final window = settings.nextWindow(DateTime(2026, 10, 12, 6, 45));

    expect(window.end.isAfter(window.start), isTrue);
  });

  test('isValid rejeita fim anterior ao início', () {
    const invalida = AlarmSettings(
      startTime: TimeOfDay(hour: 7, minute: 0),
      endTime: TimeOfDay(hour: 6, minute: 30),
    );

    expect(invalida.isValid, isFalse);
    expect(settings.isValid, isTrue);
  });
}
