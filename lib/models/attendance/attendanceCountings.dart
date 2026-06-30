// To parse this JSON data, do
//
//     final attendanceCountingClass = attendanceCountingClassFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<AttendanceCountingClass> attendanceCountingClassFromJson(String str) => List<AttendanceCountingClass>.from(json.decode(str).map((x) => AttendanceCountingClass.fromJson(x)));

String attendanceCountingClassToJson(List<AttendanceCountingClass> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));



class AttendanceCountingClass {
  int? totalAbsent;
  int? totalPresent;
  int? totalLeave;
  int? totalHolidays;
  int? totalPaidLeave;
  int? totalUnPaidLeave;
  int? religiousLeave;

  AttendanceCountingClass(
      {this.totalAbsent,
      this.totalPresent,
      this.totalLeave,
      this.totalHolidays,
      this.totalPaidLeave,
      this.totalUnPaidLeave,
      this.religiousLeave});

  AttendanceCountingClass.fromJson(Map<String, dynamic> json) {
    totalAbsent = json['TotalAbsent'];
    totalPresent = json['TotalPresent'];
    totalLeave = json['TotalLeave'];
    totalHolidays = json['TotalHolidays'];
    totalPaidLeave = json['TotalPaidLeave'];
    totalUnPaidLeave = json['TotalUnPaidLeave'];
    religiousLeave = json['ReligiousLeave'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['TotalAbsent'] = totalAbsent;
    data['TotalPresent'] = totalPresent;
    data['TotalLeave'] = totalLeave;
    data['TotalHolidays'] = totalHolidays;
    data['TotalPaidLeave'] = totalPaidLeave;
    data['TotalUnPaidLeave'] = totalUnPaidLeave;
    data['ReligiousLeave'] = religiousLeave;
    return data;
  }
}
