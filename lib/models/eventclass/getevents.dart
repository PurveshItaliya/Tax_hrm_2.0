// To parse this JSON data, do
//
//     final getEvents = getEventsFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<GetEvents> getEventsFromJson(String str) =>
    List<GetEvents>.from(json.decode(str).map((x) => GetEvents.fromJson(x)));

String getEventsToJson(List<GetEvents> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetEvents {
  int? eventId;
  String? eventName;
  int? companyId;
  String? startDate;
  String? endDate;
  String? eventPlace;
  String? description;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;

  GetEvents({
    this.eventId,
    this.eventName,
    this.companyId,
    this.startDate,
    this.endDate,
    this.eventPlace,
    this.description,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
  });

  GetEvents.fromJson(Map<String, dynamic> json) {
    eventId = json['EventId'] ?? 0;
    eventName = json['EventName'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    startDate = json['StartDate'] ?? "";
    endDate = json['EndDate'] ?? "";
    eventPlace = json['EventPlace'] ?? "";
    description = json['Description'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['EventId'] = eventId;
    data['EventName'] = eventName;
    data['CompanyId'] = companyId;
    data['StartDate'] = startDate;
    data['EndDate'] = endDate;
    data['EventPlace'] = eventPlace;
    data['Description'] = description;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    return data;
  }
}
