// To parse this JSON data, do
//
//     final ifscListModel = ifscListModelFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<IfscListModel> ifscListModelFromJson(String str) => List<IfscListModel>.from(json.decode(str).map((x) => IfscListModel.fromJson(x)));

String ifscListModelToJson(List<IfscListModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class IfscListModel {
  int? iFSCID;
  String? bankName;
  String? branchName;
  String? iFSC;
  String? guid;
  String? syncDateTime;
  String? flag;
  String? custId;
  String? entrydate;
  int? companyId;

  IfscListModel(
      {this.iFSCID,
      this.bankName,
      this.branchName,
      this.iFSC,
      this.guid,
      this.syncDateTime,
      this.flag,
      this.custId,
      this.entrydate,
      this.companyId});

  IfscListModel.fromJson(Map<String, dynamic> json) {
    iFSCID = json['IFSCID'] ?? 0;
    bankName = json['BankName'] ?? "";
    branchName = json['BranchName'] ?? "";
    iFSC = json['IFSC'] ?? "";
    guid = json['Guid'] ?? "";
    syncDateTime = json['SyncDateTime'] ?? "";
    flag = json['Flag'] ?? "";
    custId = json['CustId'] ?? "";
    entrydate = json['Entrydate'] ?? "";
    companyId = json['CompanyId'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['IFSCID'] = iFSCID;
    data['BankName'] = bankName;
    data['BranchName'] = branchName;
    data['IFSC'] = iFSC;
    data['Guid'] = guid;
    data['SyncDateTime'] = syncDateTime;
    data['Flag'] = flag;
    data['CustId'] = custId;
    data['Entrydate'] = entrydate;
    data['CompanyId'] = companyId;
    return data;
  }
}
