// ignore_for_file: strict_top_level_inference

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/SalarryMaster/createStructuresalary.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/payrool/deletesalary.dart';
import 'package:tax_hrm/models/payrool/getpayrollattendancedata.dart';
import 'package:tax_hrm/models/payrool/getsalarydata.dart';
import 'package:tax_hrm/models/payrool/monthsbreak.dart';
import 'package:tax_hrm/models/payrool/viewPayroll.dart';
import 'package:tax_hrm/models/payrool/uploadPayrolldata.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class PayRollApiSerices{
  //--------------------------Get Month Break ------------------------\\
  Future getMonthsBreak(setEmployeId,setMonth,setYear)async{
      var url = Uri.parse("${apibaseurl}api/HRM/TotalDaywiseBreak?EmpId=$setEmployeId&Month=$setMonth&Year=$setYear");
      var response = await http.get(url, headers: {
        'Authorization': "bearer ${curentUser['token']}"
      }); 
      return monthwiseBreakFromJson(response.body);
  }

  //---------------------   GetPayRoll Attendance --------------------\\
  Future  getPayRollData(setEmployeId,setMonth,setYear)async{
    var url = Uri.parse("${apibaseurl}api/HRM/PayrollAttendenceList?EmpId=$setEmployeId&Month=$setMonth&Year=$setYear");
    var response = await http.get(url, headers: {
      'Authorization': "bearer ${curentUser['token']}"
    });
    return getPayRollAttendanceFromJson(response.body);
  }

  //---------------------   Upload PayRoll Attendance --------------------\\
  Future uploadPayrollAttendanceData({required List<GetPayRollAttendance> payrollData}) async {
    var body = {
      "Flag": "A",
      "PAttendence": payrollData.map((e) => e.toJson()).toList(),
    };

    var url = Uri.parse('$apibaseurl/api/HRM/CreatePayrollAttendence'); 
    
    var response = await http.post(
      url, 
      body: jsonEncode(body),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'bearer ${curentUser['token']}'
      }
    );
    return payRollUploadFromJson(response.body); 
  }

  //---------------------   Delete PayRoll Attendance --------------------\\
  Future deletePayrollAttendance({setEmployeId, setMonth, setYear}) async {
    var url = Uri.parse("${apibaseurl}api/HRM/DeletePayrollAttendence?Month=$setMonth&Year=$setYear&EmpId=$setEmployeId");
    var response = await http.get(url, headers: {
      'Authorization': "bearer ${curentUser['token']}"
    });
    // This probably returns a generic success response, using jsonDecode
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return response.body;
    }
  }

  //---------------------   GetPayRoll Salary --------------------\\
  Future getSalaryData({setEmpid,setMonths,setYears})async{
    var url = Uri.parse("${apibaseurl}api/HRM/SalaryList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=$setEmpid&Month=$setMonths&Year=$setYears");
    var response = await http.get(url, headers: {
      'Authorization': "bearer ${curentUser['token']}"
    });
    return salarysFromJson(response.body);
  }

  //---------------------------  Delete Salary Data ------------------------------\\

  Future deleteSalaryData({setSalaryStructureId})async{
    var url = Uri.parse("${apibaseurl}api/HRM/DeleteSalarystructure?SalaryStructureId=$setSalaryStructureId");
    var response = await http.get(url, headers: {
      'Authorization': "bearer ${curentUser['token']}"
    });
    return salaryDeleteClassFromJson(response.body);
  }

  Future getPaySlips(setEmployeId,setMonth,setYear)async{
    var url = Uri.parse("$apibaseurl/api/HRM/PayslipList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=$setEmployeId&Month=$setMonth&Year=$setYear");
    var response = await http.get(url, headers: {
      'Authorization': "bearer ${curentUser['token']}"
    });
    return paySlipViewFromJson(response.body);
  }

  // Create Structure Salary
  Future createnewStructure({setEmpid,basicSalary,hra,da,conveyance,tds,esic,pf,otphours,finalamount,medicalamount,othetaddition,specialAllowance,professinalTax,totalHours,workingHours,otherDeduction,monthYear,grossEarnings,totalDeductions,oTHour,salaryMonth,salaryYear,totalBreak,pL,lWP,weeklyOff,totalPresent,weeklyOffHour,pLHour,lWPHour,lOP,cguid})async{

  var createBody = {
    "Flag": "A",
    "SalaryStructure": {
      //"SalaryStructureId": 0,
      "EffectiveDate": null,
      "CompanyId": '${selectedcurentcompany!.companyId}',
      "EmpId": setEmpid,
      "BasicSalary": basicSalary,
      "HRAApplicable": true,
      "HRA": hra,
      "DAApplicable": true,
      "DA": da,
      "ConveyanceApplicable": true,
      "Conveyance": conveyance,
      "TDSApplicable": false,
      "TDS": tds,
      "ESICApplicable": false,
      "ESIC": esic,
      "ESICEmployerContribution": true,
      "PFApplicable": false,
      "PF": pf,
      "PFEmployerContribution": null,
      "PTApplicable": null,
      "TApplicable": null,
      "OTApplicable": true,
      "OTPerhour": otphours,
      "LOPApplicable": true,
      "LOP": lOP,
      "Cguid": cguid,
      "FinaleAmt":finalamount,
      "MedicalAmt": medicalamount,
      "OtherAddition": othetaddition,
      "SpecialAllowance": specialAllowance,
      "ProfessinalTax": professinalTax,
      "TotalHours": totalHours,
      "WorkingHours": workingHours,
      "OtherDeduction": otherDeduction,
      "MonthYear": monthYear,
      "GrossEarnings": grossEarnings,
      "TotalDeductions": totalDeductions,
      "OTHour": oTHour,
      "SalaryMonth": salaryMonth,
      "SalaryYear": salaryYear,
      "TotalBreak":totalBreak,
      "PL":pL,
      "LWP":lWP,
      "WeeklyOff":weeklyOff,
      "TotalPresent":totalPresent,
      "WeeklyOffHour":weeklyOffHour,
      "PLHour":pLHour,
      "LWPHour":lWPHour,
    }
  };
  var response = await http.post(Uri.parse('$apibaseurl/api/HRM/CreateSalaryStructure',),body: jsonEncode(createBody),headers: {'Content-Type' : 'application/json', 'Accept' : '*/*','Authorization':'bearer  ${curentUser['token']}'});
  return createSalaryStructureFromJson(response.body);
}

  // Update Structure Salary
  Future updateNewStructure({setEmpid,basicSalary,hra,da,conveyance,tds,esic,pf,otphours,finalamount,medicalamount,othetaddition,specialAllowance,professinalTax,totalHours,workingHours,otherDeduction,monthYear,grossEarnings,totalDeductions,oTHour,salaryMonth,salaryYear,totalBreak,pL,lWP,weeklyOff,totalPresent,weeklyOffHour,pLHour,lWPHour,lOP,cguid})async{
    var updateBody = {
      "Flag": "U",
      "SalaryStructure": {
        "EffectiveDate": null,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId": setEmpid,
        "BasicSalary": basicSalary,
        "HRAApplicable": true,
        "HRA": hra,
        "DAApplicable": true,
        "DA": da,
        "ConveyanceApplicable": true,
        "Conveyance": conveyance,
        "TDSApplicable": false,
        "TDS": tds,
        "ESICApplicable": false,
        "ESIC": esic,
        "ESICEmployerContribution": true,
        "PFApplicable": false,
        "PF": pf,
        "PFEmployerContribution": null,
        "PTApplicable": null,
        "TApplicable": null,
        "OTApplicable": true,
        "OTPerhour": otphours,
        "LOPApplicable": true,
        "LOP": lOP,
        "Cguid": cguid,
        "FinaleAmt":finalamount,
        "MedicalAmt": medicalamount,
        "OtherAddition": othetaddition,
        "SpecialAllowance": specialAllowance,
        "ProfessinalTax": professinalTax,
        "TotalHours": totalHours,
        "WorkingHours": workingHours,
        "OtherDeduction": otherDeduction,
        "MonthYear": monthYear,
        "GrossEarnings": grossEarnings,
        "TotalDeductions": totalDeductions,
        "OTHour": oTHour,
        "SalaryMonth": salaryMonth,
        "SalaryYear": salaryYear,
        "TotalBreak":totalBreak,
        "PL":pL,
        "LWP":lWP,
        "WeeklyOff":weeklyOff,
        "TotalPresent":totalPresent,
        "WeeklyOffHour":weeklyOffHour,
        "PLHour":pLHour,
        "LWPHour":lWPHour,
      }
    };

    var response = await http.post(Uri.parse('$apibaseurl/api/HRM/CreateSalaryStructure',),body: jsonEncode(updateBody),headers: {'Content-Type' : 'application/json', 'Accept' : '*/*','Authorization':'bearer  ${curentUser['token']}'});
    return createSalaryStructureFromJson(response.body);
  }
}