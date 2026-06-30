// To parse this JSON data, do
//
//     final updateRecuritmentModal = updateRecuritmentModalFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

UpdateRecuritmentModal updateRecuritmentModalFromJson(String str) => UpdateRecuritmentModal.fromJson(json.decode(str));

String updateRecuritmentModalToJson(UpdateRecuritmentModal data) => json.encode(data.toJson());

class UpdateRecuritmentModal {
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
  dynamic firstName;
  dynamic lastName;
  dynamic positionName;
  dynamic departmentName;

  UpdateRecuritmentModal(
      {this.recruitmentID,
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
      this.departmentName});

  UpdateRecuritmentModal.fromJson(Map<String, dynamic> json) {
    recruitmentID = json['RecruitmentID'];
    companyId = json['CompanyId'];
    name = json['Name'];
    recruitmentDate = json['RecruitmentDate'];
    venue = json['Venue'];
    departmentId = json['DepartmentId'];
    positionId = json['PositionId'];
    conductedBy = json['ConductedBy'];
    referenceBy = json['ReferenceBy'];
    mobileNo = json['MobileNo'];
    email = json['Email'];
    experience = json['Experience'];
    lastSalary = json['LastSalary'];
    expectedSalary = json['ExpectedSalary'];
    remark = json['Remark'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    positionName = json['PositionName'];
    departmentName = json['DepartmentName'];
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