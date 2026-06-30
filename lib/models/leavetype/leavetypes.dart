// To parse this JSON data, do
//
//     final leaveTypes = leaveTypesFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<LeaveTypes> leaveTypesFromJson(String str) => List<LeaveTypes>.from(json.decode(str).map((x) => LeaveTypes.fromJson(x)));

String leaveTypesToJson(List<LeaveTypes> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LeaveTypes {
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
  String? leaveLimit;
  int? halfYear;
  dynamic leaveType;

  LeaveTypes(
      {this.leaveTypeId,
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
      this.leaveType});

  LeaveTypes.fromJson(Map<String, dynamic> json) {
    leaveTypeId = json['LeaveTypeId'];
    companyId = json['CompanyId'];
    leaveTypeFName = json['LeaveTypeFName'];
    leaveTypeSName = json['LeaveTypeSName'];
    carryForward = json['CarryForward'];
    yearlyLimit = json['YearlyLimit'];
    monthly = json['Monthly'];
    quarterly = json['Quarterly'];
    considerWeeklyOff = json['ConsiderWeeklyOff'];
    considerHoliday = json['ConsiderHoliday'];
    policyIssueDate = json['PolicyIssueDate'];
    description = json['Description'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    leaveLimit = json['LeaveLimit'];
    halfYear = json['HalfYear'];
    leaveType = json['LeaveType'];
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
