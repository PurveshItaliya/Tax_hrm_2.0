// ignore_for_file: empty_catches, strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/additions/additem.dart';
import 'package:tax_hrm/models/additions/createadditionmodal.dart';
import 'package:tax_hrm/models/additions/deleteaddionmodal.dart';
import 'package:tax_hrm/models/additions/editadditionmodal.dart';
import 'package:tax_hrm/models/additions/employeaddition.dart';
import 'package:tax_hrm/models/additions/getaddtionmodal.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class AdditionApiClass {
  
  //----------------  Get All Addition Data -----------------------\\

  Future getadditiongroup() async {
    var response = await http.get(
      Uri.parse('${apibaseurl}api/HRM/AddDedList?CompanyID=${selectedcurentcompany!.companyId}',),
      headers: {
        'Authorization': 'bearer ${curentUser['token']}'
      }
    );
    return additionModalFromJson(response.body);
  }

  //----------------  Get All Addition Data -----------------------\\

  //---------------------------   CreateNew Group and Update----------------------\\


  Future createadditiongroup({bool? checkInsert, addDecId, empId, name, hra, da, conveyance, tds, esic, pf, medicalAmt, specialAllowance, professinalTax, cguId, type, amount1, date, remark1, detailId, hRAApplicable, dAApplicable, conveyApplicable, tDSApplicable, eSICApplicable, pFApplicable, medicalAmtApplicable, specialApplicable, professinalApplicable}) async {
    try {
      var addBody = {
      "Flag": checkInsert == true ? "A" : "U",
        "AddDedMst": {
          "CompanyId": selectedcurentcompany!.companyId,
          "EmpId": empId,
          "Name": name,
          "Amount": 0,
          "HRA": hra,
          "HRAApplicable": hRAApplicable,
          "DA": da,
          "DAApplicable": dAApplicable,
          "Conveyance": conveyance,
          "ConveyanceApplicable": conveyApplicable,
          "TDS": tds,
          "TDSApplicable": tDSApplicable,
          "ESIC": esic,
          "ESICApplicable": eSICApplicable,
          "PF": pf,
          "PFApplicable": pFApplicable,
          "MedicalAmt": medicalAmt,
          "MedicalAmtApplicable": medicalAmtApplicable,
          "SpecialAllowance": specialAllowance,
          "SpecialApplicable": specialApplicable,
          "ProfessinalTax": professinalTax,
          "ProfessinalApplicable": professinalApplicable,
          "Percentage": 0,
          "Remarks": "",
          "Cguid": cguId,
        },
        "AddDedDetail": additionList2,
      };
      var response = await http.post(
        Uri.parse('${apibaseurl}api/HRM/CreateAdditiondeduction',),
        body: jsonEncode(addBody),
        headers: {'Authorization': 'bearer  ${curentUser['token']}','Content-Type': 'application/json',},
      );
      return createAdditionModalFromJson(response.body);
    } catch (e) { /* ignored */ }
  }

  //---------------------------   CreateNew Group and Update----------------------\\


  //---------------------Delete  Addition ------------------------\\

  Future deleteAddition(cguId) async {
    var response = await http.get(
      Uri.parse('${apibaseurl}api/HRM/DeleteEntry?Cguid=$cguId'),
      headers: {
        'Authorization': 'bearer  ${curentUser['token']}'
      }
    );
    return deleteAdditionModalFromJson(response.body);
  }

  //---------------------Delete  Addition ------------------------\\

  //--------------------- Add Addition && Deduction ------------------------\\

  Future  getAdditionDeducation({employeId,month,year})async{
    var url = Uri.parse('${apibaseurl}api/HRM/AddDedListByMonth?CompanyId=${selectedcurentcompany!.companyId}&EmpId=$employeId&Month=$month&Year=$year');
    var response = await http.get(url, headers: {
      'Authorization': 'bearer ${curentUser['token']}',
    });
    return additionDeducationEmployeFromJson(response.body);
  }

  //--------------------- Add Addition && Deduction ------------------------\\

  Future updateAdditions({empId}) async {
    var response = await http.get(
      Uri.parse('${apibaseurl}api/HRM/AddDedListById?CompanyId=${selectedcurentcompany!.companyId}&EmpId=$empId'),
      headers: {'Authorization': 'bearer  ${curentUser['token']}','Content-Type': 'application/json',}
    );
    return editAdditionModalFromJson(response.body);
  }
  
}
