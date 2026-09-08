import 'package:flutter/material.dart';

extension TimeOfDayCompare on TimeOfDay {
  int get totalMinutes => hour * 60 + minute;

  bool isBefore(TimeOfDay other) => totalMinutes < other.totalMinutes;

  bool isAfter(TimeOfDay other) => totalMinutes > other.totalMinutes;

  bool isAtSameMomentAs(TimeOfDay other) => totalMinutes == other.totalMinutes;

  String get formatted {
    final hours = hour.toString().padLeft(2, '0');
    final minutes = minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
