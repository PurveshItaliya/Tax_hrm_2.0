// To parse this JSON data, do
//
//     final locationTimelInes = locationTimelInesFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<LocationTimelInes> locationTimelInesFromJson(String str) =>
    List<LocationTimelInes>.from(
      json.decode(str).map((x) => LocationTimelInes.fromJson(x)),
    );

String locationTimelInesToJson(List<LocationTimelInes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LocationTimelInes {
  int? locationId;
  int? empId;
  int? companyId;
  String? latitude;
  String? logitude;
  String? pincode;
  String? entryTime;
  String? deviceType;
  String? deviceName;
  String? address;

  LocationTimelInes({
    this.locationId,
    this.empId,
    this.companyId,
    this.latitude,
    this.logitude,
    this.pincode,
    this.entryTime,
    this.deviceType,
    this.deviceName,
    this.address,
  });

  LocationTimelInes.fromJson(Map<String, dynamic> json) {
    locationId = json['LocationId'] ?? 0;
    empId = json['EmpId'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    latitude = json['Latitude'] ?? "";
    logitude = json['Logitude'] ?? "";
    pincode = json['Pincode'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    deviceType = json['DeviceType'] ?? "";
    deviceName = json['DeviceName'] ?? "";
    address = json['Address'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['LocationId'] = locationId;
    data['EmpId'] = empId;
    data['CompanyId'] = companyId;
    data['Latitude'] = latitude;
    data['Logitude'] = logitude;
    data['Pincode'] = pincode;
    data['EntryTime'] = entryTime;
    data['DeviceType'] = deviceType;
    data['DeviceName'] = deviceName;
    data['Address'] = address;
    return data;
  }
}
