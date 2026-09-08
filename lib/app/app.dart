import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/alarm/presentation/pages/home_page.dart';

class SmartSleepApp extends StatelessWidget {
  const SmartSleepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Sleep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}
