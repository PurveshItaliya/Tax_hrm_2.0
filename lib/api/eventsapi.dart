
// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/eventclass/getevents.dart';
import 'package:tax_hrm/models/eventclass/newevents.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/notes/newnotes.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class  EventsApiClass {

  // data get api

  Future getEventsData()async{
    var uri =Uri.parse('${apibaseurl}api/HRM/Eventlist?CompanyID=${selectedcurentcompany!.companyId}');
    var response  = await http.get(uri,headers: {
    'Authorization': "bearer ${curentUser['token']}"
    });
    return getEventsFromJson(response.body);
  }
  
  // add and edit api 

  Future createEvent({setEventname,setStartDat,setEndDate,eventPlaces,setDescription,setCguid,setEventIds,bool? checkInsert})async{
    var setbody = {
      "Flag": "A",
      "Event": {
        "EventName": setEventname,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "StartDate": setStartDat,
        "EndDate": setEndDate,
        "EventPlace": eventPlaces,
        "Description": setDescription,
        "Cguid": setCguid
      }
    };

    var updateBody = {
      "Flag": "U",
      "Event": {
        "EventId": setEventIds,
        "EventName": setEventname,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "StartDate": setStartDat,
        "EndDate": setEndDate,
        "EventPlace": eventPlaces,
        "Description": setDescription,
        "Cguid": setCguid
      }
    };

    var uri = Uri.parse('${apibaseurl}api/HRM/CreateEvent');
    var responses =await http.post(uri,body: jsonEncode(checkInsert == true ?  setbody :updateBody),headers: {'Authorization':"bearer ${curentUser['token']}",'Content-Type': 'application/json',});
    return newEventsFromJson(responses.body);  
  }

  // delete ervents

  Future deleteEvents({setEventid})async{
    var uri =Uri.parse('${apibaseurl}api/HRM/DeleteEvent?EventId=$setEventid');
    var response  = await http.get(uri,headers: {
    'Authorization':"bearer ${curentUser['token']}"
    });
    return notesClassFromJson(response.body);
  }

}