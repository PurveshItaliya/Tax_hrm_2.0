// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/deletmodel.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/postmodel.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class PositionsApiCall{

  // ******************************************* position creater Api *************************************************
  
  Future<dynamic> designationcreate({positionname,departmentname,positionststatus,bool? insertmod,positionid}) async {
    try {
      var bodys = {
        "PositionName": positionname,
        "DepartmentId": departmentname,
        "IsActive": positionststatus,
        "CustId":"${curentUser['CustId']}",
        "CompanyId":'${selectedcurentcompany!.companyId}'
      };
      var bodyupdate = {
        "Id": positionid,
        "PositionName": positionname,
        "DepartmentId": departmentname,
        "IsActive": positionststatus,
        "CustId":"${curentUser['CustId']}",
        "CompanyId":'${selectedcurentcompany!.companyId}'
      };

      var url = Uri.parse("${apibaseurl}api/Master/Createposition");
      var response = await http.post(url, 
        body: jsonEncode(insertmod == true?  bodys : bodyupdate), 
        headers: {'Authorization': 'bearer ${curentUser['token']}',
          'Content-Type': 'application/json',
        }
      );
      return positionCreateFromJson(response.body);
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  // ******************************************* position creater Api *************************************************

  // ******************************************* position delete Api *************************************************

  Future deletepositionfiles(id) async {

    var url = Uri.parse("${apibaseurl}api/Master/DeletPosition?Id=$id",);

    var response = await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'});
    return deletepositionFromJson(response.body);
  }

  // ******************************************* position delete Api *************************************************

  // ******************************************* position Get Api *************************************************

  Future positionss() async {
    var url =
        Uri.parse("${apibaseurl}api/Master/PositionList?CustId=${curentUser['CustId']}&CompanyId=${selectedcurentcompany!.companyId}");
    var response =
        await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'});

    return positionmodelFromJson(response.body);
  }

  // ******************************************* position Get Api *************************************************

  Future postionsById(setPostionIds)async{
  var url = Uri.parse(
    "$apibaseurl/api/Master/PositionById?Id=$setPostionIds&CompanyId=${selectedcurentcompany!.companyId}",);

  var response =
  await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'});


return positionmodelFromJson(response.body);
}

}