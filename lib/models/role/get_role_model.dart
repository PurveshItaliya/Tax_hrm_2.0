// To parse this JSON data, do
//
//     final getrolemodel = getrolemodelFromJson(jsonString);

import 'dart:convert';

List<Getrolemodel> getrolemodelFromJson(String str) => List<Getrolemodel>.from(json.decode(str).map((x) => Getrolemodel.fromJson(x)));

String getrolemodelToJson(List<Getrolemodel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Getrolemodel {
  int roleId;
  String role;
  bool isActive;
  String custId;

  Getrolemodel({
    required this.roleId,
    required this.role,
    required this.isActive,
    required this.custId,
  });

  factory Getrolemodel.fromJson(Map<String, dynamic> json) => Getrolemodel(
    roleId: json["RoleId"] ?? 0,
    role: json["Role"] ?? "",
    isActive: json["IsActive"] ?? false,
    custId: json["CustId"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "RoleId": roleId,
    "Role": role,
    "IsActive": isActive,
    "CustId": custId,
  };
}
