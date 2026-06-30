// To parse this JSON data, do
//
//     final postrolemodel = postrolemodelFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

NewRoles postrolemodelFromJson(String str) => NewRoles.fromJson(json.decode(str));

String postrolemodelToJson(NewRoles data) => json.encode(data.toJson());
class NewRoles {
  bool? success;
  Data? data;

  NewRoles({this.success, this.data});

  NewRoles.fromJson(Map<String, dynamic> json) {
    success = json['Success'];
    data = json['data'] != null ?  Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['Success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? roleId;
  String? role;
  bool? isActive;
  String? custId;
  int? companyId;

  Data({this.roleId, this.role, this.isActive, this.custId, this.companyId});

  Data.fromJson(Map<String, dynamic> json) {
    roleId = json['RoleId'] ?? 0;
    role = json['Role'] ?? "";
    isActive = json['IsActive'] ?? false;
    custId = json['CustId'] ?? "";
    companyId = json['CompanyId'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['RoleId'] = roleId;
    data['Role'] = role;
    data['IsActive'] = isActive;
    data['CustId'] = custId;
    data['CompanyId'] = companyId;
    return data;
  }
}
