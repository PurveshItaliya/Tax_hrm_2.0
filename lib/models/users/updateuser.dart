// To parse this JSON data, do
//
//     final updateAdmin = updateAdminFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

UpdateAdmin updateAdminFromJson(String str) =>
    UpdateAdmin.fromJson(json.decode(str));

String updateAdminToJson(UpdateAdmin data) => json.encode(data.toJson());

class UpdateAdmin {
  String? flag;
  bool? sucess;
  Tokens? tokens;
  dynamic cguid;
  dynamic companylist;
  dynamic departmentlist;
  dynamic positionlist;
  dynamic emplist;
  dynamic categorylist;
  dynamic subcategorylist;

  UpdateAdmin({
    this.flag,
    this.sucess,
    this.tokens,
    this.cguid,
    this.companylist,
    this.departmentlist,
    this.positionlist,
    this.emplist,
    this.categorylist,
    this.subcategorylist,
  });

  UpdateAdmin.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'] ?? "";
    sucess = json['Sucess'] ?? false;
    tokens = json['tokens'] != null ? Tokens.fromJson(json['tokens']) : null;
    cguid = json['Cguid'] ?? "";
    companylist = json['companylist'] ?? "";
    departmentlist = json['departmentlist'] ?? "";
    positionlist = json['positionlist'] ?? "";
    emplist = json['emplist'] ?? "";
    categorylist = json['categorylist'] ?? "";
    subcategorylist = json['subcategorylist'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Flag'] = flag;
    data['Sucess'] = sucess;
    if (tokens != null) {
      data['tokens'] = tokens!.toJson();
    }
    data['Cguid'] = cguid;
    data['companylist'] = companylist;
    data['departmentlist'] = departmentlist;
    data['positionlist'] = positionlist;
    data['emplist'] = emplist;
    data['categorylist'] = categorylist;
    data['subcategorylist'] = subcategorylist;
    return data;
  }
}

class Tokens {
  int? id;
  int? regTypeId;
  int? packageId;
  bool? cRM;
  bool? officeman;
  bool? hRM;
  String? custId;
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
  dynamic token;
  String? cguid;
  String? iPAddress;
  String? licenseDate;
  dynamic permitUsers;
  dynamic name;
  dynamic diffDate;

  Tokens({
    this.id,
    this.regTypeId,
    this.packageId,
    this.cRM,
    this.officeman,
    this.hRM,
    this.custId,
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
    this.iPAddress,
    this.licenseDate,
    this.permitUsers,
    this.name,
    this.diffDate,
  });

  Tokens.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    regTypeId = json['RegTypeId'] ?? 0;
    packageId = json['PackageId'] ?? 0;
    cRM = json['CRM'] ?? false;
    officeman = json['Officeman'] ?? false;
    hRM = json['HRM'] ?? false;
    custId = json['CustId'] ?? "";
    firstName = json['FirstName'] ?? "";
    lastName = json['LastName'] ?? "";
    mobile = json['Mobile'] ?? "";
    email = json['Email'] ?? "";
    username = json['Username'] ?? "";
    password = json['Password'] ?? "";
    role = json['Role'] ?? "";
    isActive = json['IsActive'] ?? false;
    isDefault = json['IsDefault'] ?? false;
    success = json['success'] ?? false;
    token = json['token'] ?? "";
    cguid = json['Cguid'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    licenseDate = json['LicenseDate'] ?? "";
    permitUsers = json['PermitUsers'] ?? "";
    name = json['Name'] ?? "";
    diffDate = json['DiffDate'] ?? "";
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
    data['IPAddress'] = iPAddress;
    data['LicenseDate'] = licenseDate;
    data['PermitUsers'] = permitUsers;
    data['Name'] = name;
    data['DiffDate'] = diffDate;
    return data;
  }
}
