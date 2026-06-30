// To parse this JSON data, do
//
//     final deleteAdditionModal = deleteAdditionModalFromJson(jsonString);

import 'dart:convert';

DeleteAdditionModal deleteAdditionModalFromJson(String str) =>
    DeleteAdditionModal.fromJson(json.decode(str));

String deleteAdditionModalToJson(DeleteAdditionModal data) =>
    json.encode(data.toJson());

class DeleteAdditionModal {
  bool success;
  String data;

  DeleteAdditionModal({required this.success, required this.data});

  factory DeleteAdditionModal.fromJson(Map<String, dynamic> json) =>
      DeleteAdditionModal(
        success: json["Success"] ?? false,
        data: json["data"] ?? "",
      );

  Map<String, dynamic> toJson() => {"Success": success, "data": data};
}
