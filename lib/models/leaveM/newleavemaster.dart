// To parse this JSON data, do
//
//     final newLeaveTypes = newLeaveTypesFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

NewLeaveTypes newLeaveTypesFromJson(String str) =>
    NewLeaveTypes.fromJson(json.decode(str));

String newLeaveTypesToJson(NewLeaveTypes data) => json.encode(data.toJson());

class NewLeaveTypes {
  String? flag;
  bool? success;
  dynamic attendence;
  dynamic attendenceLog;
  dynamic holiday;
  LeavesTypes? leavesTypes;
  dynamic salaryStructure;
  dynamic empLeave;
  dynamic empShiftGroup;

  NewLeaveTypes({
    this.flag,
    this.success,
    this.attendence,
    this.attendenceLog,
    this.holiday,
    this.leavesTypes,
    this.salaryStructure,
    this.empLeave,
    this.empShiftGroup,
  });

  NewLeaveTypes.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'] ?? "";
    success = json['Success'] ?? false;
    attendence = json['Attendence'] ?? "";
    attendenceLog = json['AttendenceLog'] ?? "";
    holiday = json['Holiday'] ?? "";
    leavesTypes = json['LeavesTypes'] != null
        ? LeavesTypes.fromJson(json['LeavesTypes'])
        : null;
    salaryStructure = json['SalaryStructure'] ?? "";
    empLeave = json['EmpLeave'] ?? "";
    empShiftGroup = json['EmpShiftGroup'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Flag'] = flag;
    data['Success'] = success;
    data['Attendence'] = attendence;
    data['AttendenceLog'] = attendenceLog;
    data['Holiday'] = holiday;
    if (leavesTypes != null) {
      data['LeavesTypes'] = leavesTypes!.toJson();
    }
    data['SalaryStructure'] = salaryStructure;
    data['EmpLeave'] = empLeave;
    data['EmpShiftGroup'] = empShiftGroup;
    return data;
  }
}

class LeavesTypes {
  int? leaveTypeId;
  int? companyId;
  String? leaveTypeFName;
  String? leaveTypeSName;
  int? carryForward;
  int? yearlyLimit;
  dynamic monthly;
  dynamic quarterly;
  bool? considerWeeklyOff;
  bool? considerHoliday;
  String? description;
  String? cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic custId;

  LeavesTypes({
    this.leaveTypeId,
    this.companyId,
    this.leaveTypeFName,
    this.leaveTypeSName,
    this.carryForward,
    this.yearlyLimit,
    this.monthly,
    this.quarterly,
    this.considerWeeklyOff,
    this.considerHoliday,
    this.description,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
  });

  LeavesTypes.fromJson(Map<String, dynamic> json) {
    leaveTypeId = json['LeaveTypeId'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    leaveTypeFName = json['LeaveTypeFName'] ?? "";
    leaveTypeSName = json['LeaveTypeSName'] ?? "";
    carryForward = json['CarryForward'] ?? 0;
    yearlyLimit = json['YearlyLimit'] ?? 0;
    monthly = json['Monthly'] ?? "";
    quarterly = json['Quarterly'] ?? "";
    considerWeeklyOff = json['ConsiderWeeklyOff'] ?? false;
    considerHoliday = json['ConsiderHoliday'] ?? false;
    description = json['Description'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['LeaveTypeId'] = leaveTypeId;
    data['CompanyId'] = companyId;
    data['LeaveTypeFName'] = leaveTypeFName;
    data['LeaveTypeSName'] = leaveTypeSName;
    data['CarryForward'] = carryForward;
    data['YearlyLimit'] = yearlyLimit;
    data['Monthly'] = monthly;
    data['Quarterly'] = quarterly;
    data['ConsiderWeeklyOff'] = considerWeeklyOff;
    data['ConsiderHoliday'] = considerHoliday;
    data['Description'] = description;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    return data;
  }
}
