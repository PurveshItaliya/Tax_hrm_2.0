// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/authclass/emailotpcheck.dart';
import 'package:tax_hrm/models/regiostrationmodel/databasecreate.dart';
import 'package:tax_hrm/models/regiostrationmodel/registration.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class RegistrationApi {
  // Frim Type list api
  Future  getRegistrationApi(usertoken)async{
    var url = Uri.parse('${apibaseurl}api/Master/TypeList');
    var response = await http.get(url);

    return registrationTypeFromJson(response.body);
  }

  //----------------------------  Mobile no Otp Verification Otp ----------------------\\
  Future sendOtp(mobileNumber) async {
    var body = {"Mobile": mobileNumber};
    var url = Uri.parse('${apibaseurl}api/Master/GetOtp');
    var response = await http.post(
      url,
      body: jsonEncode(body),
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
            "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        'Content-Type': 'application/json',
      },
    );

    return jsonDecode(response.body);
  }

  //---------------------------------------------------------------------\\

  //------------------------------  Email Verification Otp -------------------------\\
  Future emailVerification(useEmail) async {
    var url = Uri.parse(
      'https://webcrmnode.taxfile.co.in/sentToOTP?email=$useEmail',
    );

    var response = await http.get(
      url,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
            "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        'Content-Type': 'application/json',
      },
    );

    return emailVerificationFromJson(response.body);
  }

  Future checkUserName({chcekusernames})async{
    var url = Uri.parse('${apibaseurl}api/Master/CheckUserNameExist?Username=$chcekusernames');

    var responses = await http.get(url);

    return jsonDecode(responses.body);
  }

  // --------------------- Check User Mobile Exist Api -----------------\\
  Future checkUserMobileApi(checkMobile) async {
    var url = Uri.parse('${apibaseurl}api/Master/CheckUserMobileExist?Mobile=$checkMobile');

    var response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });
  
    return jsonDecode(response.body);
  }

  Future createDataBase({setCustid})async{
    var url = Uri.parse('$apibaseurl/api/Master/CreateDb?CustId=$setCustid');

    var response = await http.post(url, headers: {
        'Content-Type': 'application/json',
    });

    return dataBaseCreateFromJson(response.body);
  }
}
