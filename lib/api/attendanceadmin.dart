// ignore_for_file: strict_top_level_inference

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/attendance/allemployeattendance.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class AdminAttenDanceApis {
  Future getDateAttendance(setDate) async {
    var url = Uri.parse('$apibaseurl/api/HRM/GetAttendenceList?CompanyID=${selectedcurentcompany!.companyId}&AttendenceDate=$setDate');

    var response = await http.get(url, headers: {
      'Authorization': 'bearer ${curentUser['token']}'
    });

    return allEmployeAttendanceFromJson(response.body);
  }
}
