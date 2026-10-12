import 'package:flutter/material.dart';

import '../../../../core/utils/time_of_day_ext.dart';
import '../pages/time_editor_page.dart';

class TimeWindowPicker extends StatelessWidget {
  const TimeWindowPicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
    this.errorText,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;
  final String? errorText;

  Future<void> _pickTime(
    BuildContext context, {
    required String title,
    required TimeOfDay current,
    required ValueChanged<TimeOfDay> onChanged,
  }) async {
    final selected = await Navigator.of(context).push<TimeOfDay>(
      MaterialPageRoute<TimeOfDay>(
        builder: (_) => TimeEditorPage(title: title, initialTime: current),
      ),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimeCard(
          label: 'Início da janela',
          time: startTime.formatted,
          onTap: () => _pickTime(
            context,
            title: 'Início da janela',
            current: startTime,
            onChanged: onStartChanged,
          ),
        ),
        const SizedBox(height: 12),
        _TimeCard(
          label: 'Fim da janela',
          time: endTime.formatted,
          onTap: () => _pickTime(
            context,
            title: 'Fim da janela',
            current: endTime,
            onChanged: onEndChanged,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            errorText!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.schedule_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
