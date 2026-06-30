// To parse this JSON data, do
//
//     final deleteposition = deletepositionFromJson(jsonString);

import 'dart:convert';

Deleteposition deletepositionFromJson(String str) =>
    Deleteposition.fromJson(json.decode(str));

String deletepositionToJson(Deleteposition data) => json.encode(data.toJson());

class Deleteposition {
  bool success;
  String data;
  dynamic datas;

  Deleteposition({
    required this.success,
    required this.data,
    required this.datas,
  });

  factory Deleteposition.fromJson(Map<String, dynamic> json) => Deleteposition(
    success: json["Success"] ?? true,
    data: json["data"] ?? "",
    datas: json["datas"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "Success": success,
    "data": data,
    "datas": datas,
  };
}
