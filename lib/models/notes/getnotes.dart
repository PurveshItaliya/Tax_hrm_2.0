// To parse this JSON data, do
//
//     final getNotes = getNotesFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<GetNotes> getNotesFromJson(String str) =>
    List<GetNotes>.from(json.decode(str).map((x) => GetNotes.fromJson(x)));

String getNotesToJson(List<GetNotes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetNotes {
  int? noteId;
  String? empId;
  String? companyId;
  String? cguid;
  String? entryTime;
  String? message;
  dynamic img;
  String? iPAddress;
  String? serverName;

  GetNotes({
    this.noteId,
    this.empId,
    this.companyId,
    this.cguid,
    this.entryTime,
    this.message,
    this.img,
    this.iPAddress,
    this.serverName,
  });

  GetNotes.fromJson(Map<String, dynamic> json) {
    noteId = json['NoteId'] ?? 0;
    empId = json['EmpId'] ?? "";
    companyId = json['CompanyId'] ?? "";
    cguid = json['Cguid'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    message = json['Message'] ?? "";
    img = json['Img'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['NoteId'] = noteId;
    data['EmpId'] = empId;
    data['CompanyId'] = companyId;
    data['Cguid'] = cguid;
    data['EntryTime'] = entryTime;
    data['Message'] = message;
    data['Img'] = img;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    return data;
  }
}
