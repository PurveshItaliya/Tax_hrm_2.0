// To parse this JSON data, do
//
//     final createNewIfsc = createNewIfscFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

CreateNewIfsc createNewIfscFromJson(String str) => CreateNewIfsc.fromJson(json.decode(str));

String createNewIfscToJson(CreateNewIfsc data) => json.encode(data.toJson());
class CreateNewIfsc {
  String? flag;
  bool? success;
  Ifsccode? ifsccode;

  CreateNewIfsc({this.flag, this.success, this.ifsccode});

  CreateNewIfsc.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'];
    success = json['Success'];
    ifsccode = json['ifsccode'] != null
        ?  Ifsccode.fromJson(json['ifsccode'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['Flag'] = flag;
    data['Success'] = success;
    if (ifsccode != null) {
      data['ifsccode'] = ifsccode!.toJson();
    }
    return data;
  }
}

class Ifsccode {
  int? iFSCID;
  String? bankName;
  String? branchName;
  String? iFSC;
  String? guid;
  dynamic syncDateTime;
  dynamic flag;
  String? custId;
  String? entrydate;

  Ifsccode(
      {this.iFSCID,
      this.bankName,
      this.branchName,
      this.iFSC,
      this.guid,
      this.syncDateTime,
      this.flag,
      this.custId,
      this.entrydate});

  Ifsccode.fromJson(Map<String, dynamic> json) {
    iFSCID = json['IFSCID'] ?? 0;
    bankName = json['BankName'] ?? "";
    branchName = json['BranchName'] ?? "";
    iFSC = json['IFSC'] ?? "";
    guid = json['Guid'] ?? "";
    syncDateTime = json['SyncDateTime'] ?? "";
    flag = json['Flag'] ?? "";
    custId = json['CustId'] ?? "";
    entrydate = json['Entrydate'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['IFSCID'] = iFSCID;
    data['BankName'] = bankName;
    data['BranchName'] = branchName;
    data['IFSC'] = iFSC;
    data['Guid'] = guid;
    data['SyncDateTime'] = syncDateTime;
    data['Flag'] = flag;
    data['CustId'] = custId;
    data['Entrydate'] = entrydate;
    return data;
  }
}
