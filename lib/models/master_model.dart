import 'dart:convert';

List<Mstclass> mstclassFromJson(String str) =>
    List<Mstclass>.from(json.decode(str).map((x) => Mstclass.fromJson(x)));

String mstclassToJson(List<Mstclass> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Mstclass {
  int? masterId;
  int? groupTag;
  String? masterTag1;
  dynamic masterTag2;
  String? description;
  String? remark;
  dynamic webDataMode;
  dynamic syncDateTime;
  dynamic iPAddress;
  dynamic flag;
  dynamic companyId;
  dynamic entryDate;
  dynamic img;

  Mstclass(
      {this.masterId,
      this.groupTag,
      this.masterTag1,
      this.masterTag2,
      this.description,
      this.remark,
      this.webDataMode,
      this.syncDateTime,
      this.iPAddress,
      this.flag,
      this.companyId,
      this.entryDate,
      this.img});

  Mstclass.fromJson(Map<String, dynamic> json) {
    masterId = json['MasterId'] ?? 0;
    groupTag = json['GroupTag'] ?? 0;
    masterTag1 = json['MasterTag1'] ?? "";
    masterTag2 = json['MasterTag2'] ?? "";
    description = json['Description'] ?? "";
    remark = json['Remark'] ?? "";
    webDataMode = json['WebDataMode'] ?? "";
    syncDateTime = json['SyncDateTime'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    flag = json['Flag'] ?? "";
    companyId = json['CompanyId'] ?? "";
    entryDate = json['EntryDate'] ?? "";
    img = json['Img'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['MasterId'] = masterId;
    data['GroupTag'] = groupTag;
    data['MasterTag1'] = masterTag1;
    data['MasterTag2'] = masterTag2;
    data['Description'] = description;
    data['Remark'] = remark;
    data['WebDataMode'] = webDataMode;
    data['SyncDateTime'] = syncDateTime;
    data['IPAddress'] = iPAddress;
    data['Flag'] = flag;
    data['CompanyId'] = companyId;
    data['EntryDate'] = entryDate;
    data['Img'] = img;
    return data;
  }
}
