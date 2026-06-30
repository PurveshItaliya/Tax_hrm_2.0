// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<UserDataClass> userDataClassFromJson(String str) => List<UserDataClass>.from(json.decode(str).map((x) => UserDataClass.fromJson(x)));

String userDataClassToJson(List<UserDataClass> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UserDataClass {
  int? id;
  int? companyId;
  int? userId;
  int? projectId;
  int? categoryId;
  int? subCategoryId;
  String? date;
  bool? isActive;
  String? timePeriod;
  String? taskName;
  String? custId;
  String? flag;
  dynamic iPAddress;
  dynamic userName;
  String? serverName;
  String? entryTime;
  String? cguid;
  String? autoReference;
  dynamic projectName;
  String? categoryName;
  String? heading;

  UserDataClass(
      {this.id,
      this.companyId,
      this.userId,
      this.projectId,
      this.categoryId,
      this.subCategoryId,
      this.date,
      this.isActive,
      this.timePeriod,
      this.taskName,
      this.custId,
      this.flag,
      this.iPAddress,
      this.userName,
      this.serverName,
      this.entryTime,
      this.cguid,
      this.autoReference,
      this.projectName,
      this.categoryName,
      this.heading});

  UserDataClass.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    companyId = json['CompanyId'];
    userId = json['UserId'];
    projectId = json['ProjectId'];
    categoryId = json['CategoryId'];
    subCategoryId = json['SubCategoryId'];
    date = json['Date'];
    isActive = json['IsActive'];
    timePeriod = json['TimePeriod'];
    taskName = json['TaskName'];
    custId = json['CustId'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    userName = json['UserName'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    cguid = json['Cguid'];
    autoReference = json['AutoReference'];
    projectName = json['ProjectName'];
    categoryName = json['CategoryName'];
    heading = json['Heading'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Id'] = id;
    data['CompanyId'] = companyId;
    data['UserId'] = userId;
    data['ProjectId'] = projectId;
    data['CategoryId'] = categoryId;
    data['SubCategoryId'] = subCategoryId;
    data['Date'] = date;
    data['IsActive'] = isActive;
    data['TimePeriod'] = timePeriod;
    data['TaskName'] = taskName;
    data['CustId'] = custId;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['UserName'] = userName;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['Cguid'] = cguid;
    data['AutoReference'] = autoReference;
    data['ProjectName'] = projectName;
    data['CategoryName'] = categoryName;
    data['Heading'] = heading;
    return data;
  }
}
