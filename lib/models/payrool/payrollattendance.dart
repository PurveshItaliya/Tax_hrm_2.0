// To parse this JSON data, do
//
//     final payrollAttendence = payrollAttendenceFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<PayrollAttendence> payrollAttendenceFromJson(String str) => List<PayrollAttendence>.from(json.decode(str).map((x) => PayrollAttendence.fromJson(x)));

String payrollAttendenceToJson(List<PayrollAttendence> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class PayrollAttendence {
  int? payrollAtteID;
  String? attendenceDate;
  int? companyId;
  int? empId;
  String? inTime;
  String? outTime;
  String? totalBreak;
  String? totalHours;
  String? dayType;
  String? cguid;
  String? flag;
  String? iPAddress;
  dynamic serverName;
  String? entryTime;

  PayrollAttendence(
      {this.payrollAtteID,
      this.attendenceDate,
      this.companyId,
      this.empId,
      this.inTime,
      this.outTime,
      this.totalBreak,
      this.totalHours,
      this.dayType,
      this.cguid,
      this.flag,
      this.iPAddress,
      this.serverName,
      this.entryTime});

  PayrollAttendence.fromJson(Map<String, dynamic> json) {
    payrollAtteID = json['PayrollAtteID'];
    attendenceDate = json['AttendenceDate'];
    companyId = json['CompanyId'];
    empId = json['EmpId'];
    inTime = json['InTime'];
    outTime = json['OutTime'];
    totalBreak = json['TotalBreak'];
    totalHours = json['TotalHours'];
    dayType = json['DayType'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['PayrollAtteID'] = payrollAtteID;
    data['AttendenceDate'] = attendenceDate;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['InTime'] = inTime;
    data['OutTime'] = outTime;
    data['TotalBreak'] = totalBreak;
    data['TotalHours'] = totalHours;
    data['DayType'] = dayType;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    return data;
  }
}
