// To parse this JSON data, do
//
//     final userLogin = userLoginFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

UserLogin userLoginFromJson(String str) => UserLogin.fromJson(json.decode(str));

String userLoginToJson(UserLogin data) => json.encode(data.toJson());

class UserLogin {
  int? id;
  int? regTypeId;
  dynamic packageId;
  bool? cRM;
  bool? officeman;
  bool? hRM;
  String? custId;
  dynamic mainCustId;
  String? firstName;
  String? lastName;
  String? mobile;
  String? email;
  String? username;
  String? password;
  String? role;
  bool? isActive;
  bool? isDefault;
  bool? success;
  String? token;
  String? cguid;
  String? ipAddress;
  String? licenseDate;
  dynamic device;
  int? permitUsers;
  double? dBversion;
  bool? isWhatsNew;
  double? shiftCguid;
  int? companyId;
  dynamic name;
  dynamic diffDate;
  dynamic cityName;
  String? registerdate;

  UserLogin({
    this.id,
    this.regTypeId,
    this.packageId,
    this.cRM,
    this.officeman,
    this.hRM,
    this.custId,
    this.mainCustId,
    this.firstName,
    this.lastName,
    this.mobile,
    this.email,
    this.username,
    this.password,
    this.role,
    this.isActive,
    this.isDefault,
    this.success,
    this.token,
    this.cguid,
    this.ipAddress,
    this.licenseDate,
    this.device,
    this.permitUsers,
    this.dBversion,
    this.isWhatsNew,
    this.shiftCguid,
    this.companyId,
    this.name,
    this.diffDate,
    this.cityName,
    this.registerdate,
  });

  UserLogin.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    regTypeId = json['RegTypeId'] ?? 0;
    packageId = json['PackageId'] ?? "";
    cRM = json['CRM'] ?? true;
    officeman = json['Officeman'] ?? true;
    hRM = json['HRM'] ?? true;
    custId = json['CustId'] ?? "";
    mainCustId = json['MainCustId'] ?? "";
    firstName = json['FirstName'] ?? "";
    lastName = json['LastName'] ?? "";
    mobile = json['Mobile'] ?? "";
    email = json['Email'] ?? "";
    username = json['Username'] ?? "";
    password = json['Password'] ?? "";
    role = json['Role'] ?? "";
    isActive = json['IsActive'] ?? true;
    isDefault = json['IsDefault'] ?? true;
    success = json['success'] ?? true;
    token = json['token'] ?? "";
    cguid = json['Cguid'] ?? "";
    ipAddress = json['IPAddress'] ?? "";
    licenseDate = json['LicenseDate'] ?? "";
    device = json['Device'] ?? "";
    permitUsers = json['PermitUsers'] ?? 0;
    dBversion = json['DBversion'] ?? 0.0;
    isWhatsNew = json['IsWhatsNew'] ?? true;
    shiftCguid = json['ShiftCguid'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    name = json['Name'] ?? "";
    diffDate = json['DiffDate'] ?? "";
    cityName = json['CityName'] ?? "";
    registerdate = json['Registerdate'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['RegTypeId'] = regTypeId;
    data['PackageId'] = packageId;
    data['CRM'] = cRM;
    data['Officeman'] = officeman;
    data['HRM'] = hRM;
    data['CustId'] = custId;
    data['MainCustId'] = mainCustId;
    data['FirstName'] = firstName;
    data['LastName'] = lastName;
    data['Mobile'] = mobile;
    data['Email'] = email;
    data['Username'] = username;
    data['Password'] = password;
    data['Role'] = role;
    data['IsActive'] = isActive;
    data['IsDefault'] = isDefault;
    data['success'] = success;
    data['token'] = token;
    data['Cguid'] = cguid;
    data['IPAddress'] = ipAddress;
    data['LicenseDate'] = licenseDate;
    data['Device'] = device;
    data['PermitUsers'] = permitUsers;
    data['DBversion'] = dBversion;
    data['IsWhatsNew'] = isWhatsNew;
    data['ShiftCguid'] = shiftCguid;
    data['CompanyId'] = companyId;
    data['Name'] = name;
    data['DiffDate'] = diffDate;
    data['CityName'] = cityName;
    data['Registerdate'] = registerdate;

    return data;
  }
}
