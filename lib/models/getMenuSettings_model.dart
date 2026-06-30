// To parse this JSON data, do
//     final getMenuSettingsModel = getMenuSettingsModelFromJson(jsonString);

// ignore_for_file: file_names

import 'dart:convert';

List<GetMenuSettingsModel> getMenuSettingsModelFromJson(String str) =>
    List<GetMenuSettingsModel>.from(
      json.decode(str).map((x) => GetMenuSettingsModel.fromJson(x)),
    );

String getMenuSettingsModelToJson(List<GetMenuSettingsModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetMenuSettingsModel {
  int? iD;
  String? custId;
  int? companyId;
  int? empId;
  String? columnKey;
  String? columnValue;
  String? mode;
  int? userID;
  String? userName;
  String? entryTime;

  GetMenuSettingsModel({
    this.iD,
    this.custId,
    this.companyId,
    this.empId,
    this.columnKey,
    this.columnValue,
    this.mode,
    this.userID,
    this.userName,
    this.entryTime,
  });

  GetMenuSettingsModel.fromJson(Map<String, dynamic> json) {
    iD = json['ID'] ?? 0;
    custId = json['CustId'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    empId = json['EmpId'] ?? 0;
    columnKey = json['ColumnKey'] ?? "";
    columnValue = json['ColumnValue'] ?? "";
    mode = json['Mode'] ?? "";
    userID = json['UserID'] ?? 0;
    userName = json['UserName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ID'] = iD;
    data['CustId'] = custId;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['ColumnKey'] = columnKey;
    data['ColumnValue'] = columnValue;
    data['Mode'] = mode;
    data['UserID'] = userID;
    data['UserName'] = userName;
    data['EntryTime'] = entryTime;
    return data;
  }
}
