// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/ifsc/create_new_model.dart';
import 'package:tax_hrm/models/ifsc/delete_ifsc_model.dart';
import 'package:tax_hrm/models/ifsc/get_ifscbyid_model.dart';
import 'package:tax_hrm/models/ifsc/ifsc_model.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class IfscApiCall {
  Future getifscdatalist() async {
    var url = Uri.parse(
      "$apibaseurl/api/Master/IFSCList?CustId=${curentUser['CustId']}&CompanyID=${selectedcurentcompany!.companyId}",
    );

    var response = await http.get(
      url,
      headers: {'Authorization': 'bearer ${curentUser['token']}'},
    );
    return ifscListModelFromJson(response.body);
  }

  //-----------------------------  Create Ifsc ----------------------------\\
  Future creatIfscApi(
    bankkname,
    brancchname,
    ifsc,
    cguids,
    bool insertmood,
    selectedid,
  ) async {
    var bodys = {
      "Flag": "A",
      "IFSCCode": {
        // "IFSCID": 1,
        "BankName": bankkname,
        "BranchName": brancchname,
        "IFSC": ifsc,
        "Guid": cguids,
        //"SyncDateTime": null,
        "CustId": '${curentUser!.custId}',
        "Entrydate": "${DateTime.now()}",
        "CompanyId": "${selectedcurentcompany!.companyId}",
      },
    };

    var updatebody = {
      "Flag": "U",
      "IFSCCode": {
        "IFSCID": selectedid,
        "BankName": bankkname,
        "BranchName": brancchname,
        "IFSC": ifsc,
        "Guid": cguids,
        //"SyncDateTime": null,
        "CustId": '${curentUser!.custId}',
        "Entrydate": "${DateTime.now()}",
        "CompanyId": "${selectedcurentcompany!.companyId}",
      },
    };

    var url = Uri.parse("$apibaseurl/api/Master/CreateIFSC");
    var response = await http.post(
      url,
      body: jsonEncode(insertmood == true ? bodys : updatebody),
      headers: {
        'Content-Type': 'application/json', // Specify JSON content type
        'Authorization': 'bearer ${curentUser['token']}',
      },
    );

    return createNewIfscFromJson(response.body);
  }

  //-----------------------------  Create Ifsc ----------------------------\\

  Future editIfsc(ifscid, bankkname, brancchname, ifsc, cid, curenttimr) async {
    var bodys = {
      "Flag": "U",
      "IFSCCode": {
        "IFSCID": ifscid,
        "BankName": bankkname,
        "BranchName": brancchname,
        "IFSC": ifsc,
        "Guid": "${curentUser!.cguid}",
        //"SyncDateTime": null,
        "CustId": cid,
        "Entrydate": curenttimr,
        "CompanyId": "${selectedcurentcompany!.companyId}",
      },
    };
    var url = Uri.parse("$apibaseurl/api/Master/CreateIFSC");
    var response = await http.post(
      url,
      body: jsonEncode(bodys),
      headers: {
        'Content-Type': 'application/json', // Specify JSON content type
        'Authorization': 'bearer ${curentUser['token']}',
      },
    );

    //
    return createNewIfscFromJson(response.body);
  }

  //---------------------------Get Byid IFSC-------------------------------------\\

  Future getIfscByid(ifscId) async {
    var url = Uri.parse("${apibaseurl}api/Master/IFSCListById?IFSCID=$ifscId");

    var response = await http.get(url,headers: {'Authorization': 'bearer ${curentUser['token']}'});
    return getIfscByidFromJson(response.body);
  }
  //-----------------------------------------------------------------------------------\\

  Future deleteIfsc(ifscid) async {
    var url = Uri.parse("${apibaseurl}api/Master/DeleteIFSC?IFSCID=$ifscid");

    var response = await http.get(url,headers: {'Authorization': 'bearer ${curentUser['token']}'}
    );
    return dleteMyTaskFromJson(response.body);
  }
}
