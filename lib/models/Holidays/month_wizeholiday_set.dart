// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<GetHolidayById> getHolidayByIdFromJson(String str) => List<GetHolidayById>.from(json.decode(str).map((x) => GetHolidayById.fromJson(x)));

String getHolidayByIdToJson(List<GetHolidayById> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetHolidayById {
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
  String? holidayType;
  bool? ismultiple;
  String? enddate;
  String? masterCguid;

  GetHolidayById(
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
      this.masterCguid});

  GetHolidayById.fromJson(Map<String, dynamic> json) {
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
    final Map<String, dynamic> data = Map<String, dynamic>();
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
