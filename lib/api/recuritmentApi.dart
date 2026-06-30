
// ignore_for_file: empty_catches, strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/recruitment/createrecuritment_modal.dart';
import 'package:tax_hrm/models/recruitment/deleterecuritment_model.dart';
import 'package:tax_hrm/models/recruitment/recruitmentmodel.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class RecuritmetntApiClass {

  //----------------Get All Recuritment Group Data-----------------------\\

  Future getrecuritmentgroup() async {
    var response = await http.get(Uri.parse('$apibaseurl/api/HRM/ReecruitmentList?CompanyID=${selectedcurentcompany!.companyId}',),
    headers: {'Authorization': 'bearer ${curentUser['token']}'});
    return recruitmentModalFromJson(response.body);
  }
  
  //----------------Get All Recuritment Group Data-----------------------\\

  //---------------------------   CreateNew Group and Update----------------------\\

  Future createrecruitmentgroup(bool?  checkInsert, {recruitmentId, name,custId,recruitmentDate,venue,departmentId, positionId, conductedBy, referenceBy, mobile, email, experience, lastSalary, expectedSalary, remark, cguId})async{
    try{
      var  setbody = {
        "Flag": "A",
        "Recruitment": {
          "Name": name,
          "CompanyId": selectedcurentcompany!.companyId,
          "CustId": custId,
          "RecruitmentDate": recruitmentDate,
          "Venue": venue,
          "DepartmentId": departmentId,
          "PositionId": positionId,
          "ConductedBy": conductedBy,
          "ReferenceBy": referenceBy,
          "MobileNo": mobile,
          "Email": email,
          "Experience": experience,
          "LastSalary": lastSalary,
          "ExpectedSalary": expectedSalary,
          "Remark": remark,
          "Cguid": cguId,
        }
      };

      var  updateBody = {
        "Flag": "U",
        "Recruitment": {
          "RecruitmentID": recruitmentId,
          "Name": name,
          "CompanyId": selectedcurentcompany!.companyId,
          "CustId": custId,
          "RecruitmentDate": recruitmentDate,
          "Venue": venue,
          "DepartmentId": departmentId,
          "PositionId": positionId,
          "ConductedBy": conductedBy,
          "ReferenceBy": referenceBy,
          "MobileNo": mobile,
          "Email": email,
          "Experience": experience,
          "LastSalary": lastSalary,
          "ExpectedSalary": expectedSalary,
          "Remark": remark,
          "Cguid": cguId,
        }
      };

      var response = await http.post(Uri.parse('$apibaseurl/api/HRM/CreateRecruit',),body: jsonEncode(checkInsert == true ? setbody : updateBody),headers: {'Content-Type' : 'application/json', 'Accept' : '*/*','Authorization':'bearer  ${curentUser['token']}'});
      return createRecuritmentModalFromJson(response.body);
    } catch(e){ /* ignored */ }
  }
  
  //---------------------------   CreateNew Group and Update----------------------\\

  //---------------------Delete  Recruitment ------------------------\\

  Future deleteRecuritment({setId}) async {
    var response = await http.get(Uri.parse('$apibaseurl/api/HRM/DeleteRecruitment?RecruitmentID=$setId'),headers: {'Authorization': 'bearer  ${curentUser['token']}'});
    return deleteRecuritmentModalFromJson(response.body);
  }

  //---------------------Delete  Recruitment ------------------------\\
}
