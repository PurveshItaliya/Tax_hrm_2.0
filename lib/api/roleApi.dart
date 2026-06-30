// ignore_for_file: strict_top_level_inference
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/role/create_role.dart';
import 'package:tax_hrm/models/role/delete_role.dart';
import 'package:tax_hrm/models/role/get_role_model.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class Roleapi {
  //Role get
  Future getRole() async {
    var url = Uri.parse(
        "$apibaseurl/api/Master/RoleList?CustId=${curentUser['CustId']}&CompanyId=${selectedcurentcompany!.companyId}");

    var response = await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'});
    return getrolemodelFromJson(response.body);
  }

  //role post
  Future<dynamic> roleecreate(rolename,bool insertmood,setRid) async {
      var bodys = {
        "Role": rolename,
        "IsActive": true,
        "CustId": "${curentUser['CustId']}",
        "CompanyId":"${selectedcurentcompany!.companyId}"
      };
        var updateBody = {
        "RoleId": setRid,
        "Role": rolename,
        "IsActive": true,
        "CustId": "${curentUser['CustId']}",
        "CompanyId":"${selectedcurentcompany!.companyId}"
      };
      var url = Uri.parse("$apibaseurl/api/Master/CreateRole");
      var response = await http.post(url, body: jsonEncode(insertmood == true ? bodys : updateBody), headers: {'Authorization': 'bearer ${curentUser['token']}'});
      return postrolemodelFromJson(response.body);  
  }

  //delete role
  Future roledeletefiles(custId) async {
    var url = Uri.parse(
    "$apibaseurl/api/Master/DeletRole?RoleId=$custId");
    var response = await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'});
    return deleteroleemodelFromJson(response.body);
  }

}
