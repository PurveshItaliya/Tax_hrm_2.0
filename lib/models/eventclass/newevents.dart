// To parse this JSON data, do
//
//     final newEvents = newEventsFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

NewEvents newEventsFromJson(String str) => NewEvents.fromJson(json.decode(str));

String newEventsToJson(NewEvents data) => json.encode(data.toJson());

class NewEvents {
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
  Event? event;
  dynamic shiftMst;
  dynamic recruitment;
  dynamic assetMst;

  NewEvents({
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
  });

  NewEvents.fromJson(Map<String, dynamic> json) {
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
    event = json['Event'] != null ? Event.fromJson(json['Event']) : null;
    shiftMst = json['ShiftMst'] ?? "";
    recruitment = json['Recruitment'] ?? "";
    assetMst = json['AssetMst'] ?? "";
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
    if (event != null) {
      data['Event'] = event!.toJson();
    }
    data['ShiftMst'] = shiftMst;
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    return data;
  }
}

class Event {
  int? eventId;
  String? eventName;
  int? companyId;
  String? startDate;
  String? endDate;
  String? eventPlace;
  String? description;
  String? cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic custId;

  Event({
    this.eventId,
    this.eventName,
    this.companyId,
    this.startDate,
    this.endDate,
    this.eventPlace,
    this.description,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
  });

  Event.fromJson(Map<String, dynamic> json) {
    eventId = json['EventId'] ?? 0;
    eventName = json['EventName'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    startDate = json['StartDate'] ?? "";
    endDate = json['EndDate'] ?? "";
    eventPlace = json['EventPlace'] ?? "";
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
    data['EventId'] = eventId;
    data['EventName'] = eventName;
    data['CompanyId'] = companyId;
    data['StartDate'] = startDate;
    data['EndDate'] = endDate;
    data['EventPlace'] = eventPlace;
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
