import 'dart:convert';

List<Departmentmodel> departmentmodelFromJson(String str) =>
    List<Departmentmodel>.from(
      json.decode(str).map((x) => Departmentmodel.fromJson(x)),
    );

String departmentmodelToJson(List<Departmentmodel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Departmentmodel {
  int id;
  String departmentName;
  bool isActive;

  Departmentmodel({
    required this.id,
    required this.departmentName,
    required this.isActive,
  });

  factory Departmentmodel.fromJson(Map<String, dynamic> json) =>
      Departmentmodel(
        id: json["Id"] ?? 0,
        departmentName: json["DepartmentName"] ?? "",
        isActive: json["IsActive"] ?? true,
      );

  Map<String, dynamic> toJson() => {
    "Id": id,
    "DepartmentName": departmentName,
    "IsActive": isActive,
  };
}
