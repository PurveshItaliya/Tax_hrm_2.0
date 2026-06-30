// To parse this JSON data, do
//
//     final salarys = salarysFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<Salarys> salarysFromJson(String str) =>
    List<Salarys>.from(json.decode(str).map((x) => Salarys.fromJson(x)));

String salarysToJson(List<Salarys> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Salarys {
  int? salaryStructureId;
  String? effectiveDate;
  int? companyId;
  int? empId;
  String? basicSalary;
  String? hRA;
  String? dA;
  String? conveyance;
  bool? tDSApplicable;
  String? tDS;
  bool? eSICApplicable;
  String? eSIC;
  dynamic eSICEmployerContribution;
  bool? pFApplicable;
  String? pF;
  dynamic pFEmployerContribution;
  dynamic pTApplicable;
  dynamic tApplicable;
  bool? oTApplicable;
  dynamic oTPerhour;
  dynamic lOPApplicable;
  dynamic lOP;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  bool? hRAApplicable;
  bool? dAApplicable;
  bool? conveyanceApplicable;
  double? finaleAmt;
  double? medicalAmt;
  double? otherAddition;
  double? specialAllowance;
  double? professinalTax;
  double? totalHours;
  double? workingHours;
  double? otherDeduction;
  dynamic oTHour;
  String? monthYear;
  dynamic grossEarnings;
  dynamic totalDeductions;
  String? firstName;
  String? lastName;
  dynamic positionName;
  dynamic departmentName;
  bool? salaryBoolValue;

  Salarys({
    this.salaryStructureId,
    this.effectiveDate,
    this.companyId,
    this.empId,
    this.basicSalary,
    this.hRA,
    this.dA,
    this.conveyance,
    this.tDSApplicable,
    this.tDS,
    this.eSICApplicable,
    this.eSIC,
    this.eSICEmployerContribution,
    this.pFApplicable,
    this.pF,
    this.pFEmployerContribution,
    this.pTApplicable,
    this.tApplicable,
    this.oTApplicable,
    this.oTPerhour,
    this.lOPApplicable,
    this.lOP,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.hRAApplicable,
    this.dAApplicable,
    this.conveyanceApplicable,
    this.finaleAmt,
    this.medicalAmt,
    this.otherAddition,
    this.specialAllowance,
    this.professinalTax,
    this.totalHours,
    this.workingHours,
    this.otherDeduction,
    this.oTHour,
    this.monthYear,
    this.grossEarnings,
    this.totalDeductions,
    this.firstName,
    this.lastName,
    this.positionName,
    this.departmentName,
    this.salaryBoolValue,
  });

  Salarys.fromJson(Map<String, dynamic> json) {
    salaryStructureId = json['SalaryStructureId'] ?? 0;
    effectiveDate = json['EffectiveDate'] ?? "";
    companyId = json['CompanyId'] ?? 0;
    empId = json['EmpId'] ?? 0;
    basicSalary = json['BasicSalary'] ?? "";
    hRA = json['HRA'] ?? "";
    dA = json['DA'] ?? "";
    conveyance = json['Conveyance'] ?? "";
    tDSApplicable = json['TDSApplicable'] ?? false;
    tDS = json['TDS'] ?? "";
    eSICApplicable = json['ESICApplicable'] ?? false;
    eSIC = json['ESIC'] ?? "";
    eSICEmployerContribution = json['ESICEmployerContribution'] ?? "";
    pFApplicable = json['PFApplicable'] ?? false;
    pF = json['PF'] ?? "";
    pFEmployerContribution = json['PFEmployerContribution'] ?? "";
    pTApplicable = json['PTApplicable'] ?? "";
    tApplicable = json['TApplicable'] ?? "";
    oTApplicable = json['OTApplicable'] ?? false;
    oTPerhour = json['OTPerhour'] ?? "";
    lOPApplicable = json['LOPApplicable'] ?? "";
    lOP = json['LOP'] ?? "";
    cguid = json['Cguid'] ?? "";
    flag = json['Flag'] ?? "";
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    entryTime = json['EntryTime'] ?? "";
    custId = json['CustId'] ?? "";
    hRAApplicable = json['HRAApplicable'] ?? false;
    dAApplicable = json['DAApplicable'] ?? false;
    conveyanceApplicable = json['ConveyanceApplicable'] ?? false;
    finaleAmt = json['FinaleAmt'] ?? 0.0;
    medicalAmt = json['MedicalAmt'] ?? 0.0;
    otherAddition = json['OtherAddition'] ?? 0.0;
    specialAllowance = json['SpecialAllowance'] ?? 0.0;
    professinalTax = json['ProfessinalTax'] ?? 0.0;
    totalHours = json['TotalHours'] ?? 0.0;
    workingHours = json['WorkingHours'] ?? 0.0;
    otherDeduction = json['OtherDeduction'] ?? 0.0;
    oTHour = json['OTHour'] ?? "";
    monthYear = json['MonthYear'] ?? "";
    grossEarnings = json['GrossEarnings'] ?? "";
    totalDeductions = json['TotalDeductions'] ?? "";
    firstName = json['FirstName'] ?? "";
    lastName = json['LastName'] ?? "";
    positionName = json['PositionName'] ?? "";
    departmentName = json['DepartmentName'] ?? "";
    salaryBoolValue = json['SalaryBoolValue'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['SalaryStructureId'] = salaryStructureId;
    data['EffectiveDate'] = effectiveDate;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['BasicSalary'] = basicSalary;
    data['HRA'] = hRA;
    data['DA'] = dA;
    data['Conveyance'] = conveyance;
    data['TDSApplicable'] = tDSApplicable;
    data['TDS'] = tDS;
    data['ESICApplicable'] = eSICApplicable;
    data['ESIC'] = eSIC;
    data['ESICEmployerContribution'] = eSICEmployerContribution;
    data['PFApplicable'] = pFApplicable;
    data['PF'] = pF;
    data['PFEmployerContribution'] = pFEmployerContribution;
    data['PTApplicable'] = pTApplicable;
    data['TApplicable'] = tApplicable;
    data['OTApplicable'] = oTApplicable;
    data['OTPerhour'] = oTPerhour;
    data['LOPApplicable'] = lOPApplicable;
    data['LOP'] = lOP;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['HRAApplicable'] = hRAApplicable;
    data['DAApplicable'] = dAApplicable;
    data['ConveyanceApplicable'] = conveyanceApplicable;
    data['FinaleAmt'] = finaleAmt;
    data['MedicalAmt'] = medicalAmt;
    data['OtherAddition'] = otherAddition;
    data['SpecialAllowance'] = specialAllowance;
    data['ProfessinalTax'] = professinalTax;
    data['TotalHours'] = totalHours;
    data['WorkingHours'] = workingHours;
    data['OtherDeduction'] = otherDeduction;
    data['OTHour'] = oTHour;
    data['MonthYear'] = monthYear;
    data['GrossEarnings'] = grossEarnings;
    data['TotalDeductions'] = totalDeductions;
    data['FirstName'] = firstName;
    data['LastName'] = lastName;
    data['PositionName'] = positionName;
    data['DepartmentName'] = departmentName;
    data['SalaryBoolValue'] = salaryBoolValue;
    return data;
  }
}
