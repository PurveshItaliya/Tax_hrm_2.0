// To parse this JSON data, do
//
//     final departMnetModel = departMnetModelFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

//  Use When Match Data
import 'dart:convert';

List<DepartMnetModel> departMnetModelFromJson(String str) =>
    List<DepartMnetModel>.from(
      json.decode(str).map((x) => DepartMnetModel.fromJson(x)),
    );

String departMnetModelToJson(List<DepartMnetModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DepartMnetModel {
  int? id;
  String? departmentName;
  bool? isActive;
  String? custId;
  int? companyId;
  String? cguid;
  dynamic beginTime;
  dynamic endTime;
  dynamic shiftDuration;
  dynamic mon;
  dynamic tue;
  dynamic wed;
  dynamic thru;
  dynamic fri;
  dynamic sat;
  dynamic sun;
  dynamic break1Duration;
  dynamic break2Duration;

  DepartMnetModel({
    this.id,
    this.departmentName,
    this.isActive,
    this.custId,
    this.companyId,
    this.cguid,
    this.beginTime,
    this.endTime,
    this.shiftDuration,
    this.mon,
    this.tue,
    this.wed,
    this.thru,
    this.fri,
    this.sat,
    this.sun,
    this.break1Duration,
    this.break2Duration,
  });

  DepartMnetModel.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    departmentName = json['DepartmentName'] ?? "";
    isActive = json['IsActive'] ?? true;
    custId = json['CustId'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    cguid = json['Cguid'] ?? "";
    beginTime = json['BeginTime'] ?? "";
    endTime = json['EndTime'] ?? "";
    shiftDuration = json['ShiftDuration'] ?? "";
    mon = json['Mon'] ?? "";
    tue = json['Tue'] ?? "";
    wed = json['Wed'] ?? "";
    thru = json['Thru'] ?? "";
    fri = json['Fri'] ?? "";
    sat = json['Sat'] ?? "";
    sun = json['Sun'] ?? "";
    break1Duration = json['Break1Duration'] ?? "";
    break2Duration = json['Break2Duration'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['DepartmentName'] = departmentName;
    data['IsActive'] = isActive;
    data['CustId'] = custId;
    data['CompanyId'] = companyId;
    data['Cguid'] = cguid;
    data['BeginTime'] = beginTime;
    data['EndTime'] = endTime;
    data['ShiftDuration'] = shiftDuration;
    data['Mon'] = mon;
    data['Tue'] = tue;
    data['Wed'] = wed;
    data['Thru'] = thru;
    data['Fri'] = fri;
    data['Sat'] = sat;
    data['Sun'] = sun;
    data['Break1Duration'] = break1Duration;
    data['Break2Duration'] = break2Duration;
    return data;
  }
}
