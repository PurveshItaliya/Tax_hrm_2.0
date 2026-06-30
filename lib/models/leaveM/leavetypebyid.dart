// To parse this JSON data, do
//
//     final leaveTypeByid = leaveTypeByidFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

LeaveTypeByid leaveTypeByidFromJson(String str) => LeaveTypeByid.fromJson(json.decode(str));

String leaveTypeByidToJson(LeaveTypeByid data) => json.encode(data.toJson());


class LeaveTypeByid {
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
  dynamic policyIssueDate;
  String? description;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;

  LeaveTypeByid(
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
      this.custId});

  LeaveTypeByid.fromJson(Map<String, dynamic> json) {
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
    return data;
  }
}
