// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// date Format - MMM, yyyy
String dateFormatMMMyyyy(format) {
  return DateFormat('MMM, yyyy').format(format);
}

// date format - dd MMM yyyy
String dateFormatddMMMyyyy(format) {
  return DateFormat('dd MMM yyyy').format(format);
}

// date Format - date time display
DateTime dateFormatdateHours(format) {
  return DateFormat('dd/MM/yyyy HH:mm:ss').parse(format);
}

// date format - dd MMM yyyy
String dateFormatHours(format) {
  return DateFormat('HH:mm').format(format);
}

// date format - dd MMM yyyy
String dateFormatTimeHours(format) {
  return DateFormat('h:mm a').format(format);
}

String formatTimeWithAmPm(TimeOfDay time, BuildContext context) {
  final now = DateTime.now();
  final dateTime = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );

  return DateFormat('hh:mm a').format(dateTime);
}

// date Format - date display
String dateFormatdate(format) {
  return DateFormat('dd/MM/yyyy').format(format);
}

// date Format yyyy - mm- dd - date display
String dateFormatdateYMDate(format) {
  return DateFormat('yyyy-MM-dd').format(format);
}

String formatDate(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

int convertTimeToMinutes(String time) {
  // Split the time string into hours, minutes, and seconds
  List<String> parts = time.split(':');
  int hours = int.parse(parts[0]);  
  int minutes = int.parse(parts[1]);
  int seconds = int.parse(parts[2]);

  // Convert hours and seconds to minutes
  int totalMinutes = (hours * 60) + minutes + (seconds / 60).round();

  return totalMinutes;
}

String formatTime(dynamic value) {
  if (value == null) return "00:00";

  final parts = value.toString().split(':');
  final h = parts[0].padLeft(2, '0');
  final m = (parts.length > 1 ? parts[1] : '0').padLeft(2, '0');

  return "$h:$m";
}