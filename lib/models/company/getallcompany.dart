// To parse this JSON data, do
//
//     final getCompanyData = getCompanyDataFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<GetCompanyData> getCompanyDataFromJson(String str) => List<GetCompanyData>.from(json.decode(str).map((x) => GetCompanyData.fromJson(x)));

String getCompanyDataToJson(List<GetCompanyData> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class GetCompanyData {
  int? companyId;
  int? userId;
  int? firmId;
  String? companyName;
  String? add1;
  String? add2;
  String? add3;
  int? pincodeId;
  dynamic cityId;
  int? stateId;
  String? phone1;
  String? phone2;
  String? mobile1;
  String? mobile2;
  String? email;
  String? pAN;
  String? gST;
  String? guid;
  String? syncDateTime;
  bool? isActive;
  String? custId;
  dynamic areaName;
  dynamic cityName;
  String? stateName;
    String? cguid;
  dynamic code;

  GetCompanyData(
      {this.companyId,
      this.userId,
      this.firmId,
      this.companyName,
      this.add1,
      this.add2,
      this.add3,
      this.pincodeId,
      this.cityId,
      this.stateId,
      this.phone1,
      this.phone2,
      this.mobile1,
      this.mobile2,
      this.email,
      this.pAN,
      this.gST,
      this.guid,
      this.syncDateTime,
      this.isActive,
      this.custId,
      this.areaName,
      this.cityName,
      this.stateName,
       this.cguid,
      this.code});

  GetCompanyData.fromJson(Map<String, dynamic> json) {
    companyId = json['CompanyId'];
    userId = json['UserId'];
    firmId = json['FirmId'];
    companyName = json['CompanyName'];
    add1 = json['Add1'];
    add2 = json['Add2'];
    add3 = json['Add3'];
    pincodeId = json['PincodeId'];
    cityId = json['CityId'];
    stateId = json['StateId'];
    phone1 = json['Phone1'];
    phone2 = json['Phone2'];
    mobile1 = json['Mobile1'];
    mobile2 = json['Mobile2'];
    email = json['Email'];
    pAN = json['PAN'];
    gST = json['GST'];
    guid = json['Guid'];
    syncDateTime = json['SyncDateTime'];
    isActive = json['IsActive'];
    custId = json['CustId'];
    areaName = json['AreaName'];
    cityName = json['CityName'];
    stateName = json['StateName'];
      cguid = json['Cguid'];
    code = json['Code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['CompanyId'] = companyId;
    data['UserId'] = userId;
    data['FirmId'] = firmId;
    data['CompanyName'] = companyName;
    data['Add1'] = add1;
    data['Add2'] = add2;
    data['Add3'] = add3;
    data['PincodeId'] = pincodeId;
    data['CityId'] = cityId;
    data['StateId'] = stateId;
    data['Phone1'] = phone1;
    data['Phone2'] = phone2;
    data['Mobile1'] = mobile1;
    data['Mobile2'] = mobile2;
    data['Email'] = email;
    data['PAN'] = pAN;
    data['GST'] = gST;
    data['Guid'] = guid;
    data['SyncDateTime'] = syncDateTime;
    data['IsActive'] = isActive;
    data['CustId'] = custId;
    data['AreaName'] = areaName;
    data['CityName'] = cityName;
    data['StateName'] = stateName;
     data['Cguid'] = cguid;
    data['Code'] = code;
    return data;
  }
}
