// To parse this JSON data, do
//
//     final getLeaveMaster = getLeaveMasterFromJson(jsonString);

import 'dart:convert';

List<GetLeaveMaster> getLeaveMasterFromJson(String str) =>
    List<GetLeaveMaster>.from(
      json.decode(str).map((x) => GetLeaveMaster.fromJson(x)),
    );

String getLeaveMasterToJson(List<GetLeaveMaster> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetLeaveMaster {
  int? leaveTypeId;
  int? companyId;
  String? leaveTypeFName;
  String? leaveTypeSName;
  int? carryForward;
  int? yearlyLimit;
  int? monthly;
  int? quarterly;
  bool? considerWeeklyOff;
  bool? considerHoliday;
  String? policyIssueDate;
  String? description;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  dynamic leaveLimit;
  dynamic halfYear;
  dynamic leaveType;

  GetLeaveMaster({
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
    this.policyIssueDate,
    this.description,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.leaveLimit,
    this.halfYear,
    this.leaveType,
  });

  GetLeaveMaster.fromJson(Map<String, dynamic> json) {
    leaveTypeId = json['LeaveTypeId'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    leaveTypeFName = json['LeaveTypeFName'] ?? "";
    leaveTypeSName = json['LeaveTypeSName'] ?? "";
    carryForward = json['CarryForward'] ?? 0;
    yearlyLimit = json['YearlyLimit'] ?? 0;
    monthly = json['Monthly'] ?? 0;
    quarterly = json['Quarterly'] ?? 0;
    considerWeeklyOff = json['ConsiderWeeklyOff'] ?? false;
    considerHoliday = json['ConsiderHoliday'] ?? false;
    policyIssueDate = json['PolicyIssueDate'] ?? "";
    description = json['Description'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
    leaveLimit = json['LeaveLimit'] ?? "";
    halfYear = json['HalfYear'] ?? "";
    leaveType = json['LeaveType'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
    data['PolicyIssueDate'] = policyIssueDate;
    data['Description'] = description;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['LeaveLimit'] = leaveLimit;
    data['HalfYear'] = halfYear;
    data['LeaveType'] = leaveType;
    return data;
  }
}
