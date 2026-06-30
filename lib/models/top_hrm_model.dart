// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<HrmTopListReport> hrmTopListReportFromJson(String str) =>
    List<HrmTopListReport>.from(
      json.decode(str).map((x) => HrmTopListReport.fromJson(x)),
    );

String hrmTopListReportToJson(List<HrmTopListReport> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HrmTopListReport {
  int? empId;
  String? empName;
  int? totalDays;
  int? totalOfficeMinutes;
  String? totalOfficeHours;
  int? totalBreakMinutes;
  String? totalBreakHours;
  int? netWorkingMinutes;
  String? netWorkingHours;

  HrmTopListReport({
    this.empId,
    this.empName,
    this.totalDays,
    this.totalOfficeMinutes,
    this.totalOfficeHours,
    this.totalBreakMinutes,
    this.totalBreakHours,
    this.netWorkingMinutes,
    this.netWorkingHours,
  });

  HrmTopListReport.fromJson(Map<String, dynamic> json) {
    empId = json['EmpId'];
    empName = json['EmpName'];
    totalDays = json['TotalDays'];
    totalOfficeMinutes = json['TotalOfficeMinutes'];
    totalOfficeHours = json['TotalOfficeHours'];
    totalBreakMinutes = json['TotalBreakMinutes'];
    totalBreakHours = json['TotalBreakHours'];
    netWorkingMinutes = json['NetWorkingMinutes'];
    netWorkingHours = json['NetWorkingHours'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['EmpId'] = empId;
    data['EmpName'] = empName;
    data['TotalDays'] = totalDays;
    data['TotalOfficeMinutes'] = totalOfficeMinutes;
    data['TotalOfficeHours'] = totalOfficeHours;
    data['TotalBreakMinutes'] = totalBreakMinutes;
    data['TotalBreakHours'] = totalBreakHours;
    data['NetWorkingMinutes'] = netWorkingMinutes;
    data['NetWorkingHours'] = netWorkingHours;
    return data;
  }
}
