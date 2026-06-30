// To parse this JSON data, do
//
//     final paySlipView = paySlipViewFromJson(jsonString);

// ignore_for_file: prefer_collection_literals

import 'dart:convert';

List<PaySlipView> paySlipViewFromJson(String str) => List<PaySlipView>.from(
  json.decode(str).map((x) => PaySlipView.fromJson(x)),
);

String paySlipViewToJson(List<PaySlipView> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PaySlipView {
  int? paySlipId;
  String? date;
  int? companyId;
  int? empId;
  String? basicSalary;
  double? hRA;
  double? dA;
  double? conveyance;
  double? tDS;
  double? eSIC;
  dynamic eSICEmployerContribution;
  double? pF;
  dynamic pFEmployerContribution;
  double? overTime;
  double? oTHour;
  int? salaryMonth;
  int? salaryYear;
  dynamic lOP;
  double? finaleAmt;
  double? medicalAmt;
  double? otherAddition;
  double? specialAllowance;
  double? professinalTax;
  double? totalHours;
  double? workingHours;
  double? otherDeduction;
  double? grossEarnings;
  double? totalDeductions;
  double? grossSalary;
  String? totalBreak;
  double? pL;
  double? lWP;
  double? weeklyOff;
  double? totalPresent;
  String? weeklyOffHour;
  String? pLHour;
  String? lWPHour;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  String? empName;
  bool? payslipBoolValue;

  PaySlipView({
    this.paySlipId,
    this.date,
    this.companyId,
    this.empId,
    this.basicSalary,
    this.hRA,
    this.dA,
    this.conveyance,
    this.tDS,
    this.eSIC,
    this.eSICEmployerContribution,
    this.pF,
    this.pFEmployerContribution,
    this.overTime,
    this.oTHour,
    this.salaryMonth,
    this.salaryYear,
    this.lOP,
    this.finaleAmt,
    this.medicalAmt,
    this.otherAddition,
    this.specialAllowance,
    this.professinalTax,
    this.totalHours,
    this.workingHours,
    this.otherDeduction,
    this.grossEarnings,
    this.totalDeductions,
    this.grossSalary,
    this.totalBreak,
    this.pL,
    this.lWP,
    this.weeklyOff,
    this.totalPresent,
    this.weeklyOffHour,
    this.pLHour,
    this.lWPHour,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.empName,
    this.payslipBoolValue
  });

  double? _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  PaySlipView.fromJson(Map<String, dynamic> json) {
    paySlipId = _parseInt(json['PaySlipId']);
    date = json['Date']?.toString() ?? "";
    companyId = _parseInt(json['CompanyId']);
    empId = _parseInt(json['EmpId']);
    basicSalary = json['BasicSalary']?.toString() ?? "";
    hRA = _parseDouble(json['HRA']);
    dA = _parseDouble(json['DA']);
    conveyance = _parseDouble(json['Conveyance']);
    tDS = _parseDouble(json['TDS']);
    eSIC = _parseDouble(json['ESIC']);
    eSICEmployerContribution = json['ESICEmployerContribution'] ?? "";
    pF = _parseDouble(json['PF']);
    pFEmployerContribution = json['PFEmployerContribution'] ?? "";
    overTime = _parseDouble(json['OverTime']);
    oTHour = _parseDouble(json['OTHour']);
    salaryMonth = _parseInt(json['SalaryMonth']);
    salaryYear = _parseInt(json['SalaryYear']);
    lOP = json['LOP'] ?? "";
    finaleAmt = _parseDouble(json['FinaleAmt']);
    medicalAmt = _parseDouble(json['MedicalAmt']);
    otherAddition = _parseDouble(json['OtherAddition']);
    specialAllowance = _parseDouble(json['SpecialAllowance']);
    professinalTax = _parseDouble(json['ProfessinalTax']);
    totalHours = _parseDouble(json['TotalHours']);
    workingHours = _parseDouble(json['WorkingHours']);
    otherDeduction = _parseDouble(json['OtherDeduction']);
    grossEarnings = _parseDouble(json['GrossEarnings']);
    totalDeductions = _parseDouble(json['TotalDeductions']);
    grossSalary = _parseDouble(json['GrossSalary']);
    totalBreak = json['TotalBreak']?.toString() ?? "";
    pL = _parseDouble(json['PL']);
    lWP = _parseDouble(json['LWP']);
    weeklyOff = _parseDouble(json['WeeklyOff']);
    totalPresent = _parseDouble(json['TotalPresent']);
    weeklyOffHour = json['WeeklyOffHour']?.toString() ?? "";
    pLHour = json['PLHour']?.toString() ?? "";
    lWPHour = json['LWPHour']?.toString() ?? "";
    cguid = json['Cguid']?.toString() ?? "";
    flag = json['Flag']?.toString() ?? "";
    iPAddress = json['IPAddress']?.toString() ?? "";
    serverName = json['ServerName']?.toString() ?? "";
    entryTime = json['EntryTime']?.toString() ?? "";
    custId = json['CustId']?.toString() ?? "";
    empName = json['EmpName']?.toString() ?? "";
    
    // Safely parse payslipBoolValue as it might be a string like "false" or boolean false
    dynamic boolVal = json['PayslipBoolValue'];
    if (boolVal is bool) {
      payslipBoolValue = boolVal;
    } else if (boolVal is String) {
      payslipBoolValue = boolVal.toLowerCase() == 'true';
    } else {
      payslipBoolValue = false;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['PaySlipId'] = paySlipId;
    data['Date'] = date;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['BasicSalary'] = basicSalary;
    data['HRA'] = hRA;
    data['DA'] = dA;
    data['Conveyance'] = conveyance;
    data['TDS'] = tDS;
    data['ESIC'] = eSIC;
    data['ESICEmployerContribution'] = eSICEmployerContribution;
    data['PF'] = pF;
    data['PFEmployerContribution'] = pFEmployerContribution;
    data['OverTime'] = overTime;
    data['OTHour'] = oTHour;
    data['SalaryMonth'] = salaryMonth;
    data['SalaryYear'] = salaryYear;
    data['LOP'] = lOP;
    data['FinaleAmt'] = finaleAmt;
    data['MedicalAmt'] = medicalAmt;
    data['OtherAddition'] = otherAddition;
    data['SpecialAllowance'] = specialAllowance;
    data['ProfessinalTax'] = professinalTax;
    data['TotalHours'] = totalHours;
    data['WorkingHours'] = workingHours;
    data['OtherDeduction'] = otherDeduction;
    data['GrossEarnings'] = grossEarnings;
    data['TotalDeductions'] = totalDeductions;
    data['GrossSalary'] = grossSalary;
    data['TotalBreak'] = totalBreak;
    data['PL'] = pL;
    data['LWP'] = lWP;
    data['WeeklyOff'] = weeklyOff;
    data['TotalPresent'] = totalPresent;
    data['WeeklyOffHour'] = weeklyOffHour;
    data['PLHour'] = pLHour;
    data['LWPHour'] = lWPHour;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['EmpName'] = empName;
    data['PayslipBoolValue'] = payslipBoolValue;
    return data;
  }
}
