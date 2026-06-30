// To parse this JSON data, do
//
//     final payRollUpload = payRollUploadFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

PayRollUpload payRollUploadFromJson(String str) => PayRollUpload.fromJson(json.decode(str));

String payRollUploadToJson(PayRollUpload data) => json.encode(data.toJson());
class PayRollUpload {
  String? flag;
  bool? success;
  dynamic attendence;
  dynamic attendenceLogs;
  dynamic attendenceLog;
  dynamic holiday;
  dynamic leavesTypes;
  dynamic salaryStructure;
  dynamic empLeave;
  dynamic empShiftGroup;
  dynamic event;
  dynamic shiftMst;
  dynamic recruitment;
  dynamic assetMst;
  dynamic salaryAdditionDedection;
  dynamic paySlip;
  List<PAttendence>? pAttendence;

  PayRollUpload(
      {this.flag,
      this.success,
      this.attendence,
      this.attendenceLogs,
      this.attendenceLog,
      this.holiday,
      this.leavesTypes,
      this.salaryStructure,
      this.empLeave,
      this.empShiftGroup,
      this.event,
      this.shiftMst,
      this.recruitment,
      this.assetMst,
      this.salaryAdditionDedection,
      this.paySlip,
      this.pAttendence});

  PayRollUpload.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'];
    success = json['Success'];
    attendence = json['Attendence'];
    attendenceLogs = json['AttendenceLogs'];
    attendenceLog = json['AttendenceLog'];
    holiday = json['Holiday'];
    leavesTypes = json['LeavesTypes'];
    salaryStructure = json['SalaryStructure'];
    empLeave = json['EmpLeave'];
    empShiftGroup = json['EmpShiftGroup'];
    event = json['Event'];
    shiftMst = json['ShiftMst'];
    recruitment = json['Recruitment'];
    assetMst = json['AssetMst'];
    salaryAdditionDedection = json['SalaryAdditionDedection'];
    paySlip = json['PaySlip'];
    if (json['PAttendence'] != null) {
      pAttendence = <PAttendence>[];
      json['PAttendence'].forEach((v) {
        pAttendence!.add(PAttendence.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Flag'] = flag;
    data['Success'] = success;
    data['Attendence'] = attendence;
    data['AttendenceLogs'] = attendenceLogs;
    data['AttendenceLog'] = attendenceLog;
    data['Holiday'] = holiday;
    data['LeavesTypes'] = leavesTypes;
    data['SalaryStructure'] = salaryStructure;
    data['EmpLeave'] = empLeave;
    data['EmpShiftGroup'] = empShiftGroup;
    data['Event'] = event;
    data['ShiftMst'] = shiftMst;
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    data['SalaryAdditionDedection'] = salaryAdditionDedection;
    data['PaySlip'] = paySlip;
    if (pAttendence != null) {
      data['PAttendence'] = pAttendence!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PAttendence {
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
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;

  PAttendence(
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

  PAttendence.fromJson(Map<String, dynamic> json) {
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
    final Map<String, dynamic> data = Map<String, dynamic>();
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
