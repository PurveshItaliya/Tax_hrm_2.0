// To parse this JSON data, do
//
//     final positionCreate = positionCreateFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

PositionCreate positionCreateFromJson(String str) =>
    PositionCreate.fromJson(json.decode(str));

String positionCreateToJson(PositionCreate data) => json.encode(data.toJson());

class PositionCreate {
  bool? success;
  Data? data;

  PositionCreate({this.success, this.data});

  PositionCreate.fromJson(Map<String, dynamic> json) {
    success = json['Success'] ?? false;
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? positionName;
  int? departmentId;
  bool? isActive;
  dynamic departmentName;
  String? custId;
  int? companyId;
  dynamic cguid;

  Data({
    this.id,
    this.positionName,
    this.departmentId,
    this.isActive,
    this.departmentName,
    this.custId,
    this.companyId,
    this.cguid,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    positionName = json['PositionName'] ?? "";
    departmentId = json['DepartmentId'] ?? 0;
    isActive = json['IsActive'] ?? false;
    departmentName = json['DepartmentName'] ?? "";
    custId = json['CustId'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    cguid = json['Cguid'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['PositionName'] = positionName;
    data['DepartmentId'] = departmentId;
    data['IsActive'] = isActive;
    data['DepartmentName'] = departmentName;
    data['CustId'] = custId;
    data['CompanyId'] = companyId;
    data['Cguid'] = cguid;
    return data;
  }
}
