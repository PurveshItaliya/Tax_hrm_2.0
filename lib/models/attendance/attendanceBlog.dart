// To parse this JSON data, do
//
//     final attendanceDayBlog = attendanceDayBlogFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

AttendanceDayBlog attendanceDayBlogFromJson(String str) =>
    AttendanceDayBlog.fromJson(json.decode(str));

String attendanceDayBlogToJson(AttendanceDayBlog data) =>
    json.encode(data.toJson());

class AttendanceDayBlog {
  dynamic flag;
  bool? success;
  Attendence? attendence;
  List<AttendenceLog>? attendenceLog;
  dynamic holiday;
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

  AttendanceDayBlog({
    this.flag,
    this.success,
    this.attendence,
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

  AttendanceDayBlog.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'] ?? "";
    success = json['Success'] ?? false;
    attendence = json['Attendence'] != null
        ? Attendence.fromJson(json['Attendence'])
        : null;
    if (json['AttendenceLog'] != null) {
      attendenceLog = <AttendenceLog>[];
      json['AttendenceLog'].forEach((v) {
            attendenceLog!.add(AttendenceLog.fromJson(v));
          }) ??
          [];
    }
    holiday = json['Holiday'] ?? "";
    leavesTypes = json['LeavesTypes'] ?? "";
    salaryStructure = json['SalaryStructure'] ?? "";
    empLeave = json['EmpLeave'] ?? "";
    empShiftGroup = json['EmpShiftGroup'] ?? "";
    event = json['Event'] ?? "";
    shiftMst = json['ShiftMst'] ?? "";
    recruitment = json['Recruitment'] ?? "";
    assetMst = json['AssetMst'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Flag'] = flag;
    data['Success'] = success;
    if (attendence != null) {
      data['Attendence'] = attendence!.toJson();
    }
    if (attendenceLog != null) {
      data['AttendenceLog'] = attendenceLog!.map((v) => v.toJson()).toList();
    }
    data['Holiday'] = holiday;
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

class Attendence {
  int? attendenceID;
  String? attendenceDate;
  int? companyId;
  int? empId;
  String? inTime;
  String? outTime;
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
  String? flag;
  String? iPAddress;
  String? serverName;
  String? firstName;
  dynamic lastName;
  String? entryTime;
  String? custId;
  String? device;
  dynamic leaveCguid;
  dynamic shiftmstCguid;
  dynamic todayAbsent;
  dynamic weekOff;
  dynamic time;
  dynamic status;
  dynamic leaveTypeFName;
  dynamic leaveTypeCguid;
  String? totalMinute;
  dynamic leaveGroup;
  int? departmentId;
  dynamic departmentName;
  dynamic leaveDuration;

  Attendence({
    this.attendenceID,
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
    this.weekOff,
    this.time,
    this.status,
    this.leaveTypeFName,
    this.leaveTypeCguid,
    this.totalMinute,
    this.leaveGroup,
    this.departmentId,
    this.departmentName,
    this.leaveDuration,
  });

  Attendence.fromJson(Map<String, dynamic> json) {
    attendenceID = json['AttendenceID'] ?? 0;
    attendenceDate = json['AttendenceDate'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    empId = json['EmpId'] ?? 0;
    inTime = json['InTime'] ?? "";
    outTime = json['OutTime'] ?? "";
    isOnLeave = json['IsOnLeave'] ?? "";
    lateBy = json['LateBy'] ?? "";
    earlyBy = json['EarlyBy'] ?? "";
    leaveType = json['LeaveType'] ?? "";
    holiday = json['Holiday'] ?? "";
    leaveId = json['LeaveId'] ?? "";
    shiftId = json['ShiftId'] ?? "";
    present = json['Present'] ?? false;
    absent = json['Absent'] ?? false;
    cguid = json['Cguid'] ?? "";
    longitude = json['Longitude'] ?? "";
    latitude = json['Latitude'] ?? "";
    location = json['Location'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    firstName = json['FirstName'] ?? "";
    lastName = json['LastName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
    device = json['Device'] ?? "";
    leaveCguid = json['LeaveCguid'] ?? "";
    shiftmstCguid = json['ShiftmstCguid'] ?? "";
    todayAbsent = json['TodayAbsent'] ?? "";
    weekOff = json['WeekOff'] ?? "";
    time = json['Time'] ?? "";
    status = json['Status'] ?? "";
    leaveTypeFName = json['LeaveTypeFName'] ?? "";
    leaveTypeCguid = json['LeaveTypeCguid'] ?? "";
    totalMinute = json['TotalMinute'] ?? "";
    leaveGroup = json['LeaveGroup'] ?? "";
    departmentId = json['DepartmentId'] ?? 0;
    departmentName = json['DepartmentName'] ?? "";
    leaveDuration = json['LeaveDuration'] ?? "";
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
    data['WeekOff'] = weekOff;
    data['Time'] = time;
    data['Status'] = status;
    data['LeaveTypeFName'] = leaveTypeFName;
    data['LeaveTypeCguid'] = leaveTypeCguid;
    data['TotalMinute'] = totalMinute;
    data['LeaveGroup'] = leaveGroup;
    data['DepartmentId'] = departmentId;
    data['DepartmentName'] = departmentName;
    data['LeaveDuration'] = leaveDuration;
    return data;
  }
}

class AttendenceLog {
  int? logId;
  int? empId;
  String? attendenceDate;
  String? time;
  String? status;
  dynamic inDeviceId;
  dynamic outDeviceId;
  dynamic overTime;
  dynamic missedOutPunch;
  dynamic missedInPunch;
  dynamic remarks;
  String? cguid;
  String? longitude;
  String? latitude;
  String? location;
  String? flag;
  String? iPAddress;
  dynamic serverName;
  String? entryTime;
  String? custId;
  String? device;
  String? fileURL;

  AttendenceLog({
    this.logId,
    this.empId,
    this.attendenceDate,
    this.time,
    this.status,
    this.inDeviceId,
    this.outDeviceId,
    this.overTime,
    this.missedOutPunch,
    this.missedInPunch,
    this.remarks,
    this.cguid,
    this.longitude,
    this.latitude,
    this.location,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.device,
    this.fileURL,
  });

  AttendenceLog.fromJson(Map<String, dynamic> json) {
    logId = json['LogId'] ?? 0;
    empId = json['EmpId'] ?? 0;
    attendenceDate = json['AttendenceDate'] ?? "";
    time = json['Time'] ?? "";
    status = json['Status'] ?? "";
    inDeviceId = json['InDeviceId'] ?? "";
    outDeviceId = json['OutDeviceId'] ?? "";
    overTime = json['OverTime'] ?? "";
    missedOutPunch = json['MissedOutPunch'] ?? "";
    missedInPunch = json['MissedInPunch'] ?? "";
    remarks = json['Remarks'] ?? "";
    cguid = json['Cguid'] ?? "";
    longitude = json['Longitude'] ?? "";
    latitude = json['Latitude'] ?? "";
    location = json['Location'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
    device = json['Device'] ?? "";
    fileURL = json['FileURL'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['LogId'] = logId;
    data['EmpId'] = empId;
    data['AttendenceDate'] = attendenceDate;
    data['Time'] = time;
    data['Status'] = status;
    data['InDeviceId'] = inDeviceId;
    data['OutDeviceId'] = outDeviceId;
    data['OverTime'] = overTime;
    data['MissedOutPunch'] = missedOutPunch;
    data['MissedInPunch'] = missedInPunch;
    data['Remarks'] = remarks;
    data['Cguid'] = cguid;
    data['Longitude'] = longitude;
    data['Latitude'] = latitude;
    data['Location'] = location;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['Device'] = device;
    data['FileURL'] = fileURL;
    return data;
  }
}
