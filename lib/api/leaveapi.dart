// ignore_for_file: strict_top_level_inference

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/leavetype/applyleave.dart';
import 'package:tax_hrm/models/leavetype/getuserList.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class  LeaveApiService{
  //==================== User  List =======================\\
  Future userLeaveList() async {
    var url = Uri.parse(
        "$apibaseurl/api/HRM/EmpleaveList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=${curentUser['Role'] =='Admin' || switchValue ?'0': curentUser['Id']}");

    var response = await http.get(url, headers: {
      'Authorization':
          "bearer ${curentUser['token']}"
    });

    return leaveListDataFromJson(response.body);
  }

   //---------------------------Apply for Leave-------------------------------\\


  Future applyLeave({setEmployeId,sendCguid,leavedec,fromdate,todate,leaveYears,remarks,leaveTypeid,leaveStatusSet,dayTypes,leaveTypeCguids}) async {
    var bodys = {
      "Flag": "A",
      "EmpLeave": {
        //"EmpLeaveId": 0,
        "EmpId": setEmployeId,
        "CompanyId":'${selectedcurentcompany!.companyId}',
        "LeaveTypeId": leaveTypeid,
        "LeaveTypeCguid" : leaveTypeCguids,
        "LeaveDuration":leavedec,
        "FromDate":fromdate,
        "ToDate":todate,
        "LeaveYear":leaveYears,
        "Remarks": remarks,
        "Cguid": "$sendCguid",
        "ApproveStatus":leaveStatusSet,
       //  "DayType":dayTypes,
      }
    };
  
    var url = Uri.parse("$apibaseurl/api/HRM/CreateEmpLeave");
    var response = await http.post(url, body: jsonEncode(bodys), headers: {
      'Authorization': 'bearer ${curentUser['token']}',
      'Content-Type': 'application/json',
    });

    return leaveApplyFromJson(response.body);
  }
}