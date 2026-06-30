// ignore_for_file: strict_top_level_inference

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/departmentclass/departemtmaster/deletedepartment.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/payrool/createpayroll.dart';
import 'package:tax_hrm/models/payrool/viewPayroll.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class PaySlipApiSerices{
  //---------------------   GetPayRoll Salary --------------------\\
  Future getPaySlipData({setEmpid,setMonths,setYears})async{
    var url = Uri.parse("${apibaseurl}api/HRM/PayslipList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=$setEmpid&Month=$setMonths&Year=$setYears");
    var response = await http.get(url, headers: {
      'Authorization':"bearer ${curentUser['token']}"
    });
    return paySlipViewFromJson(response.body);
  }

  //---------------------------  Delete PlaySlip Data ------------------------------\\

  Future deletePlaySlipData({payslipcguid})async{
    var url = Uri.parse("${apibaseurl}api/HRM/DeletePayslip?Cguid=$payslipcguid");
    var response = await http.get(url, headers: {
      'Authorization':"bearer ${curentUser['token']}"
    });
    return deleteDepartmentmodelFromJson(response.body);
  }

  //-------------------------  Create PaySlip -------------------------\\
  Future createPaySlips({date,employeid,basicsalarys,hra,da,conveyance,tds,esic,pf,overtime,medicalamounts,otherAddition,specialAllowance,professinalTax,totalHours, oTPer, finaleAmt,workingHours,otherDeduction, monthYear, cguids,grossEarnings,totalDeductions,oTHour,salaryMonth,salaryYear,totalBreak,pl,lwp,weeklyOff,totalPresent,weeklyOffHour,pLHour,lWPHour, grossSalary})async{

    var createSlip = {
      "Flag": "A",
      "PaySlip": {
        "Date": date,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId": employeid,
        "BasicSalary": basicsalarys,
        "HRA": hra,
        "DA": da,
        "Conveyance":conveyance,
        "TDS": tds,
        "ESIC": esic,
        "PF": pf,
        "OverTime": overtime,
        "MedicalAmt": medicalamounts,
        "OtherAddition": otherAddition,
        "SpecialAllowance": specialAllowance,
        "ProfessinalTax": professinalTax,
        "TotalHours": totalHours,
        "FinaleAmt":finaleAmt,
        "WorkingHours":workingHours,
        "OtherDeduction": otherDeduction,
        "Cguid": cguids,
        "GrossEarnings":grossEarnings,
        "TotalDeductions":totalDeductions,
        "OTHour":oTHour,
        "SalaryMonth":salaryMonth,
        "SalaryYear":salaryYear,
        "TotalBreak":totalBreak,
        "PL":pl,
        "LWP":lwp,
        "WeeklyOff":weeklyOff,
        "TotalPresent": totalPresent,
        "WeeklyOffHour":weeklyOffHour,
        "PLHour":pLHour,
        "LWPHour":lWPHour
      }
    };
    var url = Uri.parse("$apibaseurl/api/HRM/CreatePayslip");


    var response = await http.post(url,body: jsonEncode(createSlip),headers: {'Content-Type': 'application/json','Authorization': "bearer ${curentUser['token']}"});

    return newPayRollFromJson(response.body);
  }


//----------------------------------------------------------------\\

  //-------------------------  Update PaySlip -------------------------\\
  Future updatePaySlips({date,employeid,basicsalarys,hra,da,conveyance,tds,esic,pf,overtime,medicalamounts,otherAddition,specialAllowance,professinalTax,totalHours, oTPer, finaleAmt,workingHours,otherDeduction, monthYear, cguids,grossEarnings,totalDeductions,oTHour,salaryMonth,salaryYear,totalBreak,pl,lwp,weeklyOff,totalPresent,weeklyOffHour,pLHour,lWPHour, grossSalary})async{
    var createSlip = {
      "Flag": "U",
      "PaySlip": {
        "Date": date,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId": employeid,
        "BasicSalary": basicsalarys,
        "HRA": hra,
        "DA": da,
        "Conveyance":conveyance,
        "TDS": tds,
        "ESIC": esic,
        "PF": pf,
        "OverTime": overtime,
        "MedicalAmt": medicalamounts,
        "OtherAddition": otherAddition,
        "SpecialAllowance": specialAllowance,
        "ProfessinalTax": professinalTax,
        "TotalHours": totalHours,
        "FinaleAmt":finaleAmt,
        "WorkingHours":workingHours,
        "OtherDeduction": otherDeduction,
        "Cguid": cguids,
        "GrossEarnings":grossEarnings,
        "TotalDeductions":totalDeductions,
        "OTHour":oTHour,
        "SalaryMonth":salaryMonth,
        "SalaryYear":salaryYear,
        "TotalBreak":totalBreak,
        "PL":pl,
        "LWP":lwp,
        "WeeklyOff":weeklyOff,
        "TotalPresent": totalPresent,
        "WeeklyOffHour":weeklyOffHour,
        "PLHour":pLHour,
        "LWPHour":lWPHour
      }
    };

    var url = Uri.parse("$apibaseurl/api/HRM/CreatePayslip");

    var response = await http.post(url, body: jsonEncode(createSlip), headers: {'Content-Type': 'application/json','Authorization': "bearer ${curentUser['token']}"});

    return newPayRollFromJson(response.body);
  }
}