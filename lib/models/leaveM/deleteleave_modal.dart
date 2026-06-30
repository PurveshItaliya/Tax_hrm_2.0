// To parse this JSON data, do
//
//     final getDeleteLeaveModal = getDeleteLeaveModalFromJson(jsonString);

import 'dart:convert';

GetDeleteLeaveModal getDeleteLeaveModalFromJson(String str) => GetDeleteLeaveModal.fromJson(json.decode(str));

String getDeleteLeaveModalToJson(GetDeleteLeaveModal data) => json.encode(data.toJson());

class GetDeleteLeaveModal {
  bool? success;
  String? data;

  GetDeleteLeaveModal({this.success, this.data});

  GetDeleteLeaveModal.fromJson(Map<String, dynamic> json) {
    success = json['Success'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Success'] = success;
    data['data'] = this.data;
    return data;
  }
}
