// To parse this JSON data, do
//
//     final createRecuritmentModal = createRecuritmentModalFromJson(jsonString);

import 'dart:convert';

CreateRecuritmentModal createRecuritmentModalFromJson(String str) =>
    CreateRecuritmentModal.fromJson(json.decode(str));

String createRecuritmentModalToJson(CreateRecuritmentModal data) =>
    json.encode(data.toJson());

class CreateRecuritmentModal {
  String flag;
  bool success;
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
  Recruitment recruitment;
  dynamic assetMst;
  dynamic salaryAdditionDedection;
  dynamic paySlip;
  dynamic pAttendence;

  CreateRecuritmentModal({
    required this.flag,
    required this.success,
    required this.attendence,
    required this.attendenceLogs,
    required this.attendenceLog,
    required this.holiday,
    required this.leavesTypes,
    required this.salaryStructure,
    required this.empLeave,
    required this.empShiftGroup,
    required this.event,
    required this.shiftMst,
    required this.recruitment,
    required this.assetMst,
    required this.salaryAdditionDedection,
    required this.paySlip,
    required this.pAttendence,
  });

  factory CreateRecuritmentModal.fromJson(Map<String, dynamic> json) =>
      CreateRecuritmentModal(
        flag: json["Flag"] ?? "",
        success: json["Success"] ?? false,
        attendence: json["Attendence"] ?? "",
        attendenceLogs: json["AttendenceLogs"] ?? "",
        attendenceLog: json["AttendenceLog"] ?? "",
        holiday: json["Holiday"] ?? "",
        leavesTypes: json["LeavesTypes"] ?? "",
        salaryStructure: json["SalaryStructure"] ?? "",
        empLeave: json["EmpLeave"] ?? "",
        empShiftGroup: json["EmpShiftGroup"] ?? "",
        event: json["Event"] ?? "",
        shiftMst: json["ShiftMst"] ?? "",
        recruitment: Recruitment.fromJson(json["Recruitment"] ?? {}),
        assetMst: json["AssetMst"] ?? "",
        salaryAdditionDedection: json["SalaryAdditionDedection"] ?? "",
        paySlip: json["PaySlip"] ?? "",
        pAttendence: json["PAttendence"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "Flag": flag,
    "Success": success,
    "Attendence": attendence,
    "AttendenceLogs": attendenceLogs,
    "AttendenceLog": attendenceLog,
    "Holiday": holiday,
    "LeavesTypes": leavesTypes,
    "SalaryStructure": salaryStructure,
    "EmpLeave": empLeave,
    "EmpShiftGroup": empShiftGroup,
    "Event": event,
    "ShiftMst": shiftMst,
    "Recruitment": recruitment.toJson(),
    "AssetMst": assetMst,
    "SalaryAdditionDedection": salaryAdditionDedection,
    "PaySlip": paySlip,
    "PAttendence": pAttendence,
  };
}

class Recruitment {
  int recruitmentId;
  int companyId;
  String name;
  DateTime recruitmentDate;
  String venue;
  int departmentId;
  int positionId;
  String conductedBy;
  String referenceBy;
  String mobileNo;
  String email;
  String experience;
  String lastSalary;
  String expectedSalary;
  String remark;
  String cguid;
  dynamic flag;
  dynamic ipAddress;
  dynamic serverName;
  dynamic entryTime;
  String custId;
  dynamic firstName;
  dynamic lastName;
  dynamic positionName;
  dynamic departmentName;

  Recruitment({
    required this.recruitmentId,
    required this.companyId,
    required this.name,
    required this.recruitmentDate,
    required this.venue,
    required this.departmentId,
    required this.positionId,
    required this.conductedBy,
    required this.referenceBy,
    required this.mobileNo,
    required this.email,
    required this.experience,
    required this.lastSalary,
    required this.expectedSalary,
    required this.remark,
    required this.cguid,
    required this.flag,
    required this.ipAddress,
    required this.serverName,
    required this.entryTime,
    required this.custId,
    required this.firstName,
    required this.lastName,
    required this.positionName,
    required this.departmentName,
  });

  factory Recruitment.fromJson(Map<String, dynamic> json) => Recruitment(
    recruitmentId: json["RecruitmentID"] ?? 0,
    companyId: json["CompanyId"] ?? 0,
    name: json["Name"] ?? "",
    recruitmentDate: DateTime.parse(json["RecruitmentDate"]??DateTime.now()),
    venue: json["Venue"] ?? "",
    departmentId: json["DepartmentId"] ?? 0,
    positionId: json["PositionId"] ?? 0,
    conductedBy: json["ConductedBy"] ?? "",
    referenceBy: json["ReferenceBy"] ?? "",
    mobileNo: json["MobileNo"] ?? "",
    email: json["Email"] ?? "",
    experience: json["Experience"] ?? "",
    lastSalary: json["LastSalary"] ?? "",
    expectedSalary: json["ExpectedSalary"] ?? "",
    remark: json["Remark"] ?? "",
    cguid: json["Cguid"] ?? "",
    flag: json["Flag"] ?? "",
    ipAddress: json["IPAddress"] ?? "",
    serverName: json["ServerName"] ?? "",
    entryTime: json["EntryTime"] ?? "",
    custId: json["CustId"] ?? "",
    firstName: json["FirstName"] ?? "",
    lastName: json["LastName"] ?? "",
    positionName: json["PositionName"] ?? "",
    departmentName: json["DepartmentName"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "RecruitmentID": recruitmentId,
    "CompanyId": companyId,
    "Name": name,
    "RecruitmentDate": recruitmentDate.toIso8601String(),
    "Venue": venue,
    "DepartmentId": departmentId,
    "PositionId": positionId,
    "ConductedBy": conductedBy,
    "ReferenceBy": referenceBy,
    "MobileNo": mobileNo,
    "Email": email,
    "Experience": experience,
    "LastSalary": lastSalary,
    "ExpectedSalary": expectedSalary,
    "Remark": remark,
    "Cguid": cguid,
    "Flag": flag,
    "IPAddress": ipAddress,
    "ServerName": serverName,
    "EntryTime": entryTime,
    "CustId": custId,
    "FirstName": firstName,
    "LastName": lastName,
    "PositionName": positionName,
    "DepartmentName": departmentName,
  };
}
