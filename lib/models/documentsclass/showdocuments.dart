// To parse this JSON data, do
//
//     final documentViews = documentViewsFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<DocumentViews> documentViewsFromJson(String str) =>
    List<DocumentViews>.from(
      json.decode(str).map((x) => DocumentViews.fromJson(x)),
    );

String documentViewsToJson(List<DocumentViews> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DocumentViews {
  int? id;
  String? filename;
  String? fileType;
  String? fileSize;
  String? category;
  String? timestamp;
  String? empId;
  String? companyId;
  String? filePath;
  String? firstName;

  DocumentViews({
    this.id,
    this.filename,
    this.fileType,
    this.fileSize,
    this.category,
    this.timestamp,
    this.empId,
    this.companyId,
    this.filePath,
    this.firstName,
  });

  DocumentViews.fromJson(Map<String, dynamic> json) {
    id = json['Id'] ?? 0;
    filename = json['Filename'] ?? "";
    fileType = json['FileType'] ?? "";
    fileSize = json['FileSize'] ?? "";
    category = json['Category'] ?? "";
    timestamp = json['Timestamp'] ?? "";
    empId = json['EmpId'] ?? "";
    companyId = json['CompanyId'] ?? "";
    filePath = json['FilePath'] ?? "";
    firstName = json['FirstName'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['Filename'] = filename;
    data['FileType'] = fileType;
    data['FileSize'] = fileSize;
    data['Category'] = category;
    data['Timestamp'] = timestamp;
    data['EmpId'] = empId;
    data['CompanyId'] = companyId;
    data['FilePath'] = filePath;
    data['FirstName'] = firstName;
    return data;
  }
}
