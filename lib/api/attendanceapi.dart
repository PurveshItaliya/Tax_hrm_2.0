// ignore_for_file: empty_catches, strict_top_level_inference, non_constant_identifier_names, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/attendance/attendanceBlog.dart';
import 'package:tax_hrm/models/attendance/attendanceCountings.dart';
import 'package:tax_hrm/models/attendance/attendancePunchAdmin.dart';
import 'package:tax_hrm/models/attendance/attendancelogdelet.dart';
import 'package:tax_hrm/models/attendance/attendancelogupdate.dart';
import 'package:tax_hrm/models/attendance/editattendance.dart';
import 'package:tax_hrm/models/attendance/monathattendace.dart';
import 'package:tax_hrm/models/attendance/punchnow.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/top_hrm_model.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceApis{
  //------------------------  User Month Attendance Counting Api---------------------------\\
   
   Future getEmpMonathCounting(employeid,months,setYear)async{
     var url = Uri.parse('${apibaseurl}api/HRM/TotalAttendenceList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=$employeid&Month=$months&Year=$setYear');

     var response = await http.get(url, headers: {
       'Authorization': 'bearer ${curentUser['token']}',
     });
     return   attendanceCountingClassFromJson(response.body);
  }

  //----------------------   Get Attendance List -----------------------------\\
  
  Future getEmpMonathAttendace(employeid,months,setYear)async{

      var url = Uri.parse('${apibaseurl}api/HRM/GetEmpAttendenceList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=$employeid&MonthId=$months&YearId=$setYear');

      var response = await http.get(url, headers: {
        'Authorization': 'bearer ${curentUser['token']}',
      });
     return   employeAttendanceFromJson(response.body);
  }

  Future  getDateBlogEmp(setDate,employeid,setCompanyid,)async{
    var url = Uri.parse('${apibaseurl}api/HRM/GetAttendenceListById?CompanyID=$setCompanyid&EmpId=$employeid&AttendenceDate=$setDate');
    var response = await http.get(url, headers: {
      'Authorization': 'bearer ${curentUser['token']}',
    });
    try {
      final data = jsonDecode(response.body);
      if (data != null && data['AttendenceLog'] != null) {
         bool hasIn = false;
         bool hasOut = false;
         for (var log in data['AttendenceLog']) {
            if (log['Status'] == 'IN') hasIn = true;
            if (log['Status'] == 'OUT') hasOut = true;
         }
         final prefs = await SharedPreferences.getInstance();
         DateTime pDate = setDate is DateTime ? setDate : (DateTime.tryParse(setDate.toString()) ?? DateTime.now());
         String dateKey = '${pDate.year}-${pDate.month.toString().padLeft(2, '0')}-${pDate.day.toString().padLeft(2, '0')}';
         if (hasIn) await prefs.setBool('punched_in_$dateKey', true);
         if (hasOut) await prefs.setBool('punched_out_$dateKey', true);
      }
    } catch(e) { /* ignored */ }
    return   attendanceDayBlogFromJson(response.body);
  }

  Future notificationTokens(token,setEmpid) async {
    var bodys = {
      "Flag":"U",
      "Notification":{
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId": '$setEmpid',
        "DeviceToken": token,
        "CustId":'${curentUser['custId']}'
      }
    };
    var url = Uri.parse('${apibaseurl}api/HRM/CreateNotification');
    var response = await http.post(url, body: jsonEncode(bodys),
    headers: {'Content-Type': 'application/json','Authorization': 'bearer ${curentUser!.token}',});
  }
  
  //---------------------- Create Punch ---------------------------------------\\
  
  Future callPunch({sendCguid,setRemarks,weekoffStatus}) async {
    var bodys = {
      "Flag": "A",
      "IsUser": true,
      "Attendence": {
      "AttendenceDate":DateTime.now().toString(),
        "CompanyId":' ${selectedcurentcompany!.companyId}',
        "EmpId":'${curentUser['Id']}',
        "Cguid": "$sendCguid",
        "Present": true,
        "Absent": false,
        "WeekOff":weekoffStatus == false ? null : weekoffStatus
      },
      "AttendenceLog": [
        {
          "EmpId":'${curentUser['Id']}',
          "Cguid":"$sendCguid",
          "Remarks":setRemarks,
        }
      ]
    };

    var url = Uri.parse("${apibaseurl}api/HRM/NewNewCreateAttendence");
    var response = await http.post(url, body: jsonEncode(bodys), headers: {'Authorization': 'bearer ${curentUser!['token']}','Content-Type': 'application/json',});
    try {
      final data = jsonDecode(response.body);
      if (data != null && data['success'] == true && data['AttendenceLog'] != null && data['AttendenceLog'].isNotEmpty) {
         final lastStatus = data['AttendenceLog'].last['Status'];
         final prefs = await SharedPreferences.getInstance();
         DateTime pDate = DateTime.now();
         String dateKey = '${pDate.year}-${pDate.month.toString().padLeft(2, '0')}-${pDate.day.toString().padLeft(2, '0')}';
         if (lastStatus == 'IN') await prefs.setBool('punched_in_$dateKey', true);
         if (lastStatus == 'OUT') await prefs.setBool('punched_out_$dateKey', true);
      }
    } catch(e) { /* ignored */ }
    return punchNowFromJson(response.body);
  }

  //------------------------------------------  Call Punch with Img ---------------------------------\\

  Future<dynamic> callWithImgPunch({File?  FILES,setCguid,setLongitude,setLatitude,setLocation,required Function(dynamic val) listenRes}) async {
    var url = Uri.parse('${apibaseurl}api/HRM/AttendenmcelogUploads');
    var header = {'Content-Type' : 'application/json', 'Accept' : '*/*', 'Authorization':'bearer  ${curentUser['token']}'};
    try{
      var body = <String, String>{
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId": '${curentUser['Id']}',
        "Cguid": setCguid,
        "Longitude":setLongitude,
        "Latitude":setLatitude,
        "Location":setLocation,
        "Device":"mob",
      };
      var req = http.MultipartRequest("POST", url);
      req.headers.addAll(header);
      req.fields.addAll(body);
      if (FILES != null) {
        var pic = await http.MultipartFile.fromPath("Filename", FILES.path);
        req.files.add(pic);
      }
      var response = await req.send();
      response.stream.transform(utf8.decoder).listen((value) {listenRes(jsonDecode(value));});
    }catch(e) { /* ignored */ }
  }

  Future attendanceAddAdmin({attendanceDate,setInTime,setEmpid,setCguid,setRemarks,setweekoff})async{
    var  newbodys = {
      "IsUser": curentUser['Role'] == 'User' ? true : false,
      "Attendence": {
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId":setEmpid,
       "Cguid": setCguid,
        "IsOnLeave":false,
        "AttendenceDate":attendanceDate,
        "InTime":setInTime,
        "LateBy":1,
        "EarlyBy":1,
        "LeaveType":"",
        "Present": true,
        "Absent": false,
        "Holiday":false,
        "LeaveId":1,
        "WeekOff":setweekoff
      },
      "AttendenceLog": [
        {
          "EmpId":setEmpid,
          "LeaveType": "",
          "LeaveId": 1,
          "AttendenceDate":attendanceDate,
          "Time":setInTime,
          "Cguid":setCguid,
          "Remarks":setRemarks,
        }
      ]
    };  

    var url = Uri.parse("${apibaseurl}api/HRM/NewNewCreateAttendence");
    var response = await http.post(url, body: jsonEncode(newbodys), headers: {'Authorization': 'bearer ${curentUser['token']}','Content-Type': 'application/json',});

    try {
      return adminAttendancePunchFromJson(response.body);
    } catch (e) {
      throw Exception('Failed to parse server response. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }


  Future attenDanceUpdate({attendanceid,attendanceDate,setOutTime,setEmpid,updateInMood,setCguid})async{
    var  newbodys = {
      "IsUser": curentUser['Role'] == 'User' ? true : false,
      "Attendence": {
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId":setEmpid,
        "Cguid": setCguid,
        "IsOnLeave":false,
        "AttendenceDate":attendanceDate,
        "OutTime":setOutTime,
        "LateBy":1,
        "EarlyBy":1,
        "LeaveType":"", 
        "Present": true,
        "Absent": false,
        "Holiday":false,
        "LeaveId":1,
      },
      "AttendenceLog": [
        {
          "EmpId":setEmpid,
          "LeaveType": "",
          "LeaveId": 1,
          "AttendenceDate":attendanceDate,
          "Time":setOutTime,  
          "Cguid":setCguid,
        }
      ]
    };
    var url = Uri.parse("${apibaseurl}api/HRM/NewNewCreateAttendence");
    var response = await http.post(url, body: jsonEncode(newbodys), headers: {'Authorization': 'bearer ${curentUser['token']}','Content-Type': 'application/json',});

    return adminAttendancePunchFromJson(response.body);
  }


  //-----------------------   Log Update ------------------------\\
  Future updatelogs({attendanceid,empids,attendanceGuid,logid,logStatus,attendancedate,attendanceTime,logCjuid,remarks})async{
    var bodys = {
      "IsUser": curentUser['Role'] == 'User' ? true : false,
      "ATTENDENCE": {
        "ATTENDENCEID":attendanceid,
        "EMPID": empids,
        "CGUID":attendanceGuid
      },
      "ATTENDENCELOG": [
        {
          "LOGID":logid,
          "STATUS":logStatus,
          "ATTENDENCEDATE": attendancedate,
          "TIME": attendanceTime,
          "CGUID": logCjuid,
          "REMARKS":remarks
        }
      ]
    };

    var url = Uri.parse("${apibaseurl}api/HRM/NewNewAdminlog");
    var response = await http.post(url, body: jsonEncode(bodys), headers: {'Authorization': 'bearer ${curentUser['token']}','Content-Type': 'application/json',});

    return attendanceLogUpdateFromJson(response.body);
  }

  //----------------   Delete Attendance Log -----------------------\\
  Future  deleteAttendanceLog({attendanceId,setEmpid,setLogId,setStatus})async{
    var deletebody = {
      "IsUser": curentUser['Role'] == 'User' ? true : false,
      "ATTENDENCE": {
        "ATTENDENCEID":attendanceId,
        "EMPID": setEmpid
      },
      "ATTENDENCELOG": [
        {
          "LOGID":setLogId,
          "STATUS":setStatus
        }
      ]
    };

    var url = Uri.parse("${apibaseurl}api/HRM/NewNewDeletelog");
    var response = await http.post(url, body: jsonEncode(deletebody), headers: {'Authorization': 'bearer ${curentUser['token']}','Content-Type': 'application/json',});

    return attendanceLogDeleteFromJson(response.body);
  }

  Future absentEmploye({attendanceDate,setEmpid,attendanceCguid})async{
    var bodys = {
      //"Flag": "A",
      "IsUser": curentUser['Role'] == 'User' ? true : false,
      "Attendence": {
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "EmpId":setEmpid,
        "Cguid":attendanceCguid,
        "AttendenceDate":attendanceDate,
        "LateBy":1,
        "EarlyBy":1,
        "LeaveType":"",
        "Holiday":false,
        "LeaveId":1,
        "ShiftId": 1,
        "Present": false,
        "Absent": true,
      },
      "AttendenceLog": [
        {
          "EmpId":setEmpid,
          "ShiftId": 1,
          "Remarks": ""
        }
      ]
    };
    var url = Uri.parse("${apibaseurl}api/HRM/NewNewCreateAttendence");
    var response = await http.post(url, body: jsonEncode(bodys), headers: {'Authorization': 'bearer ${curentUser['token']}','Content-Type': 'application/json',});

    return attendanceEditsFromJson(response.body);
  }

  Future changeAbsentToPresnt(attendanceDate,setEmpid,setInTime,setOutTime)async{
    var bodys = {
      "Flag": "A",
      "Attendence":{
        "AttendenceDate": attendanceDate,
        "CompanyId":'${selectedcurentcompany!.companyId}',
        "EmpId": setEmpid,
        "InTime": setInTime,
        "OutTime": setOutTime,
        "IsOnLeave": false,
        "LateBy": 1,
        "EarlyBy": 1,
        "LeaveType": "",
        "Holiday": false,
        "LeaveId": 1,
        "ShiftId": 1,
        "Present": true,
        "Absent": false,
      },
      "AttendenceLog": [
        {
          "EmpId": setEmpid,
          "AttendenceDate": attendanceDate,
          "Time": setInTime,
          "Status": "IN",
          "InDeviceId": 1,
          "OutDeviceId": 2,
          "OverTime": "",
          "MissedOutPunch": false,
          "MissedInPunch": false,
          "Remarks": null,
        },
        {
          "EmpId": setEmpid,
          "AttendenceDate": attendanceDate,
          "Time": setOutTime,
          "Status": "OUT",
          "InDeviceId": 1,
          "OutDeviceId": 2,
          "OverTime": "",
          "MissedOutPunch": false,
          "MissedInPunch": false,
          "Remarks": null,
        }
      ]
    };
    

    var url = Uri.parse("${apibaseurl}api/HRM/InsertAttendence");
    var response = await http.post(url, body: jsonEncode(bodys), headers: {'Authorization': 'bearer ${curentUser['token']}','Content-Type': 'application/json',});

    return attendanceEditsFromJson(response.body);
  }

  Future getCompanyDataList(month,year) async {
    var url = Uri.parse(
      '${apibaseurl}api/HRM/HRMTopListReport?Month=$month&Year=$year ',
    );

    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'bearer ${curentUser['token']}',
      },
    );
    if (response.statusCode == 200) {
      return hrmTopListReportFromJson(response.body);
    } else {
      return response.statusCode;
    }
  }
}