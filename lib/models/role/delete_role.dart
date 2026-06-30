// To parse this JSON data, do
//
//     final deleteroleemodel = deleteroleemodelFromJson(jsonString);

// ignore_for_file: prefer_collection_literals, file_names

import 'dart:convert';

DeleteRoles  deleteroleemodelFromJson(String str) => DeleteRoles.fromJson(json.decode(str));

String deleteroleemodelToJson(DeleteRoles data) => json.encode(data.toJson());
class DeleteRoles {
  bool? success;
  String? data;

  DeleteRoles({this.success, this.data});

  DeleteRoles.fromJson(Map<String, dynamic> json) {
    success = json['Success'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Success'] = success;
    data['data'] = this.data;
    return data;
  }
}


