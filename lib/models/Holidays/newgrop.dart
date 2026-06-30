// To parse this JSON data, do
//
//     final newHolidayCreate = newHolidayCreateFromJson(jsonString);

import 'dart:convert';

NewHolidayCreate newHolidayCreateFromJson(String str) =>
    NewHolidayCreate.fromJson(json.decode(str));

String newHolidayCreateToJson(NewHolidayCreate data) =>
    json.encode(data.toJson());

class NewHolidayCreate {
  String? flag;
  bool? success;
  dynamic attendence;
  dynamic attendenceLogs;
  dynamic attendenceLog;
  Holiday? holiday;
  dynamic leavesTypes;
  dynamic salaryStructure;
  dynamic empLeave;
  dynamic empShiftGroup;
  dynamic event;
  dynamic shiftMst;
  dynamic recruitment;
  dynamic assetMst;
  dynamic salaryAdditionDedection;
  dynamic addDedMst;
  dynamic addDedDetail;
  dynamic paySlip;
  dynamic pAttendence;

  NewHolidayCreate({
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
    this.addDedMst,
    this.addDedDetail,
    this.paySlip,
    this.pAttendence,
  });

  NewHolidayCreate.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'] ?? "";
    success = json['Success'] ?? false;
    attendence = json['Attendence'] ?? "";
    attendenceLogs = json['AttendenceLogs'] ?? "";
    attendenceLog = json['AttendenceLog'] ?? "";
    holiday = json['Holiday'] != null
        ? Holiday.fromJson(json['Holiday'])
        : null;
    leavesTypes = json['LeavesTypes'] ?? "";
    salaryStructure = json['SalaryStructure'] ?? "";
    empLeave = json['EmpLeave'] ?? "";
    empShiftGroup = json['EmpShiftGroup'] ?? "";
    event = json['Event'] ?? "";
    shiftMst = json['ShiftMst'] ?? "";
    recruitment = json['Recruitment'] ?? "";
    assetMst = json['AssetMst'] ?? "";
    salaryAdditionDedection = json['SalaryAdditionDedection'] ?? "";
    addDedMst = json['AddDedMst'] ?? "";
    addDedDetail = json['AddDedDetail'] ?? "";
    paySlip = json['PaySlip'] ?? "";
    pAttendence = json['PAttendence'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Flag'] = flag;
    data['Success'] = success;
    data['Attendence'] = attendence;
    data['AttendenceLogs'] = attendenceLogs;
    data['AttendenceLog'] = attendenceLog;
    if (holiday != null) {
      data['Holiday'] = holiday!.toJson();
    }
    data['LeavesTypes'] = leavesTypes;
    data['SalaryStructure'] = salaryStructure;
    data['EmpLeave'] = empLeave;
    data['EmpShiftGroup'] = empShiftGroup;
    data['Event'] = event;
    data['ShiftMst'] = shiftMst;
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    data['SalaryAdditionDedection'] = salaryAdditionDedection;
    data['AddDedMst'] = addDedMst;
    data['AddDedDetail'] = addDedDetail;
    data['PaySlip'] = paySlip;
    data['PAttendence'] = pAttendence;
    return data;
  }
}

class Holiday {
  int? holidayId;
  String? holidayName;
  int? companyId;
  List<String>? holidayDate;
  String? description;
  dynamic holidayGroup;
  dynamic cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic custId;
  String? holidayType;
  bool? ismultiple;
  String? enddate;
  String? masterCguid;

  Holiday({
    this.holidayId,
    this.holidayName,
    this.companyId,
    this.holidayDate,
    this.description,
    this.holidayGroup,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.holidayType,
    this.ismultiple,
    this.enddate,
    this.masterCguid,
  });

  Holiday.fromJson(Map<String, dynamic> json) {
    holidayId = json['HolidayId'] ?? 0;
    holidayName = json['HolidayName'] ?? '';
    companyId = json['CompanyId'] ?? 0;
    holidayDate = json['HolidayDate'].cast<String>() ?? [];
    description = json['Description'] ?? '';
    holidayGroup = json['HolidayGroup'] ?? '';
    cguid = json['Cguid'] ?? '';
    flag = json['Flag'] ?? '';
    iPAddress = json['IPAddress'] ?? '';
    serverName = json['ServerName'] ?? '';
    entryTime = json['EntryTime'] ?? '';
    custId = json['CustId'] ?? '';
    holidayType = json['HolidayType'] ?? '';
    ismultiple = json['ismultiple'] ?? false;
    enddate = json['Enddate'] ?? '';
    masterCguid = json['MasterCguid'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['HolidayId'] = holidayId;
    data['HolidayName'] = holidayName;
    data['CompanyId'] = companyId;
    data['HolidayDate'] = holidayDate;
    data['Description'] = description;
    data['HolidayGroup'] = holidayGroup;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['HolidayType'] = holidayType;
    data['ismultiple'] = ismultiple;
    data['Enddate'] = enddate;
    data['MasterCguid'] = masterCguid;
    return data;
  }
}
