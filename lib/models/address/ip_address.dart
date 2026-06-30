// To parse this JSON data, do
//
//     final getIpAddres = getIpAddresFromJson(jsonString);

import 'dart:convert';

GetIpAddres getIpAddresFromJson(String str) => GetIpAddres.fromJson(json.decode(str));

String getIpAddresToJson(GetIpAddres data) => json.encode(data.toJson());

class GetIpAddres {
    String? ip;

    GetIpAddres({
        this.ip,
    });

    factory GetIpAddres.fromJson(Map<String, dynamic> json) => GetIpAddres(
        ip: json["ip"],
    );

    Map<String, dynamic> toJson() => {
        "ip": ip,
    };
}
