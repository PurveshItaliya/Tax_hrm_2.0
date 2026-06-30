// To parse this JSON data, do
//
//     final regsFirmTypes = regsFirmTypesFromJson(jsonString);

import 'dart:convert';

List<RegsFirmTypes> regsFirmTypesFromJson(String str) => List<RegsFirmTypes>.from(json.decode(str).map((x) => RegsFirmTypes.fromJson(x)));

String regsFirmTypesToJson(List<RegsFirmTypes> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RegsFirmTypes {
    int? id;
    String? name;
    bool? isActive;

    RegsFirmTypes({
        this.id,
        this.name,
        this.isActive,
    });

    factory RegsFirmTypes.fromJson(Map<String, dynamic> json) => RegsFirmTypes(
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
