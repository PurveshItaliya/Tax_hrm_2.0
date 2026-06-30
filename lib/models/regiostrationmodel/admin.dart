// To parse this JSON data, do
//
//     final createAdmin = createAdminFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

CreateAdmin createAdminFromJson(String str) => CreateAdmin.fromJson(json.decode(str));

String createAdminToJson(CreateAdmin data) => json.encode(data.toJson());
class CreateAdmin {
  String? flag;
  bool? sucess;
  Tokens? tokens;
  dynamic finYear;
  String? cguid;
  List<Companylist>? companylist;
  dynamic departmentlist;
  dynamic positionlist;
  dynamic emplist;
  dynamic categorylist;
  dynamic subcategorylist;

  CreateAdmin(
      {this.flag,
      this.sucess,
      this.tokens,
      this.finYear,
      this.cguid,
      this.companylist,
      this.departmentlist,
      this.positionlist,
      this.emplist,
      this.categorylist,
      this.subcategorylist});

  CreateAdmin.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'];
    sucess = json['Sucess'];
    tokens =
        json['tokens'] != null ?  Tokens.fromJson(json['tokens']) : null;
    finYear = json['FinYear'];
    cguid = json['Cguid'];
    if (json['companylist'] != null) {
      companylist = <Companylist>[];
      json['companylist'].forEach((v) {
        companylist!.add( Companylist.fromJson(v));
      });
    }
    departmentlist = json['departmentlist'];
    positionlist = json['positionlist'];
    emplist = json['emplist'];
    categorylist = json['categorylist'];
    subcategorylist = json['subcategorylist'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Flag'] = flag;
    data['Sucess'] = sucess;
    if (tokens != null) {
      data['tokens'] = tokens!.toJson();
    }
    data['FinYear'] = finYear;
    data['Cguid'] = cguid;
    if (companylist != null) {
      data['companylist'] = companylist!.map((v) => v.toJson()).toList();
    }
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
  String? mainCustId;
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
  dynamic device;
  dynamic permitUsers;
  double? dBversion;
  bool? isWhatsNew;
  double? shiftCguid;
  dynamic name;
  dynamic diffDate;
  dynamic cityName;

  Tokens(
      {this.id,
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
      this.iPAddress,
      this.licenseDate,
      this.device,
      this.permitUsers,
      this.dBversion,
      this.isWhatsNew,
      this.shiftCguid,
      this.name,
      this.diffDate,
      this.cityName});

  Tokens.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    regTypeId = json['RegTypeId'];
    packageId = json['PackageId'];
    cRM = json['CRM'];
    officeman = json['Officeman'];
    hRM = json['HRM'];
    custId = json['CustId'];
    mainCustId = json['MainCustId'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    mobile = json['Mobile'];
    email = json['Email'];
    username = json['Username'];
    password = json['Password'];
    role = json['Role'];
    isActive = json['IsActive'];
    isDefault = json['IsDefault'];
    success = json['success'];
    token = json['token'];
    cguid = json['Cguid'];
    iPAddress = json['IPAddress'];
    licenseDate = json['LicenseDate'];
    device = json['Device'];
    permitUsers = json['PermitUsers'];
    dBversion = json['DBversion'];
    isWhatsNew = json['IsWhatsNew'];
    shiftCguid = json['ShiftCguid'];
    name = json['Name'];
    diffDate = json['DiffDate'];
    cityName = json['CityName'];
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
    data['IPAddress'] = iPAddress;
    data['LicenseDate'] = licenseDate;
    data['Device'] = device;
    data['PermitUsers'] = permitUsers;
    data['DBversion'] = dBversion;
    data['IsWhatsNew'] = isWhatsNew;
    data['ShiftCguid'] = shiftCguid;
    data['Name'] = name;
    data['DiffDate'] = diffDate;
    data['CityName'] = cityName;
    return data;
  }
}

class Companylist {
  dynamic companyId;
  dynamic userId;
  String? companyName;
  String? add1;
  String? add2;
  String? add3;
  int? pincodeId;
  int? cityId;
  int? stateId;
  String? phone1;
  String? mobile1;
  String? mobile2;
  String? email;
  String? pAN;
  String? gST;
  String? guid;
  dynamic entryTime;
  bool? isActive;
  dynamic userName;
  dynamic serverName;
  String? iPAddress;
  dynamic flag;
  String? custId;
  dynamic areaName;
  dynamic cityName;
  dynamic stateName;
  String? cguid;
  dynamic code;

  Companylist(
      {this.companyId,
      this.userId,
      this.companyName,
      this.add1,
      this.add2,
      this.add3,
      this.pincodeId,
      this.cityId,
      this.stateId,
      this.phone1,
      this.mobile1,
      this.mobile2,
      this.email,
      this.pAN,
      this.gST,
      this.guid,
      this.entryTime,
      this.isActive,
      this.userName,
      this.serverName,
      this.iPAddress,
      this.flag,
      this.custId,
      this.areaName,
      this.cityName,
      this.stateName,
      this.cguid,
      this.code});

  Companylist.fromJson(Map<String, dynamic> json) {
    companyId = json['CompanyId'];
    userId = json['UserId'];
    companyName = json['CompanyName'];
    add1 = json['Add1'];
    add2 = json['Add2'];
    add3 = json['Add3'];
    pincodeId = json['PincodeId'];
    cityId = json['CityId'];
    stateId = json['StateId'];
    phone1 = json['Phone1'];
    mobile1 = json['Mobile1'];
    mobile2 = json['Mobile2'];
    email = json['Email'];
    pAN = json['PAN'];
    gST = json['GST'];
    guid = json['Guid'];
    entryTime = json['EntryTime'];
    isActive = json['IsActive'];
    userName = json['UserName'];
    serverName = json['ServerName'];
    iPAddress = json['IPAddress'];
    flag = json['Flag'];
    custId = json['CustId'];
    areaName = json['AreaName'];
    cityName = json['CityName'];
    stateName = json['StateName'];
    cguid = json['Cguid'];
    code = json['Code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['CompanyId'] = companyId;
    data['UserId'] = userId;
    data['CompanyName'] = companyName;
    data['Add1'] = add1;
    data['Add2'] = add2;
    data['Add3'] = add3;
    data['PincodeId'] = pincodeId;
    data['CityId'] = cityId;
    data['StateId'] = stateId;
    data['Phone1'] = phone1;
    data['Mobile1'] = mobile1;
    data['Mobile2'] = mobile2;
    data['Email'] = email;
    data['PAN'] = pAN;
    data['GST'] = gST;
    data['Guid'] = guid;
    data['EntryTime'] = entryTime;
    data['IsActive'] = isActive;
    data['UserName'] = userName;
    data['ServerName'] = serverName;
    data['IPAddress'] = iPAddress;
    data['Flag'] = flag;
    data['CustId'] = custId;
    data['AreaName'] = areaName;
    data['CityName'] = cityName;
    data['StateName'] = stateName;
    data['Cguid'] = cguid;
    data['Code'] = code;
    return data;
  }
}
