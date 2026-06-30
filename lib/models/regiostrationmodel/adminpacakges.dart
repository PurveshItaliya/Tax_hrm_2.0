// To parse this JSON data, do
//
//     final userPackage = userPackageFromJson(jsonString);

import 'dart:convert';

List<UserPackage> userPackageFromJson(String str) => List<UserPackage>.from(json.decode(str).map((x) => UserPackage.fromJson(x)));

String userPackageToJson(List<UserPackage> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UserPackage {
    int id;
    String? packageName;
    bool isActive;

    UserPackage({
       required this.id,
        this.packageName,
       required this.isActive,
    });

    factory UserPackage.fromJson(Map<String, dynamic> json) => UserPackage(
        id: json["Id"],
        packageName: json["PackageName"],
        isActive: json["IsActive"],
    );

    Map<String, dynamic> toJson() => {
        "Id": id,
        "PackageName": packageName,
        "IsActive": isActive,
    };
}
