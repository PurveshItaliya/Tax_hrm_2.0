// ignore_for_file: strict_top_level_inference

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/departmentclass/departemtmaster/createdepartment.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/deletedepartment.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class DepartMentData {
  
  //--------------  Get ALL DepartMent Data in List -------------------------------\\
  
  Future getdepartmentdata() async {
    var url = Uri.parse(
      '${apibaseurl}api/Master/DepartmentList?CustId=${curentUser['CustId']}&CompanyId=${selectedcurentcompany!.companyId}',
    );

    var response = await http.get(
      url,
      headers: {'Authorization': 'bearer ${curentUser['token']}'},
    );
    return departMnetModelFromJson(response.body);
  }

  //--------------  Get ALL DepartMent Data in List -------------------------------\\

  //----------------------------   Create Department --------------------------------\\
  
  Future createdepartment({tname ,status,bool? insertmood,setdid}) async {
    var bodys = {
      "DepartmentName": tname,
      "IsActive": status,
      "CustId":"${curentUser['CustId']}",
      "CompanyId": '${selectedcurentcompany!.companyId}'
    };

    var updatebody = {
      "Id": setdid,
      "DepartmentName": tname,
      "IsActive": status,
      "CustId":"${curentUser['CustId']}",
      "CompanyId": '${selectedcurentcompany!.companyId}'
    };

    var url = Uri.parse("${apibaseurl}api/Master/CreateDepartment");
    var response = await http.post(url, body: jsonEncode(insertmood == true?  bodys:updatebody), headers: {
      'Authorization': 'bearer ${curentUser['token']}',
      'Content-Type': 'application/json',
    });
    return cretaeDepartMentFromJson(response.body);
  }

  //----------------------------   Create Department --------------------------------\\

  //------------------------------------   Delete Department  -----------------------\\
  
  Future departdeletefiles(id) async {

    var url = Uri.parse("${apibaseurl}api/Master/DeletDepartment?Id=$id",);

    var response = await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'});

    return deleteDepartmentmodelFromJson(response.body);
  }

  //------------------------------------   Delete Department  -----------------------\\

  Future departmetById(departmentid)async{
  var url = Uri.parse(
      "$apibaseurl/api/Master/DepartmentLsitById?Id=$departmentid",);

    var response =
    await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'});

return departMnetModelFromJson(response.body);
}

}


