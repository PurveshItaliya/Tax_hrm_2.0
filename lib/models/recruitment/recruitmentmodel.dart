// To parse this JSON data, do
//
//     final recruitmentModal = recruitmentModalFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<RecruitmentModal> recruitmentModalFromJson(String str) =>
    List<RecruitmentModal>.from(
      json.decode(str).map((x) => RecruitmentModal.fromJson(x)),
    );

String recruitmentModalToJson(List<RecruitmentModal> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RecruitmentModal {
  int? recruitmentID;
  int? companyId;
  String? name;
  String? recruitmentDate;
  String? venue;
  int? departmentId;
  dynamic positionId;
  String? conductedBy;
  String? referenceBy;
  String? mobileNo;
  String? email;
  String? experience;
  String? lastSalary;
  String? expectedSalary;
  String? remark;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  String? firstName;
  String? lastName;
  dynamic positionName;
  String? departmentName;

  RecruitmentModal({
    this.recruitmentID,
    this.companyId,
    this.name,
    this.recruitmentDate,
    this.venue,
    this.departmentId,
    this.positionId,
    this.conductedBy,
    this.referenceBy,
    this.mobileNo,
    this.email,
    this.experience,
    this.lastSalary,
    this.expectedSalary,
    this.remark,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.firstName,
    this.lastName,
    this.positionName,
    this.departmentName,
  });

  RecruitmentModal.fromJson(Map<String, dynamic> json) {
    recruitmentID = json['RecruitmentID'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    name = json['Name'] ?? "";
    recruitmentDate = json['RecruitmentDate'] ?? "";
    venue = json['Venue'] ?? "";
    departmentId = json['DepartmentId'] ?? 0;
    positionId = json['PositionId'] ?? "";
    conductedBy = json['ConductedBy'] ?? "";
    referenceBy = json['ReferenceBy'] ?? "";
    mobileNo = json['MobileNo'] ?? "";
    email = json['Email'] ?? "";
    experience = json['Experience'] ?? "";
    lastSalary = json['LastSalary'] ?? "";
    expectedSalary = json['ExpectedSalary'] ?? "";
    remark = json['Remark'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
    firstName = json['FirstName'] ?? "";
    lastName = json['LastName'] ?? "";
    positionName = json['PositionName'] ?? "";
    departmentName = json['DepartmentName'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['RecruitmentID'] = recruitmentID;
    data['CompanyId'] = companyId;
    data['Name'] = name;
    data['RecruitmentDate'] = recruitmentDate;
    data['Venue'] = venue;
    data['DepartmentId'] = departmentId;
    data['PositionId'] = positionId;
    data['ConductedBy'] = conductedBy;
    data['ReferenceBy'] = referenceBy;
    data['MobileNo'] = mobileNo;
    data['Email'] = email;
    data['Experience'] = experience;
    data['LastSalary'] = lastSalary;
    data['ExpectedSalary'] = expectedSalary;
    data['Remark'] = remark;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['FirstName'] = firstName;
    data['LastName'] = lastName;
    data['PositionName'] = positionName;
    data['DepartmentName'] = departmentName;
    return data;
  }
}
