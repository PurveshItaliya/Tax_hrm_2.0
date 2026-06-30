// To parse this JSON data, do
//
//     final createNewCompany = createNewCompanyFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

CreateNewCompany createNewCompanyFromJson(String str) => CreateNewCompany.fromJson(json.decode(str));

String createNewCompanyToJson(CreateNewCompany data) => json.encode(data.toJson());
class CreateNewCompany {
  bool? success;
  Data? data;

  CreateNewCompany({this.success, this.data});

  CreateNewCompany.fromJson(Map<String, dynamic> json) {
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
  int? firmId;
  int? userId;
  String? custId;
  String? firmName;
  String? firmType;
  String? pAN;
  String? gST;
  String? add1;
  String? add2;
  String? add3;
  int? pincodeId;
  int? stateId;
  String? phone1;
  String? phone2;
  String? mobile1;
  String? mobile2;
  String? email;
  String? guid;
  dynamic syncDateTime;
  bool? isActive;

  Data(
      {this.firmId,
      this.userId,
      this.custId,
      this.firmName,
      this.firmType,
      this.pAN,
      this.gST,
      this.add1,
      this.add2,
      this.add3,
      this.pincodeId,
      this.stateId,
      this.phone1,
      this.phone2,
      this.mobile1,
      this.mobile2,
      this.email,
      this.guid,
      this.syncDateTime,
      this.isActive});

  Data.fromJson(Map<String, dynamic> json) {
    firmId = json['FirmId'];
    userId = json['UserId'];
    custId = json['CustId'];
    firmName = json['FirmName'];
    firmType = json['FirmType'];
    pAN = json['PAN'];
    gST = json['GST'];
    add1 = json['Add1'];
    add2 = json['Add2'];
    add3 = json['Add3'];
    pincodeId = json['PincodeId'];
    stateId = json['StateId'];
    phone1 = json['Phone1'];
    phone2 = json['Phone2'];
    mobile1 = json['Mobile1'];
    mobile2 = json['Mobile2'];
    email = json['Email'];
    guid = json['Guid'];
    syncDateTime = json['SyncDateTime'];
    isActive = json['IsActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['FirmId'] = firmId;
    data['UserId'] = userId;
    data['CustId'] = custId;
    data['FirmName'] = firmName;
    data['FirmType'] = firmType;
    data['PAN'] = pAN;
    data['GST'] = gST;
    data['Add1'] = add1;
    data['Add2'] = add2;
    data['Add3'] = add3;
    data['PincodeId'] = pincodeId;
    data['StateId'] = stateId;
    data['Phone1'] = phone1;
    data['Phone2'] = phone2;
    data['Mobile1'] = mobile1;
    data['Mobile2'] = mobile2;
    data['Email'] = email;
    data['Guid'] = guid;
    data['SyncDateTime'] = syncDateTime;
    data['IsActive'] = isActive;
    return data;
  }
}
