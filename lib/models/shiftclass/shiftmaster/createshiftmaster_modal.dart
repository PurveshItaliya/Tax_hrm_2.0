// To parse this JSON data, do
//
//     final shiftMasterCreate = shiftMasterCreateFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

ShiftMasterCreate shiftMasterCreateFromJson(String str) =>
    ShiftMasterCreate.fromJson(json.decode(str));

String shiftMasterCreateToJson(ShiftMasterCreate data) =>
    json.encode(data.toJson());

class ShiftMasterCreate {
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
  ShiftMst? shiftMst;
  dynamic recruitment;
  dynamic assetMst;
  dynamic salaryAdditionDedection;
  dynamic paySlip;
  dynamic pAttendence;

  ShiftMasterCreate({
    this.flag,
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
    this.pAttendence,
  });

  ShiftMasterCreate.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'] ?? "";
    success = json['Success'] ?? false;
    attendence = json['Attendence'] ?? "";
    attendenceLogs = json['AttendenceLogs'] ?? "";
    attendenceLog = json['AttendenceLog'] ?? "";
    holiday = json['Holiday'] ?? "";
    leavesTypes = json['LeavesTypes'] ?? "";
    salaryStructure = json['SalaryStructure'] ?? "";
    empLeave = json['EmpLeave'] ?? "";
    empShiftGroup = json['EmpShiftGroup'] ?? "";
    event = json['Event'] ?? "";
    shiftMst = json['ShiftMst'] != null
        ? ShiftMst.fromJson(json['ShiftMst'])
        : null;
    recruitment = json['Recruitment'] ?? "";
    assetMst = json['AssetMst'] ?? "";
    salaryAdditionDedection = json['SalaryAdditionDedection'] ?? "";
    paySlip = json['PaySlip'] ?? "";
    pAttendence = json['PAttendence'] ?? "";
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
    if (shiftMst != null) {
      data['ShiftMst'] = shiftMst!.toJson();
    }
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    data['SalaryAdditionDedection'] = salaryAdditionDedection;
    data['PaySlip'] = paySlip;
    data['PAttendence'] = pAttendence;
    return data;
  }
}

class ShiftMst {
  int? shiftID;
  int? companyId;
  String? shiftFName;
  String? shiftSName;
  dynamic beginTime;
  dynamic endTime;
  bool? break1;
  bool? break2;
  dynamic break1BeginTime;
  dynamic break2BeginTime;
  dynamic break1EndTime;
  dynamic break2EndTime;
  String? shiftDuration;
  String? break1Duration;
  String? break2Duration;
  String? shiftType;
  dynamic departmentId;
  int? positionId;
  bool? mon;
  bool? tue;
  bool? wed;
  bool? thu;
  bool? fri;
  bool? sat;
  bool? sun;
  String? cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic shiftGroupGuid;
  dynamic entryTime;
  dynamic custId;
  dynamic positionName;

  ShiftMst({
    this.shiftID,
    this.companyId,
    this.shiftFName,
    this.shiftSName,
    this.beginTime,
    this.endTime,
    this.break1,
    this.break2,
    this.break1BeginTime,
    this.break2BeginTime,
    this.break1EndTime,
    this.break2EndTime,
    this.shiftDuration,
    this.break1Duration,
    this.break2Duration,
    this.shiftType,
    this.departmentId,
    this.positionId,
    this.mon,
    this.tue,
    this.wed,
    this.thu,
    this.fri,
    this.sat,
    this.sun,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.shiftGroupGuid,
    this.entryTime,
    this.custId,
    this.positionName,
  });

  ShiftMst.fromJson(Map<String, dynamic> json) {
    shiftID = json['ShiftID'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    shiftFName = json['ShiftFName'] ?? "";
    shiftSName = json['ShiftSName'] ?? "";
    beginTime = json['BeginTime'] ?? "";
    endTime = json['EndTime'] ?? "";
    break1 = json['Break1'] ?? false;
    break2 = json['Break2'] ?? false;
    break1BeginTime = json['Break1BeginTime'] ?? "";
    break2BeginTime = json['Break2BeginTime'] ?? "";
    break1EndTime = json['Break1EndTime'] ?? "";
    break2EndTime = json['Break2EndTime'] ?? "";
    shiftDuration = json['ShiftDuration'] ?? "";
    break1Duration = json['Break1Duration'] ?? "";
    break2Duration = json['Break2Duration'] ?? "";
    shiftType = json['ShiftType'] ?? "";
    departmentId = json['DepartmentId'] ?? "";
    positionId = json['PositionId'] ?? 0;
    mon = json['Mon'] ?? false;
    tue = json['Tue'] ?? false;
    wed = json['Wed'] ?? false;
    thu = json['Thu'] ?? false;
    fri = json['Fri'] ?? false;
    sat = json['Sat'] ?? false;
    sun = json['Sun'] ?? false;
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    shiftGroupGuid = json['ShiftGroupGuid'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
    positionName = json['PositionName'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ShiftID'] = shiftID;
    data['CompanyId'] = companyId;
    data['ShiftFName'] = shiftFName;
    data['ShiftSName'] = shiftSName;
    data['BeginTime'] = beginTime;
    data['EndTime'] = endTime;
    data['Break1'] = break1;
    data['Break2'] = break2;
    data['Break1BeginTime'] = break1BeginTime;
    data['Break2BeginTime'] = break2BeginTime;
    data['Break1EndTime'] = break1EndTime;
    data['Break2EndTime'] = break2EndTime;
    data['ShiftDuration'] = shiftDuration;
    data['Break1Duration'] = break1Duration;
    data['Break2Duration'] = break2Duration;
    data['ShiftType'] = shiftType;
    data['DepartmentId'] = departmentId;
    data['PositionId'] = positionId;
    data['Mon'] = mon;
    data['Tue'] = tue;
    data['Wed'] = wed;
    data['Thu'] = thu;
    data['Fri'] = fri;
    data['Sat'] = sat;
    data['Sun'] = sun;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['ShiftGroupGuid'] = shiftGroupGuid;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['PositionName'] = positionName;
    return data;
  }
}
