// To parse this JSON data, do
//
//     final updateShiftMaster = updateShiftMasterFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

UpdateShiftMaster updateShiftMasterFromJson(String str) => UpdateShiftMaster.fromJson(json.decode(str));

String updateShiftMasterToJson(UpdateShiftMaster data) => json.encode(data.toJson());

class UpdateShiftMaster {
  int? shiftID;
  int? companyId;
  String? shiftFName;
  String? shiftSName;
  String? beginTime;
  String? endTime;
  bool? break1;
  bool? break2;
  dynamic break1BeginTime;
  dynamic break2BeginTime;
  dynamic break1EndTime;
  dynamic break2EndTime;
  String? shiftDuration;
  String? break1Duration;
  String? break2Duration;
  String? shiftType;
  int? departmentId;
  int? positionId;
  bool? mon;
  bool? tue;
  bool? wed;
  bool? thu;
  bool? fri;
  bool? sat;
  bool? sun;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? shiftGroupGuid;
  String? entryTime;
  String? custId;
  dynamic positionName;

  UpdateShiftMaster(
      {this.shiftID,
        this.companyId,
        this.shiftFName,
        this.shiftSName,
        this.beginTime,
        this.endTime,
        this.break1,
        this.break2,
        this.break1BeginTime,
        this.break2BeginTime,
        this.break1EndTime,
        this.break2EndTime,
        this.shiftDuration,
        this.break1Duration,
        this.break2Duration,
        this.shiftType,
        this.departmentId,
        this.positionId,
        this.mon,
        this.tue,
        this.wed,
        this.thu,
        this.fri,
        this.sat,
        this.sun,
        this.cguid,
        this.flag,
        this.iPAddress,
        this.serverName,
        this.shiftGroupGuid,
        this.entryTime,
        this.custId,
        this.positionName});

  UpdateShiftMaster.fromJson(Map<String, dynamic> json) {
    shiftID = json['ShiftID'];
    companyId = json['CompanyId'];
    shiftFName = json['ShiftFName'];
    shiftSName = json['ShiftSName'];
    beginTime = json['BeginTime'];
    endTime = json['EndTime'];
    break1 = json['Break1'];
    break2 = json['Break2'];
    break1BeginTime = json['Break1BeginTime'];
    break2BeginTime = json['Break2BeginTime'];
    break1EndTime = json['Break1EndTime'];
    break2EndTime = json['Break2EndTime'];
    shiftDuration = json['ShiftDuration'];
    break1Duration = json['Break1Duration'];
    break2Duration = json['Break2Duration'];
    shiftType = json['ShiftType'];
    departmentId = json['DepartmentId'];
    positionId = json['PositionId'];
    mon = json['Mon'];
    tue = json['Tue'];
    wed = json['Wed'];
    thu = json['Thu'];
    fri = json['Fri'];
    sat = json['Sat'];
    sun = json['Sun'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    shiftGroupGuid = json['ShiftGroupGuid'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    positionName = json['PositionName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ShiftID'] = shiftID;
    data['CompanyId'] = companyId;
    data['ShiftFName'] = shiftFName;
    data['ShiftSName'] = shiftSName;
    data['BeginTime'] = beginTime;
    data['EndTime'] = endTime;
    data['Break1'] = break1;
    data['Break2'] = break2;
    data['Break1BeginTime'] = break1BeginTime;
    data['Break2BeginTime'] = break2BeginTime;
    data['Break1EndTime'] = break1EndTime;
    data['Break2EndTime'] = break2EndTime;
    data['ShiftDuration'] = shiftDuration;
    data['Break1Duration'] = break1Duration;
    data['Break2Duration'] = break2Duration;
    data['ShiftType'] = shiftType;
    data['DepartmentId'] = departmentId;
    data['PositionId'] = positionId;
    data['Mon'] = mon;
    data['Tue'] = tue;
    data['Wed'] = wed;
    data['Thu'] = thu;
    data['Fri'] = fri;
    data['Sat'] = sat;
    data['Sun'] = sun;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['ShiftGroupGuid'] = shiftGroupGuid;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['PositionName'] = positionName;
    return data;
  }
}