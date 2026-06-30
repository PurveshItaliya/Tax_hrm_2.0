// To parse this JSON data, do
//
//     final createAdditionModal = createAdditionModalFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

CreateAdditionModal createAdditionModalFromJson(String str) =>
    CreateAdditionModal.fromJson(json.decode(str));

String createAdditionModalToJson(CreateAdditionModal data) =>
    json.encode(data.toJson());

class CreateAdditionModal {
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
  SalaryAdditionDedection? salaryAdditionDedection;
  dynamic paySlip;
  dynamic pAttendence;

  CreateAdditionModal({
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

  CreateAdditionModal.fromJson(Map<String, dynamic> json) {
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
    shiftMst = json['ShiftMst'] ?? "";
    recruitment = json['Recruitment'] ?? "";
    assetMst = json['AssetMst'] ?? "";
    salaryAdditionDedection = json['SalaryAdditionDedection'] != null
        ? SalaryAdditionDedection.fromJson(json['SalaryAdditionDedection'])
        : null;
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
    data['ShiftMst'] = shiftMst;
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    if (salaryAdditionDedection != null) {
      data['SalaryAdditionDedection'] = salaryAdditionDedection!.toJson();
    }
    data['PaySlip'] = paySlip;
    data['PAttendence'] = pAttendence;
    return data;
  }
}

class SalaryAdditionDedection {
  int? earningId;
  int? companyId;
  String? name;
  String? type;
  double? amount;
  dynamic percentage;
  String? remarks;
  String? userName;
  dynamic userId;
  String? cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  int? empId;
  String? deductionDate;
  dynamic empName;

  SalaryAdditionDedection({
    this.earningId,
    this.companyId,
    this.name,
    this.type,
    this.amount,
    this.percentage,
    this.remarks,
    this.userName,
    this.userId,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.empId,
    this.deductionDate,
    this.empName,
  });

  SalaryAdditionDedection.fromJson(Map<String, dynamic> json) {
    earningId = json['EarningId'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    name = json['Name'] ?? "";
    type = json['Type'] ?? "";
    amount = json['Amount'] ?? 0.0;
    percentage = json['Percentage'] ?? "";
    remarks = json['Remarks'] ?? "";
    userName = json['UserName'] ?? "";
    userId = json['UserId'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    empId = json['EmpId'] ?? 0;
    deductionDate = json['DeductionDate'] ?? "";
    empName = json['EmpName'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['EarningId'] = earningId;
    data['CompanyId'] = companyId;
    data['Name'] = name;
    data['Type'] = type;
    data['Amount'] = amount;
    data['Percentage'] = percentage;
    data['Remarks'] = remarks;
    data['UserName'] = userName;
    data['UserId'] = userId;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['EmpId'] = empId;
    data['DeductionDate'] = deductionDate;
    data['EmpName'] = empName;
    return data;
  }
}
