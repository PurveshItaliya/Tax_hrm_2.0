// To parse this JSON data, do
//
//     final getForgotOtpModal = getForgotOtpModalFromJson(jsonString);

import 'dart:convert';

GetForgotOtpModal getForgotOtpModalFromJson(String str) => GetForgotOtpModal.fromJson(json.decode(str));

String getForgotOtpModalToJson(GetForgotOtpModal data) => json.encode(data.toJson());

class GetForgotOtpModal {
  bool? success;
  String? data;

  GetForgotOtpModal({this.success, this.data});

  GetForgotOtpModal.fromJson(Map<String, dynamic> json) {
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