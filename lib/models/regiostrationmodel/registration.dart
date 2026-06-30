// To parse this JSON data, do
//
//     final registrationType = registrationTypeFromJson(jsonString);

import 'dart:convert';

List<RegistrationType> registrationTypeFromJson(String str) => List<RegistrationType>.from(json.decode(str).map((x) => RegistrationType.fromJson(x)));

String registrationTypeToJson(List<RegistrationType> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RegistrationType {
    int id;
    String? name;
    bool isActive;

    RegistrationType({
       required this.id,
        this.name,
       required this.isActive,
    });

    factory RegistrationType.fromJson(Map<String, dynamic> json) => RegistrationType(
        id: json["Id"],
        name: json["Name"],
        isActive: json["IsActive"],
    );

    Map<String, dynamic> toJson() => {
        "Id": id,
        "Name": name,
        "IsActive": isActive,
    };
}
