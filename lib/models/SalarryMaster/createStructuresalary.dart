// To parse this JSON data, do
//
//     final createSalaryStructure = createSalaryStructureFromJson(jsonString);

// ignore_for_file: file_names, prefer_collection_literals

import 'dart:convert';

CreateSalaryStructure createSalaryStructureFromJson(String str) => CreateSalaryStructure.fromJson(json.decode(str));

String createSalaryStructureToJson(CreateSalaryStructure data) => json.encode(data.toJson());
class CreateSalaryStructure {
  String? flag;
  bool? success;
  dynamic attendence;
  dynamic attendenceLogs;
  dynamic attendenceLog;
  dynamic holiday;
  dynamic leavesTypes;
  SalaryStructure? salaryStructure;
  dynamic empLeave;
  dynamic empShiftGroup;
  dynamic event;
  dynamic shiftMst;
  dynamic recruitment;
  dynamic assetMst;
  dynamic salaryAdditionDedection;
  dynamic addDedMst;
  dynamic addDedDetail;
  dynamic paySlip;
  dynamic pAttendence;

  CreateSalaryStructure(
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

  CreateSalaryStructure.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'];
    success = json['Success'];
    attendence = json['Attendence'];
    attendenceLogs = json['AttendenceLogs'];
    attendenceLog = json['AttendenceLog'];
    holiday = json['Holiday'];
    leavesTypes = json['LeavesTypes'];
    salaryStructure = json['SalaryStructure'] != null
        ? SalaryStructure.fromJson(json['SalaryStructure'])
        : null;
    empLeave = json['EmpLeave'];
    empShiftGroup = json['EmpShiftGroup'];
    event = json['Event'];
    shiftMst = json['ShiftMst'];
    recruitment = json['Recruitment'];
    assetMst = json['AssetMst'];
    salaryAdditionDedection = json['SalaryAdditionDedection'];
    addDedMst = json['AddDedMst'];
    addDedDetail = json['AddDedDetail'];
    paySlip = json['PaySlip'];
    pAttendence = json['PAttendence'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['Flag'] = flag;
    data['Success'] = success;
    data['Attendence'] = attendence;
    data['AttendenceLogs'] = attendenceLogs;
    data['AttendenceLog'] = attendenceLog;
    data['Holiday'] = holiday;
    data['LeavesTypes'] = leavesTypes;
    if (salaryStructure != null) {
      data['SalaryStructure'] = salaryStructure!.toJson();
    }
    data['EmpLeave'] = empLeave;
    data['EmpShiftGroup'] = empShiftGroup;
    data['Event'] = event;
    data['ShiftMst'] = shiftMst;
    data['Recruitment'] = recruitment;
    data['AssetMst'] = assetMst;
    data['SalaryAdditionDedection'] = salaryAdditionDedection;
    data['AddDedMst'] = addDedMst;
    data['AddDedDetail'] = addDedDetail;
    data['PaySlip'] = paySlip;
    data['PAttendence'] = pAttendence;
    return data;
  }
}

class SalaryStructure {
  num? salaryStructureId;
  String? effectiveDate;
  num? companyId;
  num? empId;
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
  num? oTPerhour;
  dynamic lOPApplicable;
  dynamic lOP;
  String? cguid;
  dynamic flag;
  dynamic iPAddress;
  dynamic serverName;
  dynamic entryTime;
  dynamic custId;
  bool? hRAApplicable;
  bool? dAApplicable;
  bool? conveyanceApplicable;
  num? finaleAmt;
  num? medicalAmt;
  num? otherAddition;
  num? specialAllowance;
  num? professinalTax;
  num? totalHours;
  num? workingHours;
  num? otherDeduction;
  num? oTHour;
  String? monthYear;
  num? salaryMonth;
  num? salaryYear;
  num? grossEarnings;
  num? totalDeductions;
  String? totalBreak;
  num? pL;
  num? lWP;
  num? weeklyOff;
  num? totalPresent;
  num? grossSalary;
  String? weeklyOffHour;
  String? pLHour;
  String? lWPHour;
  dynamic firstName;
  dynamic lastName;
  dynamic positionName;
  dynamic departmentName;

  SalaryStructure(
      {this.salaryStructureId,
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
      this.salaryMonth,
      this.salaryYear,
      this.grossEarnings,
      this.totalDeductions,
      this.totalBreak,
      this.pL,
      this.lWP,
      this.weeklyOff,
      this.totalPresent,
      this.grossSalary,
      this.weeklyOffHour,
      this.pLHour,
      this.lWPHour,
      this.firstName,
      this.lastName,
      this.positionName,
      this.departmentName});

  SalaryStructure.fromJson(Map<String, dynamic> json) {
    salaryStructureId = json['SalaryStructureId'];
    effectiveDate = json['EffectiveDate'];
    companyId = json['CompanyId'];
    empId = json['EmpId'];
    basicSalary = json['BasicSalary'];
    hRA = json['HRA'];
    dA = json['DA'];
    conveyance = json['Conveyance'];
    tDSApplicable = json['TDSApplicable'];
    tDS = json['TDS'];
    eSICApplicable = json['ESICApplicable'];
    eSIC = json['ESIC'];
    eSICEmployerContribution = json['ESICEmployerContribution'];
    pFApplicable = json['PFApplicable'];
    pF = json['PF'];
    pFEmployerContribution = json['PFEmployerContribution'];
    pTApplicable = json['PTApplicable'];
    tApplicable = json['TApplicable'];
    oTApplicable = json['OTApplicable'];
    oTPerhour = json['OTPerhour'];
    lOPApplicable = json['LOPApplicable'];
    lOP = json['LOP'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    hRAApplicable = json['HRAApplicable'];
    dAApplicable = json['DAApplicable'];
    conveyanceApplicable = json['ConveyanceApplicable'];
    finaleAmt = json['FinaleAmt'];
    medicalAmt = json['MedicalAmt'];
    otherAddition = json['OtherAddition'];
    specialAllowance = json['SpecialAllowance'];
    professinalTax = json['ProfessinalTax'];
    totalHours = json['TotalHours'];
    workingHours = json['WorkingHours'];
    otherDeduction = json['OtherDeduction'];
    oTHour = json['OTHour'];
    monthYear = json['MonthYear'];
    salaryMonth = json['SalaryMonth'];
    salaryYear = json['SalaryYear'];
    grossEarnings = json['GrossEarnings'];
    totalDeductions = json['TotalDeductions'];
    totalBreak = json['TotalBreak'];
    pL = json['PL'];
    lWP = json['LWP'];
    weeklyOff = json['WeeklyOff'];
    totalPresent = json['TotalPresent'];
    grossSalary = json['GrossSalary'];
    weeklyOffHour = json['WeeklyOffHour'];
    pLHour = json['PLHour'];
    lWPHour = json['LWPHour'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    positionName = json['PositionName'];
    departmentName = json['DepartmentName'];
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
    data['SalaryMonth'] = salaryMonth;
    data['SalaryYear'] = salaryYear;
    data['GrossEarnings'] = grossEarnings;
    data['TotalDeductions'] = totalDeductions;
    data['TotalBreak'] = totalBreak;
    data['PL'] = pL;
    data['LWP'] = lWP;
    data['WeeklyOff'] = weeklyOff;
    data['TotalPresent'] = totalPresent;
    data['GrossSalary'] = grossSalary;
    data['WeeklyOffHour'] = weeklyOffHour;
    data['PLHour'] = pLHour;
    data['LWPHour'] = lWPHour;
    data['FirstName'] = firstName;
    data['LastName'] = lastName;
    data['PositionName'] = positionName;
    data['DepartmentName'] = departmentName;
    return data;
  }
}
