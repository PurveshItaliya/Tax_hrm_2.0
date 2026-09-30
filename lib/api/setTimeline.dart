// ignore_for_file: strict_top_level_inference, unused_local_variable


import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/company/timelines.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class LocationTimeLineClass {

  //---------------------------  User TimeLine ----------------------\\


  //------------------------- User TimeLine Data ------------------------\\

  Future getUserTimeLine({setUserId, selectedDate}) async {
    String url = '$apibaseurl/api/Transation/GetTimelineList?CompanyID=${selectedcurentcompany!.companyId}&EmpId=$setUserId&Date=$selectedDate';
    
    var response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'bearer  ${curentUser['token']}'},
    );
    
    
    return locationTimelInesFromJson(response.body);
  }

  //-----------------------------------------------------------------------\\

}
