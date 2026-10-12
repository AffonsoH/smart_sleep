import 'package:flutter/material.dart';

/// Tela mostrada quando o alarme está tocando.
///
/// Ela aparece por cima da tela de bloqueio: o alarme é postado com
/// full-screen intent e a MainActivity declara showWhenLocked/turnScreenOn.
class AlarmRingingPage extends StatelessWidget {
  const AlarmRingingPage({
    super.key,
    required this.onDismiss,
    required this.dismissing,
    this.reason,
  });

  final VoidCallback onDismiss;
  final bool dismissing;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detail = reason;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 44,
                color: colors.primary,
              ),
              const SizedBox(height: 10),
              const Text(
                'Hora de acordar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: dismissing ? null : onDismiss,
                child: dismissing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Despertar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
