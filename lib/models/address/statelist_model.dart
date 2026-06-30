// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<Statelistm> statelistmFromJson(String str) =>
    List<Statelistm>.from(json.decode(str).map((x) => Statelistm.fromJson(x)));

String statelistmToJson(List<Statelistm> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Statelistm {
  int? stateID;
  String? stateName;
  String? shortCode;
  dynamic stateCode;

  Statelistm({this.stateID, this.stateName, this.shortCode, this.stateCode});

  Statelistm.fromJson(Map<String, dynamic> json) {
    stateID = json['StateID'] ?? 0;
    stateName = json['StateName'] ?? "";
    shortCode = json['ShortCode'] ?? "";
    stateCode = json['StateCode'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['StateID'] = stateID;
    data['StateName'] = stateName;
    data['ShortCode'] = shortCode;
    data['StateCode'] = stateCode;
    return data;
  }
}
