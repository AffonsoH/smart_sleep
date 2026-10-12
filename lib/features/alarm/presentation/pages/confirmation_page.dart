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
      body: SafeArea(
        // Sem AppBar e com rolagem: na tela do relógio o conteúdo fixo
        // somado à barra de título estourava o layout.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.alarm_on_rounded,
                size: 40,
                color: colors.primary,
              ),
              const SizedBox(height: 10),
              const Text(
                'Janela de despertar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                settings.windowLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Você será acordado entre ${settings.startTime.formatted} e ${settings.endTime.formatted}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: colors.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
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
