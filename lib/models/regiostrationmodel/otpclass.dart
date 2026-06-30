// To parse this JSON data, do
//
//     final otpSendClass = otpSendClassFromJson(jsonString);

import 'dart:convert';

OtpSendClass otpSendClassFromJson(String str) => OtpSendClass.fromJson(json.decode(str));

String otpSendClassToJson(OtpSendClass data) => json.encode(data.toJson());

class OtpSendClass {
    bool flag;
    String message;
    Data data;

    OtpSendClass({
        required this.flag,
        required this.message,
        required this.data,
    });

    factory OtpSendClass.fromJson(Map<String, dynamic> json) => OtpSendClass(
        flag: json["flag"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "flag": flag,
        "message": message,
        "data": data.toJson(),
    };
}

class Data {
    String batchId;

    Data({
        required this.batchId,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        batchId: json["batchId"],
    );

    Map<String, dynamic> toJson() => {
        "batchId": batchId,
    };
}
