// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/employes/withoutimg.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/shiftclass/shiftgroup/createshiftgroup.dart';
import 'package:tax_hrm/models/shiftclass/shiftgroup/getallshifts.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/createshiftmaster_modal.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/utils/basicdata.dart';
class ShiftApiClass{

  //--------------------------------------------------------- Shift Master Page --------------------------------------\\

  //----------------Get All Shift Master Data-----------------------\\
  
  Future  getshiftGroupMaster()async{
    var response = await http.get(Uri.parse('${apibaseurl}api/HRM/EmpShiftgroup?CompanyID=${selectedcurentcompany!.companyId}',),headers: {'Authorization':'bearer  ${curentUser['token']}'});
    return shiftGroupFromJson(response.body);
  }

  //----------------Get All Shift Master Data-----------------------\\

  //---------------------------   Create New Shift Group and Update----------------------\\

  Future createshiftgroup({shiftfullname,shiftshortname,setCguid,bool? setinsertmood,shitid})async{
    var  setbody = {
      "Flag": "A",
      "EmpShiftGroup": {
        "ShiftGroupFname": shiftfullname,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "ShiftGroupSname": shiftshortname,
        "Cguid": setCguid
      }
    };

    var  setupdatebody = {
      "Flag": "U",
      "EmpShiftGroup": {
        "ShiftGroupID": shitid,
        "ShiftGroupFname": shiftfullname,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "ShiftGroupSname": shiftshortname,
        "Cguid": setCguid
      }
    };

    var response = await http.post(Uri.parse('${apibaseurl}api/HRM/CreateEmpShift',),body: jsonEncode(setinsertmood == true? setbody : setupdatebody),
      headers: {
        'Content-Type' : 'application/json', 'Accept' : '*/*',
        'Authorization':'bearer  ${curentUser['token']}'
      }
    );

    return shiftGroupCreateFromJson(response.body);
  }

  //---------------------------   Create New Shift Group and Update----------------------\\

  //--------------------- delete Shift Group ------------------------\\

  Future deleteShiftGroupMaster(setId)async{
    var response = await http.get(Uri.parse('${apibaseurl}api/HRM/DeleteGroup?ShiftGroupID=$setId',),headers: {'Authorization':'bearer  ${curentUser['token']}'});
    return getCompanyListModelFromJson(response.body);
  }

  //--------------------- delete Shift Group ------------------------\\

//--------------------------------------------------------- Shift Master Page --------------------------------------\\


//--------------------------------------------------------- Shift Timing Page --------------------------------------\\

  //------------------------- GetShift Master Data ------------------------\\

  Future getShiftTimingMaster({selectedcompany})async{
    var response = await http.get(Uri.parse('${apibaseurl}api/HRM/ShiftList?CompanyID=${selectedcurentcompany== null ?selectedcompany:selectedcurentcompany!.companyId}',),headers: {'Authorization':'bearer  ${curentUser['token']}'});
    return getShiftMasterDataFromJson(response.body);
  }

  //------------------------- GetShift Master Data ------------------------\\

  //--------------------- delete Shift Timing ------------------------\\

  Future deleteShiftTimingmasters(setId)async{
    var response = await http.get(Uri.parse('${apibaseurl}api/HRM/DeleteShift?ShiftID=$setId',),headers: {'Authorization':'bearer  ${curentUser['token']}'});
    return getCompanyListModelFromJson(response.body);
  }

  //--------------------- delete Shift Timing ------------------------\\

  //---------------------- create Shift Timing -------------------------------------------------\\

  Future createShifttimingMastergroup({shiftGroupGuid,departmentId,positionId,shiftfullname,shiftshortname,setCguid,bool? setinsertmood,shitid,beginTime, endTime , break1, break2, shiftDuration ,break1Duration, break2Duration, shiftType, mon, tue, wed, thru, fri, sat, sun, context}) async {
    var  setbody = {
      "Flag": "A",
      "ShiftMst": {
        "ShiftGroupGuid": shiftGroupGuid,
        "DepartmentId": departmentId,
        "PositionId": positionId,
        "CompanyId": selectedcurentcompany!.companyId,
        "ShiftFName": shiftfullname,
        "ShiftSName": shiftshortname,
        "BeginTime": beginTime,
        "EndTime": endTime,
        "Break1": break1,
        "Break2": break2,
        "ShiftDuration": shiftDuration,
        "Break1Duration": break1Duration,
        "Break2Duration": break2Duration,
        "ShiftType": shiftType,
        "Cguid": setCguid,
        "Mon": mon,
        "Tue": tue,
        "Wed": wed,
        "Thu": thru,
        "Fri": fri,
        "Sat": sat,
        "Sun": sun,
      }
    };

    var setupdatebody = {
      "Flag": "U",
      "ShiftMst": {
        "ShiftGroupGuid": shiftGroupGuid,
        "DepartmentId": departmentId,
        "PositionId": positionId,
        "CompanyId": selectedcurentcompany!.companyId,
        "ShiftFName": shiftfullname,
        "ShiftSName": shiftshortname,
        "BeginTime": beginTime,
        "EndTime": endTime,
        "Break1": break1,
        "Break2": break2,
        "ShiftDuration": shiftDuration,
        "Break1Duration": break1Duration,
        "Break2Duration": break2Duration,
        "ShiftType": shiftType,
        "Cguid": setCguid,
        "Mon": mon,
        "Tue": tue,
        "Wed": wed,
        "Thu": thru,
        "Fri": fri,
        "Sat": sat,
        "Sun": sun,
      }
    };

    var response = await http.post(Uri.parse('${apibaseurl}api/HRM/CreateShiftMst',),body: jsonEncode(setinsertmood == true? setbody : setupdatebody),headers: {'Content-Type' : 'application/json', 'Accept' : '*/*','Authorization':'bearer  ${curentUser['token']}'});
    return shiftMasterCreateFromJson(response.body);
  }

  //---------------------- create Shift Timing -------------------------------------------------\\



//--------------------------------------------------------- Shift Timing Page --------------------------------------\\

}