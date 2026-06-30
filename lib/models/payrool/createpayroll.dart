
// To parse this JSON data, do
//
//     final newPayRoll = newPayRollFromJson(jsonString);

import 'dart:convert';

NewPayRoll newPayRollFromJson(String str) => NewPayRoll.fromJson(json.decode(str));

String newPayRollToJson(NewPayRoll data) => json.encode(data.toJson());

class NewPayRoll {
  String? flag;
  bool? success;
  dynamic attendence;
  dynamic attendenceLogs;
  dynamic attendenceLog;
  dynamic holiday;
  dynamic leavesTypes;
  dynamic salaryStructure;
  dynamic empLeave;
  dynamic empShiftGroup;
  dynamic event;
  dynamic shiftMst;
  dynamic recruitment;
  dynamic assetMst;
  dynamic salaryAdditionDedection;
  dynamic addDedMst;
  dynamic addDedDetail;
  PaySlip? paySlip;
  dynamic pAttendence;

  NewPayRoll(
      {this.flag,
        this.success,
        this.attendence,
        this.attendenceLogs,
        this.attendenceLog,
        this.holiday,
        this.leavesTypes,
        this.salaryStructure,
        this.empLeave,
        this.empShiftGroup,
        this.event,
        this.shiftMst,
        this.recruitment,
        this.assetMst,
        this.salaryAdditionDedection,
        this.addDedMst,
        this.addDedDetail,
        this.paySlip,
        this.pAttendence});

  NewPayRoll.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'];
    success = json['Success'];
    attendence = json['Attendence'];
    attendenceLogs = json['AttendenceLogs'];
    attendenceLog = json['AttendenceLog'];
    holiday = json['Holiday'];
    leavesTypes = json['LeavesTypes'];
    salaryStructure = json['SalaryStructure'];
    empLeave = json['EmpLeave'];
    empShiftGroup = json['EmpShiftGroup'];
    event = json['Event'];
    shiftMst = json['ShiftMst'];
    recruitment = json['Recruitment'];
    assetMst = json['AssetMst'];
    salaryAdditionDedection = json['SalaryAdditionDedection'];
    addDedMst = json['AddDedMst'];
    addDedDetail = json['AddDedDetail'];
    paySlip =
    json['PaySlip'] != null ? PaySlip.fromJson(json['PaySlip']) : null;
    pAttendence = json['PAttendence'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Flag'] = flag;
    data['Success'] = success;
    data['Attendence'] = attendence;
    data['AttendenceLogs'] = attendenceLogs;
    data['AttendenceLog'] = attendenceLog;
    data['Holiday'] = holiday;
    data['LeavesTypes'] = leavesTypes;
    data['SalaryStructure'] = salaryStructure;
    data['EmpLeave'] = empLeave;
    data['EmpShiftGroup'] = empShiftGroup;
    data['Event'] = event;
    data['ShiftMst'] = shiftMst;
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    data['SalaryAdditionDedection'] = salaryAdditionDedection;
    data['AddDedMst'] = addDedMst;
    data['AddDedDetail'] = addDedDetail;
    if (paySlip != null) {
      data['PaySlip'] = paySlip!.toJson();
    }
    data['PAttendence'] = pAttendence;
    return data;
  }
}

class PaySlip {
  int? paySlipId;
  String? date;
  int? companyId;
  int? empId;
  String? basicSalary;
  dynamic hRA;
  dynamic dA;
  dynamic conveyance;
  dynamic tDS;
  dynamic eSIC;
  dynamic eSICEmployerContribution;
  dynamic pF;
  dynamic pFEmployerContribution;
  dynamic overTime;
  dynamic oTHour;
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
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic custId;
  dynamic empName;

  PaySlip(
      {this.paySlipId,
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
        this.empName});

  PaySlip.fromJson(Map<String, dynamic> json) {
    paySlipId = json['PaySlipId'];
    date = json['Date'];
    companyId = json['CompanyId'];
    empId = json['EmpId'];
    basicSalary = json['BasicSalary'];
    hRA = json['HRA'];
    dA = json['DA'];
    conveyance = json['Conveyance'];
    tDS = json['TDS'];
    eSIC = json['ESIC'];
    eSICEmployerContribution = json['ESICEmployerContribution'];
    pF = json['PF'];
    pFEmployerContribution = json['PFEmployerContribution'];
    overTime = json['OverTime'];
    oTHour = json['OTHour'];
    salaryMonth = json['SalaryMonth'];
    salaryYear = json['SalaryYear'];
    lOP = json['LOP'];
    finaleAmt = json['FinaleAmt'];
    medicalAmt = json['MedicalAmt'];
    otherAddition = json['OtherAddition'];
    specialAllowance = json['SpecialAllowance'];
    professinalTax = json['ProfessinalTax'];
    totalHours = json['TotalHours'];
    workingHours = json['WorkingHours'];
    otherDeduction = json['OtherDeduction'];
    grossEarnings = json['GrossEarnings'];
    totalDeductions = json['TotalDeductions'];
    grossSalary = json['GrossSalary'];
    totalBreak = json['TotalBreak'];
    pL = json['PL'];
    lWP = json['LWP'];
    weeklyOff = json['WeeklyOff'];
    totalPresent = json['TotalPresent'];
    weeklyOffHour = json['WeeklyOffHour'];
    pLHour = json['PLHour'];
    lWPHour = json['LWPHour'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    empName = json['EmpName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
    return data;
  }
}