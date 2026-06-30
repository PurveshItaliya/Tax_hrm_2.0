// To parse this JSON data, do
//
//     final employeByid = employeByidFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

EmployeByid employeByidFromJson(String str) => EmployeByid.fromJson(json.decode(str));

String employeByidToJson(EmployeByid data) => json.encode(data.toJson());
class EmployeByid {
  int? id;
  String? companyId;
  String? firstName;
  String? lastName;
  dynamic img;
  String? mobile1;
  String? mobile2;
  String? add1;
  String? add2;
  String? add3;
  String? pincodeId;
  String? cityId;
  String? stateId;
  String? dOB;
  String? dOJ;
  String? email;
  String? gender;
  String? pAN;
  String? maritalStatus;
  String? departmentId;
  String? positionId;
  String? role;
  String? iFSC;
  String? bankName;
  String? branchName;
  String? accNo;
  String? accType;
  String? salaryType;
  String? salaryAmount;
  bool? isActive;
  String? custId;
  String? cguid;
  String? userName;
  String? password;
  String? iPAddress;
  dynamic serverName;
  String? entryTime;
  String? flag;
  dynamic areaName;
  dynamic cityName;
  dynamic stateName;
  dynamic positionName;
  dynamic departmentName;
  bool? success;
  dynamic token;

  EmployeByid(
      {this.id,
      this.companyId,
      this.firstName,
      this.lastName,
      this.img,
      this.mobile1,
      this.mobile2,
      this.add1,
      this.add2,
      this.add3,
      this.pincodeId,
      this.cityId,
      this.stateId,
      this.dOB,
      this.dOJ,
      this.email,
      this.gender,
      this.pAN,
      this.maritalStatus,
      this.departmentId,
      this.positionId,
      this.role,
      this.iFSC,
      this.bankName,
      this.branchName,
      this.accNo,
      this.accType,
      this.salaryType,
      this.salaryAmount,
      this.isActive,
      this.custId,
      this.cguid,
      this.userName,
      this.password,
      this.iPAddress,
      this.serverName,
      this.entryTime,
      this.flag,
      this.areaName,
      this.cityName,
      this.stateName,
      this.positionName,
      this.departmentName,
      this.success,
      this.token});

  EmployeByid.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    companyId = json['CompanyId'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    img = json['Img'];
    mobile1 = json['Mobile1'];
    mobile2 = json['Mobile2'];
    add1 = json['Add1'];
    add2 = json['Add2'];
    add3 = json['Add3'];
    pincodeId = json['PincodeId'];
    cityId = json['CityId'];
    stateId = json['StateId'];
    dOB = json['DOB'];
    dOJ = json['DOJ'];
    email = json['Email'];
    gender = json['Gender'];
    pAN = json['PAN'];
    maritalStatus = json['MaritalStatus'];
    departmentId = json['DepartmentId'];
    positionId = json['PositionId'];
    role = json['Role'];
    iFSC = json['IFSC'];
    bankName = json['BankName'];
    branchName = json['BranchName'];
    accNo = json['AccNo'];
    accType = json['AccType'];
    salaryType = json['SalaryType'];
    salaryAmount = json['SalaryAmount'];
    isActive = json['IsActive'];
    custId = json['CustId'];
    cguid = json['Cguid'];
    userName = json['UserName'];
    password = json['Password'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    flag = json['Flag'];
    areaName = json['AreaName'];
    cityName = json['CityName'];
    stateName = json['StateName'];
    positionName = json['PositionName'];
    departmentName = json['DepartmentName'];
    success = json['success'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['Id'] = id;
    data['CompanyId'] = companyId;
    data['FirstName'] = firstName;
    data['LastName'] = lastName;
    data['Img'] = img;
    data['Mobile1'] = mobile1;
    data['Mobile2'] = mobile2;
    data['Add1'] = add1;
    data['Add2'] = add2;
    data['Add3'] = add3;
    data['PincodeId'] = pincodeId;
    data['CityId'] = cityId;
    data['StateId'] = stateId;
    data['DOB'] = dOB;
    data['DOJ'] = dOJ;
    data['Email'] = email;
    data['Gender'] = gender;
    data['PAN'] = pAN;
    data['MaritalStatus'] = maritalStatus;
    data['DepartmentId'] = departmentId;
    data['PositionId'] = positionId;
    data['Role'] = role;
    data['IFSC'] = iFSC;
    data['BankName'] = bankName;
    data['BranchName'] = branchName;
    data['AccNo'] = accNo;
    data['AccType'] = accType;
    data['SalaryType'] = salaryType;
    data['SalaryAmount'] = salaryAmount;
    data['IsActive'] = isActive;
    data['CustId'] = custId;
    data['Cguid'] = cguid;
    data['UserName'] = userName;
    data['Password'] = password;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['Flag'] = flag;
    data['AreaName'] = areaName;
    data['CityName'] = cityName;
    data['StateName'] = stateName;
    data['PositionName'] = positionName;
    data['DepartmentName'] = departmentName;
    data['success'] = success;
    data['token'] = token;
    return data;
  }
}
