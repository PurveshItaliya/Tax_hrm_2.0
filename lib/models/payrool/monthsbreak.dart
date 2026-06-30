// To parse this JSON data, do
//
//     final monthwiseBreak = monthwiseBreakFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<MonthwiseBreak> monthwiseBreakFromJson(String str) => List<MonthwiseBreak>.from(json.decode(str).map((x) => MonthwiseBreak.fromJson(x)));

String monthwiseBreakToJson(List<MonthwiseBreak> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class MonthwiseBreak {
  String? attendenceDate;
  String? totalOutMinutes;

  MonthwiseBreak({this.attendenceDate, this.totalOutMinutes});

  MonthwiseBreak.fromJson(Map<String, dynamic> json) {
    attendenceDate = json['AttendenceDate'];
    totalOutMinutes = json['total_out_minutes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['AttendenceDate'] = attendenceDate;
    data['total_out_minutes'] = totalOutMinutes;
    return data;
  }
}
