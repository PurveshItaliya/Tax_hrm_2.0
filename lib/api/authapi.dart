// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/authclass/adminloginclass.dart';
import 'package:tax_hrm/models/authclass/checkclass.dart';
import 'package:tax_hrm/models/authclass/emploginclass.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class AuthLoginService {

  //----------------------- Check Admin UserName With Password ----------------------\\
  Future calllogin(entername, password) async {
    var bodys = {"Username": entername,"Password": password,};
    var url = Uri.parse('$apibaseurl/api/Token/Login');
    var response = await http.post(
      url,
      body: jsonEncode(bodys),
      headers: {
        "Access-Control-Allow-Origin": "*", // Required for CORS support to work
        "Access-Control-Allow-Headers":
            "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        'Content-Type': 'application/json',
      },
    );
    return userLoginFromJson(response.body);
  }

  //-----------------------Check User UserName With Password ----------------------\\
  Future callEmployeLogin(entername, password) async {
    var bodys = {"Username": entername, "Password": password};
    var url = Uri.parse('${apibaseurl}api/Token/EmpLogin');
    var headers = {
      "Access-Control-Allow-Origin": "*", // Required for CORS support to work
      "Access-Control-Allow-Headers":
          "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      'Content-Type': 'application/json',
    };
    var bodyJson = jsonEncode(bodys);

    // ── DEBUG: print curl command ────────────────────────────────────────────
    print('========== EMP LOGIN CURL ==========');
    print("curl -X POST '$url' \\");
    headers.forEach((k, v) => print("  -H '$k: $v' \\"));
    print("  -d '$bodyJson'");
    print('====================================');
    // ─────────────────────────────────────────────────────────────────────────

    var response = await http.post(
      url,
      body: bodyJson,
      headers: headers,
    );
    return empUserLoginFromJson(response.body);
  }

  //----------------------- Check Phone Number ----------------------\\
  Future checkPhoneNumbers(checkUserName,checkPassword) async {
    var uri = Uri.parse(
      '${apibaseurl}api/Master/CheckUserPassword?UserName=$checkUserName&Password=$checkPassword',
    );
    var rseponse = await http.get(uri);
    return checkNumbersFromJson(rseponse.body);
  }
}
