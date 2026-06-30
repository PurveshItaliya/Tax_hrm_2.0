// To parse this JSON data, do
//
//     final getIfscByid = getIfscByidFromJson(jsonString);

// ignore_for_file: prefer_collection_literals, file_names

import 'dart:convert';

GetIfscByid getIfscByidFromJson(String str) => GetIfscByid.fromJson(json.decode(str));

String getIfscByidToJson(GetIfscByid data) => json.encode(data.toJson());
class GetIfscByid {
  int? iFSCID;
  String? bankName;
  String? branchName;
  String? iFSC;
  String? cguid;
  String? syncDateTime;
  String? flag;
  String? custId;
  int? companyId;
  int? userID;
  String? iPAddress;
  String? userName;
  String? serverName;

  GetIfscByid(
      {this.iFSCID,
      this.bankName,
      this.branchName,
      this.iFSC,
      this.cguid,
      this.syncDateTime,
      this.flag,
      this.custId,
      this.companyId,
      this.userID,
      this.iPAddress,
      this.userName,
      this.serverName});

  GetIfscByid.fromJson(Map<String, dynamic> json) {
    iFSCID = json['IFSCID'] ?? 0;
    bankName = json['BankName']  ?? "";
    branchName = json['BranchName'] ??"";
    iFSC = json['IFSC'] ?? "";
    cguid = json['Cguid'] ??"";
    syncDateTime = json['SyncDateTime'] ??"";
    flag = json['Flag'] ?? "";
    custId = json['CustId'] ??"";
    companyId = json['CompanyId'] ?? 0;
    userID = json['UserID'] ?? 0;
    iPAddress = json['IPAddress'] ??"";
    userName = json['UserName'] ??"";
    serverName = json['ServerName'] ??"";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['IFSCID'] = iFSCID;
    data['BankName'] = bankName;
    data['BranchName'] = branchName;
    data['IFSC'] = iFSC;
    data['Cguid'] = cguid;
    data['SyncDateTime'] = syncDateTime;
    data['Flag'] = flag;
    data['CustId'] = custId;
    data['CompanyId'] = companyId;
    data['UserID'] = userID;
    data['IPAddress'] = iPAddress;
    data['UserName'] = userName;
    data['ServerName'] = serverName;
    return data;
  }
}
