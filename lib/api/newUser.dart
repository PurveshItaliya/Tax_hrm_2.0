// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/regiostrationmodel/admin.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class CreateUserMaster {
  Future createUserM({regsid, crmStatus, officemanStatus, hrmStatus, customerId, fname, lname, mobilenumber, emails, usernames, creatPassword, newcompanyname, addres1, cguid, setIpaddres, context}) async {
    var bodys = {
      "Flag": "A", //flag "U" for update
      "tokens": {
        //"Id": 448,
        "RegTypeId": regsid,
        "PackageId": null,
        "CRM": crmStatus,
        "Officeman": officemanStatus,
        "HRM": hrmStatus,
        "CustId": "$customerId",
        "FirstName": "$fname",
        "LastName": "$lname",
        "Mobile": "$mobilenumber",
        "Email": "$emails",
        "Username": "$usernames",
        "Password": "$creatPassword",
        "Role": "Admin",
        "IsActive": true,
        "IPAddress": "$setIpaddres",
        "isDefault": true,
      },
      "companylist": [
        {
          //"CompanyId": 225,
          //"UserId": 41,
          "CompanyName": "$newcompanyname",
          "Add1": "$addres1",
          "Add2": "",
          "Add3": "",
          "PincodeId": "",
          "CityId": "",
          "StateId": "",
          "Phone1": "$mobilenumber",
          "Mobile1": "",
          "Mobile2": "",
          "Email": "$emails",
          "PAN": "",
          "GST": "",
          "Guid": "$cguid",
          "SyncDateTime": null,
          "IsActive": true,
          "CustId": "$customerId",
          //"Cguid":""
        },
      ],
    };

    var url = Uri.parse('$apibaseurl/api/Master/CreateUser');
    var response = await http.post(
      url,
      body: jsonEncode(bodys),
      headers: {
        "Access-Control-Allow-Origin": "*", // Required for CORS support to work
        "Access-Control-Allow-Headers":
            "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        'Content-Type': 'application/json',
        // 'Authorization':'bearer  ${curentUser!.token}'
      },
    );
    if (response.statusCode == 404) {
      var setresponse = jsonDecode(response.body);
      showtoastmessage('${setresponse['message']}');
      Navigator.pop(context);
    }
    return createAdminFromJson(response.body);
  }
}
