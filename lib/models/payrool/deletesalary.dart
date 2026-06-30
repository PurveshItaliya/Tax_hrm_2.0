// To parse this JSON data, do
//
//     final salaryDeleteClass = salaryDeleteClassFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

SalaryDeleteClass salaryDeleteClassFromJson(String str) =>
    SalaryDeleteClass.fromJson(json.decode(str));

String salaryDeleteClassToJson(SalaryDeleteClass data) =>
    json.encode(data.toJson());

class SalaryDeleteClass {
  bool? success;
  String? data;

  SalaryDeleteClass({this.success, this.data});

  SalaryDeleteClass.fromJson(Map<String, dynamic> json) {
    success = json['Success'] ?? false;
    data = json['data'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Success'] = success;
    data['data'] = this.data;
    return data;
  }
}
