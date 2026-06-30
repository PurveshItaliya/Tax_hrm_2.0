// To parse this JSON data, do
//
//     final holidayById = holidayByIdFromJson(jsonString);

import 'dart:convert';

HolidayById holidayByIdFromJson(String str) =>
    HolidayById.fromJson(json.decode(str));

String holidayByIdToJson(HolidayById data) => json.encode(data.toJson());

class HolidayById {
  String? holidayName;
  int? companyId;
  List<String>? holidayDate;
  String? description;
  String? holidayGroup;
  String? holidayType;
  String? masterCguid;

  HolidayById({
    this.holidayName,
    this.companyId,
    this.holidayDate,
    this.description,
    this.holidayGroup,
    this.holidayType,
    this.masterCguid,
  });

  HolidayById.fromJson(Map<String, dynamic> json) {
    holidayName = json['HolidayName'] ?? '';
    companyId = json['CompanyId'] ?? 0;
    holidayDate = json['HolidayDate'].cast<String>() ?? [];
    description = json['Description'] ?? '';
    holidayGroup = json['HolidayGroup'] ?? '';
    holidayType = json['HolidayType'] ?? '';
    masterCguid = json['MasterCguid'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['HolidayName'] = holidayName;
    data['CompanyId'] = companyId;
    data['HolidayDate'] = holidayDate;
    data['Description'] = description;
    data['HolidayGroup'] = holidayGroup;
    data['HolidayType'] = holidayType;
    data['MasterCguid'] = masterCguid;
    return data;
  }
}
