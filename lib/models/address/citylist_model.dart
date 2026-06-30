// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<Citylistm> citylistmFromJson(String str) =>
    List<Citylistm>.from(json.decode(str).map((x) => Citylistm.fromJson(x)));

String citylistmToJson(List<Citylistm> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Citylistm {
  int? cityID;
  String? cityName;
  int? stateID;
  String? sTDCode;

  Citylistm({this.cityID, this.cityName, this.stateID, this.sTDCode});

  Citylistm.fromJson(Map<String, dynamic> json) {
    cityID = json['CityID'] ?? 0;
    cityName = json['CityName'] ?? "";
    stateID = json['StateID'] ?? 0;
    sTDCode = json['STDCode'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['CityID'] = cityID;
    data['CityName'] = cityName;
    data['StateID'] = stateID;
    data['STDCode'] = sTDCode;
    return data;
  }
}
