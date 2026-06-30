// ignore_for_file: strict_top_level_inference, empty_catches

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/getMenuSettings_model.dart';
import 'package:tax_hrm/models/usermaster/userbyid.dart';
import 'package:tax_hrm/models/users/updateuser.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class AdminProfileApiClass {

  //==================== Get Admin Profile Data =======================\\

  Future getAdminProfileData() async {
    var url = Uri.parse(
      '${apibaseurl}api/Master/UsermstLsitById?Id=${curentUser['Id']}',
    );

    var response = await http.get(
      url,
      headers: {'Authorization': 'bearer ${curentUser['token']}'},
    );

    return adminProfilesFromJson(response.body);
  }

  //==================== Get Admin Profile Data =======================\\

  //==================== Update Admin Profile Data =======================\\

  Future  updateAdminProfile({firstName,lastName,mobile,email,username,password,role,isActive,}) async {
    var bodys =  {
      "Flag": "U",//flag "U" for update
      "tokens": {
        "Id": curentUser['Id'],
        "RegTypeId": curentUser['RegTypeId'],
        "PackageId": curentUser['PackageId'],
        "CRM": curentUser['CRM'],
        "Officeman": curentUser['Officeman'],
        "HRM": curentUser['HRM'],
        "CustId":curentUser['CustId'],
        "FirstName": firstName,
        "LastName": lastName,
        "Mobile": mobile,
        "Email": email,
        "Username": username,
        "Password": password,
        "Role": role,
        "IsActive": isActive,
        "isDefault":true,
        "IPAddress": curentUser['IPAddress'],
        "Cguid":  curentUser['Cguid'],
        "LicenseDate": curentUser['LicenseDate']
      },
    };

    try{
      var url = Uri.parse("${apibaseurl}api/Master/CreateUser");
      var response = await http.post(url, body: jsonEncode(bodys), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'bearer ${curentUser['token']}',
      });


      return updateAdminFromJson(response.body);
    }catch(e) { /* ignored */ }


}

  //==================== Update Admin Profile Data =======================\\

  //==================== select Sub Admin Menu Access =======================\\

  Future getMenuSettingsData({empId}) async {
    try {
      var url = Uri.parse(
        '${apibaseurl}api/Master/Getmenusettings?CompanyID=${selectedcurentcompany!.companyId}&Mode=HRM&EmpId=$empId',
      );
      var response = await http.get(
        url,
        headers: {'Authorization': 'bearer ${curentUser['token']}'},
      );
      return getMenuSettingsModelFromJson(response.body);
    } catch (e) { /* ignored */ }
  }

  //==================== select Sub Admin Menu Access =======================\\

  //----------------------------------------- Post Create Menu Settings ------------------------\\

  Future addCreateMenuSettings({
    flag,
    companyId,
    empId,
    isAdminFlag,
    isUserFlag,
  }) async {
    try {
      var bodys = {
        "FLAG": flag,
        "MenuSetting": [
          {
            "CompanyId": companyId,
            "EmpId": empId,
            "ColumnKey": "AsAdmin",
            "ColumnValue": isAdminFlag,
            "Mode": "HRM",
          },
          {
            "CompanyId": companyId,
            "EmpId": empId,
            "ColumnKey": "AsUser",
            "ColumnValue": isUserFlag,
            "Mode": "HRM",
          },
        ],
      };

      var url = Uri.parse('${apibaseurl}api/Master/CreateMenusettings');
      var response = await http.post(
        url,
        body: jsonEncode(bodys),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer ${curentUser['token']}',
        },
      );
      return response.body;
    } catch (e) { /* ignored */ }
  }

  //----------------------------------------- Post Create Menu Settings ------------------------\\

}
