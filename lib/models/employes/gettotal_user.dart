// To parse this JSON data, do
//
//     final getTotalUserModal = getTotalUserModalFromJson(jsonString);

import 'dart:convert';

List<GetTotalUserModal> getTotalUserModalFromJson(String str) => List<GetTotalUserModal>.from(json.decode(str).map((x) => GetTotalUserModal.fromJson(x)));

String getTotalUserModalToJson(List<GetTotalUserModal> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetTotalUserModal {
  int? totalUser;
  dynamic permitUsers;

  GetTotalUserModal({this.totalUser, this.permitUsers});

  GetTotalUserModal.fromJson(Map<String, dynamic> json) {
    totalUser = json['TotalUser'];
    permitUsers = json['PermitUsers'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['TotalUser'] = totalUser;
    data['PermitUsers'] = permitUsers;
    return data;
  }
}
