// To parse this JSON data, do
//
//     final allEmployeAttendance = allEmployeAttendanceFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<AllEmployeAttendance> allEmployeAttendanceFromJson(String str) => List<AllEmployeAttendance>.from(json.decode(str).map((x) => AllEmployeAttendance.fromJson(x)));

String allEmployeAttendanceToJson(List<AllEmployeAttendance> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class AllEmployeAttendance {
  int? attendenceID;
  String? attendenceDate;
  int? companyId;
  int? empId;
  String? inTime;
  dynamic outTime;
  dynamic isOnLeave;
  dynamic lateBy;
  dynamic earlyBy;
  dynamic leaveType;
  dynamic holiday;
  dynamic leaveId;
  dynamic shiftId;
  bool? present;
  bool? absent;
  String? cguid;
  dynamic longitude;
  dynamic latitude;
  dynamic location;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  String? firstName;
  String? lastName;
  dynamic entryTime;
  dynamic custId;
  dynamic device;
  dynamic leaveCguid;
  dynamic shiftmstCguid;
  dynamic todayAbsent;
  dynamic time;
  dynamic status;
  dynamic leaveTypeFName;
  dynamic leaveTypeCguid;
  dynamic totalMinute;
  dynamic leaveGroup;
  int? departmentId;
  String? departmentName;

  AllEmployeAttendance(
      {this.attendenceID,
      this.attendenceDate,
      this.companyId,
      this.empId,
      this.inTime,
      this.outTime,
      this.isOnLeave,
      this.lateBy,
      this.earlyBy,
      this.leaveType,
      this.holiday,
      this.leaveId,
      this.shiftId,
      this.present,
      this.absent,
      this.cguid,
      this.longitude,
      this.latitude,
      this.location,
      this.flag,
      this.iPAddress,
      this.serverName,
      this.firstName,
      this.lastName,
      this.entryTime,
      this.custId,
      this.device,
      this.leaveCguid,
      this.shiftmstCguid,
      this.todayAbsent,
      this.time,
      this.status,
      this.leaveTypeFName,
      this.leaveTypeCguid,
      this.totalMinute,
      this.leaveGroup,
      this.departmentId,
      this.departmentName});

  AllEmployeAttendance.fromJson(Map<String, dynamic> json) {
    attendenceID = json['AttendenceID'];
    attendenceDate = json['AttendenceDate'];
    companyId = json['CompanyId'];
    empId = json['EmpId'];
    inTime = json['InTime'];
    outTime = json['OutTime'];
    isOnLeave = json['IsOnLeave'];
    lateBy = json['LateBy'];
    earlyBy = json['EarlyBy'];
    leaveType = json['LeaveType'];
    holiday = json['Holiday'];
    leaveId = json['LeaveId'];
    shiftId = json['ShiftId'];
    present = json['Present'];
    absent = json['Absent'];
    cguid = json['Cguid'];
    longitude = json['Longitude'];
    latitude = json['Latitude'];
    location = json['Location'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    device = json['Device'];
    leaveCguid = json['LeaveCguid'];
    shiftmstCguid = json['ShiftmstCguid'];
    todayAbsent = json['TodayAbsent'];
    time = json['Time'];
    status = json['Status'];
    leaveTypeFName = json['LeaveTypeFName'];
    leaveTypeCguid = json['LeaveTypeCguid'];
    totalMinute = json['TotalMinute'];
    leaveGroup = json['LeaveGroup'];
    departmentId = json['DepartmentId'];
    departmentName = json['DepartmentName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['AttendenceID'] = attendenceID;
    data['AttendenceDate'] = attendenceDate;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['InTime'] = inTime;
    data['OutTime'] = outTime;
    data['IsOnLeave'] = isOnLeave;
    data['LateBy'] = lateBy;
    data['EarlyBy'] = earlyBy;
    data['LeaveType'] = leaveType;
    data['Holiday'] = holiday;
    data['LeaveId'] = leaveId;
    data['ShiftId'] = shiftId;
    data['Present'] = present;
    data['Absent'] = absent;
    data['Cguid'] = cguid;
    data['Longitude'] = longitude;
    data['Latitude'] = latitude;
    data['Location'] = location;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['FirstName'] = firstName;
    data['LastName'] = lastName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['Device'] = device;
    data['LeaveCguid'] = leaveCguid;
    data['ShiftmstCguid'] = shiftmstCguid;
    data['TodayAbsent'] = todayAbsent;
    data['Time'] = time;
    data['Status'] = status;
    data['LeaveTypeFName'] = leaveTypeFName;
    data['LeaveTypeCguid'] = leaveTypeCguid;
    data['TotalMinute'] = totalMinute;
    data['LeaveGroup'] = leaveGroup;
    data['DepartmentId'] = departmentId;
    data['DepartmentName'] = departmentName;
    return data;
  }
}
