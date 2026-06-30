// To parse this JSON data, do
//
//     final deleteRecuritmentModal = deleteRecuritmentModalFromJson(jsonString);

import 'dart:convert';

DeleteRecuritmentModal deleteRecuritmentModalFromJson(String str) => DeleteRecuritmentModal.fromJson(json.decode(str));

String deleteRecuritmentModalToJson(DeleteRecuritmentModal data) => json.encode(data.toJson());

class DeleteRecuritmentModal {
  bool success;
  String data;

  DeleteRecuritmentModal({
    required this.success,
    required this.data,
  });

  factory DeleteRecuritmentModal.fromJson(Map<String, dynamic> json) => DeleteRecuritmentModal(
    success: json["Success"] ?? false,
    data: json["data"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "Success": success,
    "data": data,
  };
}
