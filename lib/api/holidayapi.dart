// ignore_for_file: strict_top_level_inference

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/Holidays/holidaybyid.dart';
import 'package:tax_hrm/models/Holidays/month_wizeholiday_set.dart';
import 'package:tax_hrm/models/Holidays/newgrop.dart';
import 'package:tax_hrm/models/employes/withoutimg.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class HolidayAPIS {

  //==================== Get Holiday List =======================\\

  Future<List<GetHolidayById>> getHolidaysByMonthYear({
    required int month,
    required int year,
  }) async {
      final url = Uri.parse(
        "${apibaseurl}api/HRM/GetHolidayList?CompanyID=${selectedcurentcompany!.companyId}&Month=$month&Year=$year",
      );
      
      var response = await http.get(url, headers: {
        'Authorization':"bearer ${curentUser['token']}"
      });
    return getHolidayByIdFromJson(response.body);
  }

  Future getHolidays() async { 
    var url = Uri.parse(
      "${apibaseurl}api/HRM/GetHolidayList?CompanyId=${selectedcurentcompany!.companyId}",
    );
    var response = await http.get(
      url,
      headers: {'Authorization': "bearer ${curentUser['token']}"},
    );
    return _holidayListFromResponse(response.body);
  }

  List<GetHolidayViews> _holidayListFromResponse(String responseBody) {
    final decodedBody = json.decode(responseBody);
    final dynamic holidayList = decodedBody is List
        ? decodedBody
        : decodedBody is Map
            ? decodedBody['Data'] ?? decodedBody['data'] ?? decodedBody['HolidayList'] ?? decodedBody['holidayList'] ?? []
            : [];

    if (holidayList is! List) return [];

    return List<GetHolidayViews>.from(
      holidayList.map((holiday) => GetHolidayViews.fromJson(Map<String, dynamic>.from(holiday))),
    );
  }

  //==================== Get Holiday List =======================\\

  //==================== Delete Holiday List =======================\\

  Future deleteHoliday(holidayid) async {
    var url = Uri.parse("${apibaseurl}api/HRM/DeleteHoliday?HolidayId=$holidayid");
    var response = await http.get(url, headers: {
      'Authorization':"bearer ${curentUser['token']}"
    });
    return getCompanyListModelFromJson(response.body);
  }

  //==================== Delete Holiday List =======================\\

  //==================== create and edit Holiday List =======================\\

  Future newHolidayCreate({holidaynames,holidayDates,setDecription,setCguid, bool? insertmood, holidayType,masterCguid})async{
    var bodys = {
      "Flag": "A",
      "Holiday": {
        "HolidayName": holidaynames,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "HolidayDate": holidayDates,
        "Description": setDecription,
        "HolidayType": holidayType,
        "Cguid": setCguid
      }
    };

    var updateBody = {
      "Flag": "U",
      "Holiday": {
        "HolidayName": holidaynames,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "HolidayDate": holidayDates,
        "Description": setDecription,
        "HolidayType": holidayType,
        "Cguid": setCguid,
        "MasterCguid": masterCguid
      }
    };

    var url = Uri.parse('${apibaseurl}api/HRM/CreateHoliday');

    var response = await http.post(url, body: jsonEncode(insertmood == true?  bodys :updateBody), headers: {'Authorization': 'bearer ${curentUser['token']}','Content-Type': 'application/json',});
    
    return newHolidayCreateFromJson(response.body);
  }

  //==================== create and edit Holiday List =======================\\

  //-------------------------------- Get Holiday By Id  --------------------------------\\\

  Future getHolidayById(cguId)async{
    var url = Uri.parse("$apibaseurl/api/HRM/GetHolidayListById?MasterCguid=$cguId");
    var response = await http.get(url, headers: {'Authorization': "bearer ${curentUser['token']}"});
    
    return holidayByIdFromJson(response.body);
  }

  //-------------------------------- Get Holiday By Id  --------------------------------\\

}
