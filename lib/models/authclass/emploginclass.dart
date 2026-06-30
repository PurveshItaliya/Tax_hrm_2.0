// To parse this JSON data, do
//
//     final empUserLogin = empUserLoginFromJson(jsonString);
// ignore_for_file: prefer_collection_literals

import 'dart:convert';

EmpUserLogin empUserLoginFromJson(String str) =>
    EmpUserLogin.fromJson(json.decode(str));

String empUserLoginToJson(EmpUserLogin data) => json.encode(data.toJson());

class EmpUserLogin {
  int? id;
  int? companyId;
  dynamic companyName;
  String? firstName;
  String? lastName;
  dynamic img;
  String? mobile1;
  dynamic mobile2;
  dynamic add1;
  dynamic add2;
  dynamic add3;
  dynamic pincodeId;
  dynamic cityId;
  dynamic stateId;
  dynamic dOB;
  dynamic dOJ;
  dynamic annivarsaryDate;
  dynamic registerDate;
  String? email;
  dynamic gender;
  dynamic pAN;
  dynamic maritalStatus;
  int? departmentId;
  int? positionId;
  String? role;
  dynamic iFSC;
  dynamic bankName;
  dynamic branchName;
  dynamic accNo;
  dynamic accType;
  dynamic salaryType;
  dynamic salaryAmount;
  bool? isActive;
  dynamic isLogin;
  dynamic highestDegree;
  dynamic degreeName;
  dynamic universityName;
  dynamic passingYear;
  dynamic uANNo;
  dynamic eSICNo;
  String? shiftCguid;
  String? custId;
  String? cguid;
  String? userName;
  String? password;
  String? iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic flag;
  int? totalhours;
  dynamic areaName;
  dynamic cityName;
  dynamic stateName;
  dynamic positionName;
  dynamic departmentName;
  bool? success;
  String? token;
  bool? cRM;
  bool? officeman;
  bool? hRM;
  bool? isAdmin;
  String? workType;
  String? officeLocation;
  dynamic fullName;
  bool? isRecords;

  EmpUserLogin({
    this.id,
    this.companyId,
    this.companyName,
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
    this.annivarsaryDate,
    this.registerDate,
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
    this.isLogin,
    this.highestDegree,
    this.degreeName,
    this.universityName,
    this.passingYear,
    this.uANNo,
    this.eSICNo,
    this.shiftCguid,
    this.custId,
    this.cguid,
    this.userName,
    this.password,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.flag,
    this.totalhours,
    this.areaName,
    this.cityName,
    this.stateName,
    this.positionName,
    this.departmentName,
    this.success,
    this.token,
    this.cRM,
    this.officeman,
    this.hRM,
    this.isAdmin,
    this.workType,
    this.officeLocation,
    this.fullName,
    this.isRecords,
  });

  EmpUserLogin.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    companyName = json['CompanyName'] ?? "";
    firstName = json['FirstName'] ?? "";
    lastName = json['LastName'] ?? "";
    img = json['Img'] ?? "";
    mobile1 = json['Mobile1'] ?? "";
    mobile2 = json['Mobile2'] ?? "";
    add1 = json['Add1'] ?? "";
    add2 = json['Add2'] ?? "";
    add3 = json['Add3'] ?? "";
    pincodeId = json['PincodeId'] ?? "";
    cityId = json['CityId'] ?? "";
    stateId = json['StateId'] ?? "";
    dOB = json['DOB'] ?? "";
    dOJ = json['DOJ'] ?? "";
    annivarsaryDate = json['AnnivarsaryDate'] ?? "";
    registerDate = json['RegisterDate'] ?? "";
    email = json['Email'] ?? "";
    gender = json['Gender'] ?? "";
    pAN = json['PAN'] ?? "";
    maritalStatus = json['MaritalStatus'] ?? "";
    departmentId = json['DepartmentId'] ?? 0;
    positionId = json['PositionId'] ?? 0;
    role = json['Role'] ?? "";
    iFSC = json['IFSC'] ?? "";
    bankName = json['BankName'] ?? "";
    branchName = json['BranchName'] ?? "";
    accNo = json['AccNo'] ?? "";
    accType = json['AccType'] ?? "";
    salaryType = json['SalaryType'] ?? "";
    salaryAmount = json['SalaryAmount'] ?? "";
    isActive = json['IsActive'] ?? true;
    isLogin = json['IsLogin'] ?? "";
    highestDegree = json['HighestDegree'] ?? "";
    degreeName = json['DegreeName'] ?? "";
    universityName = json['UniversityName'] ?? "";
    passingYear = json['PassingYear'] ?? "";
    uANNo = json['UANNo'] ?? "";
    eSICNo = json['ESICNo'] ?? "";
    shiftCguid = json['ShiftCguid'] ?? "";
    custId = json['CustId'] ?? "";
    cguid = json['Cguid'] ?? "";
    userName = json['UserName'] ?? "";
    password = json['Password'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    flag = json['Flag'] ?? "";
    totalhours = json['Totalhours'] ?? 0;
    areaName = json['AreaName'] ?? "";
    cityName = json['CityName'] ?? "";
    stateName = json['StateName'] ?? "";
    positionName = json['PositionName'] ?? "";
    departmentName = json['DepartmentName'] ?? "";
    success = json['success'] ?? true;
    token = json['token'] ?? "";
    cRM = json['CRM'] ?? true;
    officeman = json['Officeman'] ?? true;
    hRM = json['HRM'] ?? true;
    isAdmin = json['isAdmin'] ?? true;
    workType = json['WorkType'] ?? "";
    officeLocation = json['OfficeLocation'] ?? "";
    fullName = json['FullName'] ?? "";
    isRecords = json['IsRecords'] ?? true;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['CompanyId'] = companyId;
    data['CompanyName'] = companyName;
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
    data['AnnivarsaryDate'] = annivarsaryDate;
    data['RegisterDate'] = registerDate;
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
    data['IsLogin'] = isLogin;
    data['HighestDegree'] = highestDegree;
    data['DegreeName'] = degreeName;
    data['UniversityName'] = universityName;
    data['PassingYear'] = passingYear;
    data['UANNo'] = uANNo;
    data['ESICNo'] = eSICNo;
    data['ShiftCguid'] = shiftCguid;
    data['CustId'] = custId;
    data['Cguid'] = cguid;
    data['UserName'] = userName;
    data['Password'] = password;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['Flag'] = flag;
    data['Totalhours'] = totalhours;
    data['AreaName'] = areaName;
    data['CityName'] = cityName;
    data['StateName'] = stateName;
    data['PositionName'] = positionName;
    data['DepartmentName'] = departmentName;
    data['success'] = success;
    data['token'] = token;
    data['CRM'] = cRM;
    data['Officeman'] = officeman;
    data['HRM'] = hRM;
    data['isAdmin'] = isAdmin;
    data['WorkType'] = workType;
    data['OfficeLocation'] = officeLocation;
    data['FullName'] = fullName;
    data['IsRecords'] = isRecords;
    return data;
  }
}
