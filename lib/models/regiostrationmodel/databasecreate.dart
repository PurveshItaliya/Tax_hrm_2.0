// To parse this JSON data, do
//
//     final dataBaseCreate = dataBaseCreateFromJson(jsonString);

import 'dart:convert';

DataBaseCreate dataBaseCreateFromJson(String str) => DataBaseCreate.fromJson(json.decode(str));

String dataBaseCreateToJson(DataBaseCreate data) => json.encode(data.toJson());

class DataBaseCreate {
    bool success;
    String data;

    DataBaseCreate({
        required this.success,
        required this.data,
    });

    factory DataBaseCreate.fromJson(Map<String, dynamic> json) => DataBaseCreate(
        success: json["Success"],
        data: json["data"],
    );

    Map<String, dynamic> toJson() => {
        "Success": success,
        "data": data,
    };
}
