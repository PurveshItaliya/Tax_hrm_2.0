// To parse this JSON data, do
//
//     final deleteDepartmentmodel = deleteDepartmentmodelFromJson(jsonString);

import 'dart:convert';

DeleteDepartmentmodel deleteDepartmentmodelFromJson(String str) =>
    DeleteDepartmentmodel.fromJson(json.decode(str));

String deleteDepartmentmodelToJson(DeleteDepartmentmodel data) =>
    json.encode(data.toJson());

class DeleteDepartmentmodel {
  bool? success;
  String? data;

  DeleteDepartmentmodel({this.success, this.data});

  factory DeleteDepartmentmodel.fromJson(Map<String, dynamic> json) =>
      DeleteDepartmentmodel(
        success: json["Success"] ?? false,
        data: json["data"] ?? "",
      );

  Map<String, dynamic> toJson() => {"Success": success, "data": data};
}
