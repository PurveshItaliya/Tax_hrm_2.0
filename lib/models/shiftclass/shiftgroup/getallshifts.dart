// To parse this JSON data, do
//
//     final shiftGroup = shiftGroupFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<ShiftGroup> shiftGroupFromJson(String str) =>
    List<ShiftGroup>.from(json.decode(str).map((x) => ShiftGroup.fromJson(x)));

String shiftGroupToJson(List<ShiftGroup> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ShiftGroup {
  int? shiftGroupID;
  String? shiftGroupFname;
  int? companyId;
  String? shiftGroupSname;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;

  ShiftGroup({
    this.shiftGroupID,
    this.shiftGroupFname,
    this.companyId,
    this.shiftGroupSname,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
  });

  ShiftGroup.fromJson(Map<String, dynamic> json) {
    shiftGroupID = json['ShiftGroupID'] ?? 0;
    shiftGroupFname = json['ShiftGroupFname'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    shiftGroupSname = json['ShiftGroupSname'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ShiftGroupID'] = shiftGroupID;
    data['ShiftGroupFname'] = shiftGroupFname;
    data['CompanyId'] = companyId;
    data['ShiftGroupSname'] = shiftGroupSname;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    return data;
  }
}
