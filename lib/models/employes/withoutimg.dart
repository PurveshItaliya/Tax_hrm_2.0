// To parse this JSON data, do
//
//     final getCompanyListModel = getCompanyListModelFromJson(jsonString);

import 'dart:convert';

GetCompanyListModel getCompanyListModelFromJson(String str) =>
    GetCompanyListModel.fromJson(json.decode(str));

String getCompanyListModelToJson(GetCompanyListModel data) =>
    json.encode(data.toJson());

class GetCompanyListModel {
  bool success;
  String data;

  GetCompanyListModel({required this.success, required this.data});

  factory GetCompanyListModel.fromJson(Map<String, dynamic> json) =>
      GetCompanyListModel(
        success: json["Success"] ?? false,
        data: json["data"] ?? "",
      );

  Map<String, dynamic> toJson() => {"Success": success, "data": data};
}
