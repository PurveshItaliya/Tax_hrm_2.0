// To parse this JSON data, do
//
//     final shiftGroupCreate = shiftGroupCreateFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

ShiftGroupCreate shiftGroupCreateFromJson(String str) =>
    ShiftGroupCreate.fromJson(json.decode(str));

String shiftGroupCreateToJson(ShiftGroupCreate data) =>
    json.encode(data.toJson());

class ShiftGroupCreate {
  String? flag;
  bool? success;
  dynamic attendence;
  dynamic attendenceLog;
  dynamic holiday;
  dynamic leavesTypes;
  dynamic salaryStructure;
  dynamic empLeave;
  EmpShiftGroup? empShiftGroup;
  dynamic event;
  dynamic shiftMst;
  dynamic recruitment;
  dynamic assetMst;

  ShiftGroupCreate({
    this.flag,
    this.success,
    this.attendence,
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
  });

  ShiftGroupCreate.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'] ?? "";
    success = json['Success'] ?? false;
    attendence = json['Attendence'] ?? "";
    attendenceLog = json['AttendenceLog'] ?? "";
    holiday = json['Holiday'] ?? "";
    leavesTypes = json['LeavesTypes'] ?? "";
    salaryStructure = json['SalaryStructure'] ?? "";
    empLeave = json['EmpLeave'] ?? "";
    empShiftGroup = json['EmpShiftGroup'] != null
        ? EmpShiftGroup.fromJson(json['EmpShiftGroup'])
        : null;
    event = json['Event'] ?? "";
    shiftMst = json['ShiftMst'] ?? "";
    recruitment = json['Recruitment'] ?? "";
    assetMst = json['AssetMst'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Flag'] = flag;
    data['Success'] = success;
    data['Attendence'] = attendence;
    data['AttendenceLog'] = attendenceLog;
    data['Holiday'] = holiday;
    data['LeavesTypes'] = leavesTypes;
    data['SalaryStructure'] = salaryStructure;
    data['EmpLeave'] = empLeave;
    if (empShiftGroup != null) {
      data['EmpShiftGroup'] = empShiftGroup!.toJson();
    }
    data['Event'] = event;
    data['ShiftMst'] = shiftMst;
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    return data;
  }
}

class EmpShiftGroup {
  int? shiftGroupID;
  String? shiftGroupFname;
  int? companyId;
  String? shiftGroupSname;
  String? cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic custId;

  EmpShiftGroup({
    this.shiftGroupID,
    this.shiftGroupFname,
    this.companyId,
    this.shiftGroupSname,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
  });

  EmpShiftGroup.fromJson(Map<String, dynamic> json) {
    shiftGroupID = json['ShiftGroupID'] ?? 0;
    shiftGroupFname = json['ShiftGroupFname'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    shiftGroupSname = json['ShiftGroupSname'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ShiftGroupID'] = shiftGroupID;
    data['ShiftGroupFname'] = shiftGroupFname;
    data['CompanyId'] = companyId;
    data['ShiftGroupSname'] = shiftGroupSname;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    return data;
  }
}
