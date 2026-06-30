// To parse this JSON data, do
//
//     final additionModal = additionModalFromJson(jsonString);

import 'dart:convert';

List<AdditionModal> additionModalFromJson(String str) =>
    List<AdditionModal>.from(
      json.decode(str).map((x) => AdditionModal.fromJson(x)),
    );

String additionModalToJson(List<AdditionModal> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AdditionModal {
  int? addDedId;
  int? companyId;
  int? empId;
  String? name;
  double? amount;
  String? hRA;
  bool? hRAApplicable;
  String? dA;
  bool? dAApplicable;
  String? conveyance;
  bool? conveyanceApplicable;
  String? tDS;
  bool? tDSApplicable;
  String? eSIC;
  dynamic eSICApplicable;
  String? pF;
  bool? pFApplicable;
  double? medicalAmt;
  bool? medicalAmtApplicable;
  double? specialAllowance;
  bool? specialApplicable;
  double? professinalTax;
  bool? professinalApplicable;
  double? percentage;
  String? remarks;
  String? cguid;
  String? userName;
  int? userId;
  String? iPAddress;
  String? serverName;
  String? flag;
  String? entryTime;
  String? empName;

  AdditionModal({
    this.addDedId,
    this.companyId,
    this.empId,
    this.name,
    this.amount,
    this.hRA,
    this.hRAApplicable,
    this.dA,
    this.dAApplicable,
    this.conveyance,
    this.conveyanceApplicable,
    this.tDS,
    this.tDSApplicable,
    this.eSIC,
    this.eSICApplicable,
    this.pF,
    this.pFApplicable,
    this.medicalAmt,
    this.medicalAmtApplicable,
    this.specialAllowance,
    this.specialApplicable,
    this.professinalTax,
    this.professinalApplicable,
    this.percentage,
    this.remarks,
    this.cguid,
    this.userName,
    this.userId,
    this.iPAddress,
    this.serverName,
    this.flag,
    this.entryTime,
    this.empName,
  });

  AdditionModal.fromJson(Map<String, dynamic> json) {
    addDedId = json['AddDedId'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    empId = json['EmpId'] ?? 0;
    name = json['Name'] ?? "";
    amount = json['Amount'] ?? 0.0;
    hRA = json['HRA'] ?? "";
    hRAApplicable = json['HRAApplicable'] ?? false;
    dA = json['DA'] ?? "";
    dAApplicable = json['DAApplicable'] ?? false;
    conveyance = json['Conveyance'] ?? "";
    conveyanceApplicable = json['ConveyanceApplicable'] ?? false;
    tDS = json['TDS'] ?? "";
    tDSApplicable = json['TDSApplicable'] ?? false;
    eSIC = json['ESIC'] ?? "";
    eSICApplicable = json['ESICApplicable'] ?? false;
    pF = json['PF'] ?? "";
    pFApplicable = json['PFApplicable'] ?? false;
    medicalAmt = json['MedicalAmt'] ?? 0.0;
    medicalAmtApplicable = json['MedicalAmtApplicable'] ?? false;
    specialAllowance = json['SpecialAllowance'] ?? 0.0;
    specialApplicable = json['SpecialApplicable'] ?? false;
    professinalTax = json['ProfessinalTax'] ?? 0.0;
    professinalApplicable = json['ProfessinalApplicable'] ?? false;
    percentage = json['Percentage'] ?? 0.0;
    remarks = json['Remarks'] ?? "";
    cguid = json['Cguid'] ?? "";
    userName = json['UserName'] ?? "";
    userId = json['UserId'] ?? 0;
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    flag = json['Flag'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    empName = json['EmpName'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['AddDedId'] = addDedId;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['Name'] = name;
    data['Amount'] = amount;
    data['HRA'] = hRA;
    data['HRAApplicable'] = hRAApplicable;
    data['DA'] = dA;
    data['DAApplicable'] = dAApplicable;
    data['Conveyance'] = conveyance;
    data['ConveyanceApplicable'] = conveyanceApplicable;
    data['TDS'] = tDS;
    data['TDSApplicable'] = tDSApplicable;
    data['ESIC'] = eSIC;
    data['ESICApplicable'] = eSICApplicable;
    data['PF'] = pF;
    data['PFApplicable'] = pFApplicable;
    data['MedicalAmt'] = medicalAmt;
    data['MedicalAmtApplicable'] = medicalAmtApplicable;
    data['SpecialAllowance'] = specialAllowance;
    data['SpecialApplicable'] = specialApplicable;
    data['ProfessinalTax'] = professinalTax;
    data['ProfessinalApplicable'] = professinalApplicable;
    data['Percentage'] = percentage;
    data['Remarks'] = remarks;
    data['Cguid'] = cguid;
    data['UserName'] = userName;
    data['UserId'] = userId;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['Flag'] = flag;
    data['EntryTime'] = entryTime;
    data['EmpName'] = empName;
    return data;
  }
}
