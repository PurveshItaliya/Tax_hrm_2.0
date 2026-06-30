// To parse this JSON data, do
//
//     final getHolidayViews = getHolidayViewsFromJson(jsonString);

import 'dart:convert';

List<GetHolidayViews> getHolidayViewsFromJson(String str) => List<GetHolidayViews>.from(json.decode(str).map((x) => GetHolidayViews.fromJson(x)));

String getHolidayViewsToJson(List<GetHolidayViews> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetHolidayViews {
  int? holidayId;
  String? holidayName;
  int? companyId;
  String? holidayDate;
  String? description;
  dynamic holidayGroup;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  dynamic holidayType;
  bool? ismultiple;
  String? enddate;
  String? masterCguid;

  GetHolidayViews(
      {this.holidayId,
      this.holidayName,
      this.companyId,
      this.holidayDate,
      this.description,
      this.holidayGroup,
      this.cguid,
      this.flag,
      this.iPAddress,
      this.serverName,
      this.entryTime,
      this.custId,
      this.holidayType,
      this.ismultiple,
      this.enddate,
      this.masterCguid,
    });

  GetHolidayViews.fromJson(Map<String, dynamic> json) {
    holidayId = json['HolidayId'];
    holidayName = json['HolidayName'];
    companyId = json['CompanyId'];
    holidayDate = json['HolidayDate'];
    description = json['Description'];
    holidayGroup = json['HolidayGroup'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    holidayType = json['HolidayType'];
    ismultiple = json['ismultiple'];
    enddate = json['Enddate'];
    masterCguid = json['MasterCguid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['HolidayId'] = holidayId;
    data['HolidayName'] = holidayName;
    data['CompanyId'] = companyId;
    data['HolidayDate'] = holidayDate;
    data['Description'] = description;
    data['HolidayGroup'] = holidayGroup;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['HolidayType'] = holidayType;
    data['ismultiple'] = ismultiple;
    data['Enddate'] = enddate;
    data['MasterCguid'] = masterCguid;
    return data;
  }
}
