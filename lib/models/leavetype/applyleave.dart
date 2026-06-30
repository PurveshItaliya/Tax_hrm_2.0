// To parse this JSON data, do
//
//     final leaveApply = leaveApplyFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

LeaveApply leaveApplyFromJson(String str) => LeaveApply.fromJson(json.decode(str));

String leaveApplyToJson(LeaveApply data) => json.encode(data.toJson());
class LeaveApply {
  bool? isUser;
  String? flag;
  bool? success;
  dynamic attendence;
  dynamic attendenceLogs;
  dynamic attendenceLog;
  dynamic holiday;
  dynamic leavesTypes;
  dynamic salaryStructure;
  EmpLeave? empLeave;
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

  LeaveApply(
      {this.isUser,
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
      this.pAttendence});

  LeaveApply.fromJson(Map<String, dynamic> json) {
    isUser = json['IsUser'];
    flag = json['Flag'];
    success = json['Success'];
    attendence = json['Attendence'];
    attendenceLogs = json['AttendenceLogs'];
    attendenceLog = json['AttendenceLog'];
    holiday = json['Holiday'];
    leavesTypes = json['LeavesTypes'];
    salaryStructure = json['SalaryStructure'];
    empLeave = json['EmpLeave'] != null
        ? EmpLeave.fromJson(json['EmpLeave'])
        : null;
    empShiftGroup = json['EmpShiftGroup'];
    event = json['Event'];
    shiftMst = json['ShiftMst'];
    recruitment = json['Recruitment'];
    assetMst = json['AssetMst'];
    salaryAdditionDedection = json['SalaryAdditionDedection'];
    addDedMst = json['AddDedMst'];
    addDedDetail = json['AddDedDetail'];
    paySlip = json['PaySlip'];
    pAttendence = json['PAttendence'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['IsUser'] = isUser;
    data['Flag'] = flag;
    data['Success'] = success;
    data['Attendence'] = attendence;
    data['AttendenceLogs'] = attendenceLogs;
    data['AttendenceLog'] = attendenceLog;
    data['Holiday'] = holiday;
    data['LeavesTypes'] = leavesTypes;
    data['SalaryStructure'] = salaryStructure;
    if (empLeave != null) {
      data['EmpLeave'] = empLeave!.toJson();
    }
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

class EmpLeave {
  int? empLeaveId;
  int? companyId;
  int? empId;
  int? leaveTypeId;
  String? leaveTypeCguid;
  String? fromDate;
  String? toDate;
  String? remarks;
  String? leaveYear;
  dynamic leaveTypeFName;
  String? leaveDuration;
  String? cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic custId;
  String? approveStatus;
  dynamic dayType;
  double? gainLeave;
  double? usedLeave;
  double? eligibleLeave;
  dynamic firstName;
  dynamic lastName;
  dynamic leaveDays;

  EmpLeave(
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
      this.lastName,
      this.leaveDays});

  EmpLeave.fromJson(Map<String, dynamic> json) {
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
    leaveDays = json['LeaveDays'];
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
    data['LeaveDays'] = leaveDays;
    return data;
  }
}
