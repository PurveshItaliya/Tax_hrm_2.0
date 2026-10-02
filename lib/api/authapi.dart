// ignore_for_file: avoid_print, strict_top_level_inference

import 'dart:convert';
import 'dart:developer';
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
    print("----- API REQUEST: Login -----");
    print("URL: $url");
    print("Payload: ${jsonEncode(bodys)}");
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
    print("----- API RESPONSE: Login -----");
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");
    print("-------------------------------");
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

    log("----- API REQUEST: EmpLogin -----", name: "EmpLogin");
    log("URL: $url", name: "EmpLogin");
    log("Payload: $bodyJson", name: "EmpLogin");
    var response = await http.post(
      url,
      body: bodyJson,
      headers: headers,
    );
    log("----- API RESPONSE: EmpLogin -----", name: "EmpLogin");
    log("Status Code: ${response.statusCode}", name: "EmpLogin");
    log("Response Body: ${response.body}", name: "EmpLogin");
    log("----------------------------------", name: "EmpLogin");
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
