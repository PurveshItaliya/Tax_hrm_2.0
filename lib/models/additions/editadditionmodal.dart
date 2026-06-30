// To parse this JSON data, do
//
//     final editAdditionModal = editAdditionModalFromJson(jsonString);

import 'dart:convert';

EditAdditionModal editAdditionModalFromJson(String str) =>
    EditAdditionModal.fromJson(json.decode(str));

String editAdditionModalToJson(EditAdditionModal data) =>
    json.encode(data.toJson());

class EditAdditionModal {
  dynamic flag;
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
  AddDedMst? addDedMst;
  List<AddDedDetail>? addDedDetail;
  dynamic paySlip;
  dynamic pAttendence;

  EditAdditionModal({
    this.flag,
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
    this.pAttendence,
  });

  EditAdditionModal.fromJson(Map<String, dynamic> json) {
    flag = json['Flag'] ?? "";
    success = json['Success'] ?? false;
    attendence = json['Attendence'] ?? "";
    attendenceLogs = json['AttendenceLogs'] ?? "";
    attendenceLog = json['AttendenceLog'] ?? "";
    holiday = json['Holiday'] ?? "";
    leavesTypes = json['LeavesTypes'] ?? "";
    salaryStructure = json['SalaryStructure'] ?? "";
    empLeave = json['EmpLeave'] ?? "";
    empShiftGroup = json['EmpShiftGroup'] ?? "";
    event = json['Event'] ?? "";
    shiftMst = json['ShiftMst'] ?? "";
    recruitment = json['Recruitment'] ?? "";
    assetMst = json['AssetMst'] ?? "";
    salaryAdditionDedection = json['SalaryAdditionDedection'] ?? "";
    addDedMst = json['AddDedMst'] != null
        ? AddDedMst.fromJson(json['AddDedMst'])
        : null;
    if (json['AddDedDetail'] != null) {
      addDedDetail = <AddDedDetail>[];
      json['AddDedDetail'].forEach((v) {
            addDedDetail!.add(AddDedDetail.fromJson(v));
          }) ??
          [];
    }
    paySlip = json['PaySlip'] ?? "";
    pAttendence = json['PAttendence'] ?? "";
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
    if (addDedMst != null) {
      data['AddDedMst'] = addDedMst!.toJson();
    }
    if (addDedDetail != null) {
      data['AddDedDetail'] = addDedDetail!.map((v) => v.toJson()).toList();
    }
    data['PaySlip'] = paySlip;
    data['PAttendence'] = pAttendence;
    return data;
  }
}

class AddDedMst {
  int? addDedId;
  int? companyId;
  int? empId;
  String? name;
  dynamic amount;
  String? hRA;
  bool? hRAApplicable;
  String? dA;
  bool? dAApplicable;
  String? conveyance;
  bool? conveyanceApplicable;
  String? tDS;
  bool? tDSApplicable;
  String? eSIC;
  bool? eSICApplicable;
  String? pF;
  bool? pFApplicable;
  double? medicalAmt;
  bool? medicalAmtApplicable;
  double? specialAllowance;
  bool? specialApplicable;
  double? professinalTax;
  bool? professinalApplicable;
  dynamic percentage;
  dynamic remarks;
  String? cguid;
  String? userName;
  int? userId;
  String? iPAddress;
  String? serverName;
  String? flag;
  String? entryTime;
  dynamic empName;

  AddDedMst({
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

  AddDedMst.fromJson(Map<String, dynamic> json) {
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

class AddDedDetail {
  int? detailId;
  int? companyId;
  int? empId;
  dynamic type;
  dynamic amount;
  dynamic date;
  dynamic remarks;
  String? cguid;
  String? mstCguid;
  String? userName;
  int? userId;
  String? iPAddress;
  String? serverName;
  String? flag;
  String? entryTime;

  AddDedDetail({
    this.detailId,
    this.companyId,
    this.empId,
    this.type,
    this.amount,
    this.date,
    this.remarks,
    this.cguid,
    this.mstCguid,
    this.userName,
    this.userId,
    this.iPAddress,
    this.serverName,
    this.flag,
    this.entryTime,
  });

  AddDedDetail.fromJson(Map<String, dynamic> json) {
    detailId = json['DetailId'] ?? 0;
    companyId = json['CompanyId'] ?? 0;
    empId = json['EmpId'] ?? 0;
    type = json['Type'] ?? "";
    amount = json['Amount'] ?? "";
    date = json['Date'] ?? "";
    remarks = json['Remarks'] ?? "";
    cguid = json['Cguid'] ?? "";
    mstCguid = json['MstCguid'] ?? "";
    userName = json['UserName'] ?? "";
    userId = json['UserId'] ?? 0;
    iPAddress = json['IPAddress'] ?? "";
    serverName = json['ServerName'] ?? "";
    flag = json['Flag'] ?? "";
    entryTime = json['EntryTime'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['DetailId'] = detailId;
    data['CompanyId'] = companyId;
    data['EmpId'] = empId;
    data['Type'] = type;
    data['Amount'] = amount;
    data['Date'] = date;
    data['Remarks'] = remarks;
    data['Cguid'] = cguid;
    data['MstCguid'] = mstCguid;
    data['UserName'] = userName;
    data['UserId'] = userId;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['Flag'] = flag;
    data['EntryTime'] = entryTime;
    return data;
  }
}
