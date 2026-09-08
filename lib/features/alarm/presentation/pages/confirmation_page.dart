import 'package:flutter/material.dart';

import '../../../../core/utils/time_of_day_ext.dart';
import '../../data/models/alarm_settings.dart';

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({
    super.key,
    required this.settings,
  });

  final AlarmSettings settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarme confirmado'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.alarm_on_rounded,
                size: 64,
                color: colors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Janela de despertar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                settings.windowLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Você será acordado entre ${settings.startTime.formatted} e ${settings.endTime.formatted}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: colors.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Voltar e ajustar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
