// To parse this JSON data, do
//
//     final leaveListData = leaveListDataFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<LeaveListData> leaveListDataFromJson(String str) => List<LeaveListData>.from(json.decode(str).map((x) => LeaveListData.fromJson(x)));

String leaveListDataToJson(List<LeaveListData> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class LeaveListData {
  int? empLeaveId;
  int? companyId;
  int? empId;
  int? leaveTypeId;
  String? leaveTypeCguid;
  String? fromDate;
  String? toDate;
  String? remarks;
  String? leaveYear;
  String? leaveTypeFName;
  String? leaveDuration;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  String? approveStatus;
  String? dayType;
  double? gainLeave;
  double? usedLeave;
  double? eligibleLeave;
  String? firstName;
  String? lastName;

  LeaveListData(
      {this.empLeaveId,
      this.companyId,
      this.empId,
      this.leaveTypeId,
      this.leaveTypeCguid,
      this.fromDate,
      this.toDate,
      this.remarks,
      this.leaveYear,
      this.leaveTypeFName,
      this.leaveDuration,
      this.cguid,
      this.flag,
      this.iPAddress,
      this.serverName,
      this.entryTime,
      this.custId,
      this.approveStatus,
      this.dayType,
      this.gainLeave,
      this.usedLeave,
      this.eligibleLeave,
      this.firstName,
      this.lastName});

  LeaveListData.fromJson(Map<String, dynamic> json) {
    empLeaveId = json['EmpLeaveId'];
    companyId = json['CompanyId'];
    empId = json['EmpId'];
    leaveTypeId = json['LeaveTypeId'];
    leaveTypeCguid = json['LeaveTypeCguid'];
    fromDate = json['FromDate'];
    toDate = json['ToDate'];
    remarks = json['Remarks'];
    leaveYear = json['LeaveYear'];
    leaveTypeFName = json['LeaveTypeFName'];
    leaveDuration = json['LeaveDuration'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    approveStatus = json['ApproveStatus'];
    dayType = json['DayType'];
    gainLeave = json['GainLeave'];
    usedLeave = json['UsedLeave'];
    eligibleLeave = json['EligibleLeave'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['EmpLeaveId'] = empLeaveId;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['LeaveTypeId'] = leaveTypeId;
    data['LeaveTypeCguid'] = leaveTypeCguid;
    data['FromDate'] = fromDate;
    data['ToDate'] = toDate;
    data['Remarks'] = remarks;
    data['LeaveYear'] = leaveYear;
    data['LeaveTypeFName'] = leaveTypeFName;
    data['LeaveDuration'] = leaveDuration;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['ApproveStatus'] = approveStatus;
    data['DayType'] = dayType;
    data['GainLeave'] = gainLeave;
    data['UsedLeave'] = usedLeave;
    data['EligibleLeave'] = eligibleLeave;
    data['FirstName'] = firstName;
    data['LastName'] = lastName;
    return data;
  }
}

