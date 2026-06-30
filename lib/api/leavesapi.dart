
// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/employes/withoutimg.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/leaveM/deleteleave_modal.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/models/leaveM/newleavemaster.dart';
import 'package:tax_hrm/models/leaveM/leavetypebyid.dart';
import 'package:tax_hrm/models/leavetype/applyleave.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class  LeaveMasterApiService{
  //==================== LeaveType List =======================\\
  Future getLeaveMlist() async {
    var url = Uri.parse(
        "${apibaseurl}api/HRM/LeaveTyppeList?CompanyID=${selectedcurentcompany!.companyId}");
    var response = await http.get(url, headers: {
      'Authorization':
          "bearer ${curentUser['token']}"
    });
    return getLeaveMasterFromJson(response.body);
  }
  //-----------------------------------------------------------------------------\\

  //=============================  CreateType  Master==============================\\
  Future createNewLeaveType({leaveTypeFnames,leaveTypesnames,carryForwards,yearlimits,setweekoff,setholiday,setDescriptions,setMonthlys,setquartely,setCguid,setPolicydate,setLeaveids, leaveType, bool? insertMoods,halfYear,leaveLimit})async{
    int numberOrZero(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final leaveTypeBody = {
      if (insertMoods != true) "LeaveTypeId": numberOrZero(setLeaveids),
      "CompanyId": numberOrZero(selectedcurentcompany!.companyId),
      "LeaveTypeFName": leaveTypeFnames,
      "LeaveTypeSName": leaveTypesnames,
      "CarryForward": numberOrZero(carryForwards),
      "YearlyLimit": numberOrZero(yearlimits),
      "ConsiderWeeklyOff": setweekoff == true,
      "ConsiderHoliday": setholiday == true,
      "Description": setDescriptions ?? '',
      "Monthly": numberOrZero(setMonthlys),
      "Quarterly": numberOrZero(setquartely),
      "Cguid": setCguid,
      "PolicyIssueDate": setPolicydate,
      "LeaveType": leaveType,
      "HalfYear": numberOrZero(halfYear),
      "LeaveLimit": leaveLimit ?? '',
    };

    var requestBody = {
      "Flag": insertMoods == true ? "A" : "U",
      "LeavesTypes": leaveTypeBody,
    };

    var url = Uri.parse("${apibaseurl}api/HRM/CreateLeavesType");

    var response = await http.post(url, body: jsonEncode(requestBody), headers: {
      'Authorization': 'bearer ${curentUser['token']}',
     'Content-Type': 'application/json',
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Create leave type failed (${response.statusCode}): ${response.body}');
    }

    final responseJson = jsonDecode(response.body);
    if (responseJson is Map && responseJson['Message'] != null && responseJson['Success'] != true) {
      throw Exception(responseJson['Message'].toString());
    }

    return newLeaveTypesFromJson(response.body);
  }

  //------------------------------------------------------------------------------\\

  //======================== Get LeaveMaster Byid ================================\\
  Future getLeaveByid({leaveid,leavecguid})async{
    var url = Uri.parse("${apibaseurl}api/HRM/LeaveTypeById?LeaveTypeId=$leaveid&Cguid=$leavecguid");
    var response = await http.get(url, headers: {
      'Authorization':
          "bearer ${curentUser['token']}"
    });
    return leaveTypeByidFromJson(response.body);
  }

  //---------------------Delete  Addition ------------------------\\
  Future deleteLeaveApi({leaveTypeID}) async {
    var response = await http.get(Uri.parse('${apibaseurl}api/HRM/DeleteType?LeaveTypeId=$leaveTypeID'),
    headers: {
      'Authorization': 'bearer  ${curentUser['token']}'
    });
    return getDeleteLeaveModalFromJson(response.body);
  }

  Future applyLeave({setEmployeId,sendCguid,leavedec,fromdate,todate,leaveYears,remarks,leaveTypeid,leaveStatusSet,dayTypes,leaveTypeCguids}) async {
    var bodys = {
      "Flag": "A",
      "EmpLeave": {
        "EmpId": setEmployeId,
        "CompanyId":'${selectedcurentcompany!.companyId}',
        "LeaveTypeId": leaveTypeid,
        "LeaveTypeCguid" : leaveTypeCguids,
        "LeaveDuration":leavedec,
        "LeaveDays": leavedec,
        "FromDate":fromdate,
        "ToDate":todate,
        "LeaveYear":leaveYears,
        "Remarks": remarks,
        "Cguid": "$sendCguid",
        "ApproveStatus":leaveStatusSet,
        "DayType":dayTypes,
      }
    };

    var url = Uri.parse("$apibaseurl/api/HRM/CreateEmpLeave");
    var response = await http.post(url, body: jsonEncode(bodys), headers: {
      'Authorization': 'bearer ${curentUser!['token']}',
      'Content-Type': 'application/json',
    });
    return leaveApplyFromJson(response.body);
  }




//-------------------------------Update ------------------------------------\\

  Future updateLeave({leaveId,sendCguid,leavedec,fromdate,todate,leaveYears,remarks,leaveTypeid,leaveStatus,setEmpid,dayTypes,leaveTypeCguids}) async {
    var bodys = {
      "Flag": "U",
      "EmpLeave": {
        "EmpLeaveId": leaveId,
        "EmpId": setEmpid,
        "CompanyId":'${selectedcurentcompany!.companyId}',
        "LeaveTypeId": leaveTypeid,
        "LeaveTypeCguid" : leaveTypeCguids,
        "LeaveDuration":"$leavedec",
        "LeaveDays": leavedec,
        "FromDate":fromdate,
        "ToDate":todate,
        "LeaveYear":leaveYears,
        "Remarks": remarks,
        "Cguid": "$sendCguid",
        "ApproveStatus":leaveStatus,
        "DayType":dayTypes,
      }
    };
    var url = Uri.parse("$apibaseurl/api/HRM/CreateEmpLeave");
    var response = await http.post(url, body: jsonEncode(bodys), headers: {
      'Authorization': 'bearer ${curentUser!['token']}',
      'Content-Type': 'application/json',
    });
    return leaveApplyFromJson(response.body);
  }




  //---------------------------------------    Delete Leave ------------------------------\\

  Future deleteLeave(leaveCguid)async{
    var url = Uri.parse("${apibaseurl}api/HRM/DeleteEmpLeave?Cguid=$leaveCguid");

    var response = await http.get(url, headers: {
      'Authorization': "bearer ${curentUser['token']}"
    });
    return getCompanyListModelFromJson(response.body);
  }
}
