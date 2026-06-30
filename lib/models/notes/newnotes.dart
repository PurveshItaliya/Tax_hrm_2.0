// To parse this JSON data, do
//
//     final notesClass = notesClassFromJson(jsonString);

import 'dart:convert';

NotesClass notesClassFromJson(String str) =>
    NotesClass.fromJson(json.decode(str));

String notesClassToJson(NotesClass data) => json.encode(data.toJson());

class NotesClass {
  bool? success;
  String? data;

  NotesClass({this.success, this.data});

  factory NotesClass.fromJson(Map<String, dynamic> json) =>
      NotesClass(success: json["Success"] ?? true, data: json["data"] ?? "");

  Map<String, dynamic> toJson() => {"Success": success, "data": data};
}
