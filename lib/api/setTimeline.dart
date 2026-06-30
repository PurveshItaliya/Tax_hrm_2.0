// ignore_for_file: strict_top_level_inference, unused_local_variable

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/company/timelines.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class LocationTimeLineClass {

  //---------------------------  User TimeLine ----------------------\\


  Future setUserTimeLine({latitude,logitude,pincode,deviceType,deviceName,addres})async{
    var  setbody = {
      "EmpId": curentUser['Id'],
      "CompanyId": selectedcurentcompany!.companyId,
      "Latitude": latitude,
      "Logitude":logitude,
      "Pincode":pincode,
      "DeviceType": deviceType,
      "DeviceName": deviceName,
      "Address":addres
    };
    var response = await http.post(Uri.parse('${apibaseurl}api/Transation/CreateTimeline'),body: jsonEncode(setbody),headers: {'Content-Type' : 'application/json', 'Accept' : '*/*','Authorization':'bearer ${curentUser['token']}'});}

  //------------------------- User TimeLine Data ------------------------\\

  Future getUserTimeLine({setUserId, selectedDate}) async {
    var response = await http.get(
      Uri.parse(
        '$apibaseurl/api/Transation/GetTimelineList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=$setUserId&Date=$selectedDate',
      ),
      headers: {'Authorization': 'bearer  ${curentUser['token']}'},
    );
    return locationTimelInesFromJson(response.body);
  }

  //-----------------------------------------------------------------------\\

}
