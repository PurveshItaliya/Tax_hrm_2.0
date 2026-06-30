// To parse this JSON data, do
//
//     final cretaeDepartMent = cretaeDepartMentFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

CretaeDepartMent cretaeDepartMentFromJson(String str) =>
    CretaeDepartMent.fromJson(json.decode(str));

String cretaeDepartMentToJson(CretaeDepartMent data) =>
    json.encode(data.toJson());

class CretaeDepartMent {
  bool? success;
  Data? data;

  CretaeDepartMent({this.success, this.data});

  CretaeDepartMent.fromJson(Map<String, dynamic> json) {
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
  String? departmentName;
  bool? isActive;
  String? custId;
  int? companyId;

  Data({
    this.id,
    this.departmentName,
    this.isActive,
    this.custId,
    this.companyId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    departmentName = json['DepartmentName'] ?? "";
    isActive = json['IsActive'] ?? true;
    custId = json['CustId'] ?? "";
    companyId = json['CompanyId'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['DepartmentName'] = departmentName;
    data['IsActive'] = isActive;
    data['CustId'] = custId;
    data['CompanyId'] = companyId;
    return data;
  }
}
