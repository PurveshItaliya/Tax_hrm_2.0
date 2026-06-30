// ignore_for_file: camel_case_types

import 'dart:convert';

List<pincodem> pincodemFromJson(String str) =>
    List<pincodem>.from(json.decode(str).map((x) => pincodem.fromJson(x)));

String pincodemToJson(List<pincodem> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class pincodem {
  int? pinCodeID;
  int? code;
  dynamic userID;
  String? areaName;
  int? cityID;
  bool? isNew;
  bool? isSelect;

  pincodem(
      {this.pinCodeID,
      this.code,
      this.userID,
      this.areaName,
      this.cityID,
      this.isNew,
      this.isSelect});

  pincodem.fromJson(Map<String, dynamic> json) {
    pinCodeID = json['PinCodeID'] ?? 0;
    code = json['Code'] ?? 0;
    userID = json['UserID'] ?? '';
    areaName = json['AreaName'] ?? '';
    cityID = json['CityID'] ?? 0;
    isNew = json['IsNew'] ?? false;
    isSelect = json['IsSelect'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['PinCodeID'] = pinCodeID;
    data['Code'] = code;
    data['UserID'] = userID;
    data['AreaName'] = areaName;
    data['CityID'] = cityID;
    data['IsNew'] = isNew;
    data['IsSelect'] = isSelect;
    return data;
  }
}
