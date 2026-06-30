// To parse this JSON data, do
//
//     final positionmodel = positionmodelFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<PositionDataL> positionmodelFromJson(String str) =>
    List<PositionDataL>.from(
      json.decode(str).map((x) => PositionDataL.fromJson(x)),
    );

String positionmodelToJson(List<PositionDataL> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PositionDataL {
  int? id;
  String? positionName;
  int? departmentId;
  bool? isActive;
  String? departmentName;
  String? custId;
  int? companyId;
  String? cguid;
  String? shiftCguid;

  PositionDataL({
    this.id,
    this.positionName,
    this.departmentId,
    this.isActive,
    this.departmentName,
    this.custId,
    this.companyId,
    this.cguid,
    this.shiftCguid,
  });

  PositionDataL.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    positionName = json['PositionName'] ?? "";
    departmentId = json['DepartmentId'] ?? 0;
    isActive = json['IsActive'] ?? false;
    departmentName = json['DepartmentName'] ?? "";
    custId = json['CustId'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    cguid = json['Cguid'] ?? "";
    shiftCguid = json['ShiftCguid'] ?? "";
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
    data['ShiftCguid'] = shiftCguid;
    return data;
  }
}
