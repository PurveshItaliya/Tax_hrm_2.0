// ignore_for_file: strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/eventclass/getevents.dart';
import 'package:tax_hrm/models/eventclass/newevents.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/notes/newnotes.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class EventsApiClass {
  // data get api

  Future getEventsData() async {
    var uri = Uri.parse(
      '${apibaseurl}api/HRM/Eventlist?CompanyID=${selectedcurentcompany!.companyId}',
    );
    var response = await http.get(
      uri,
      headers: {'Authorization': "bearer ${curentUser['token']}"},
    );
    return getEventsFromJson(response.body);
  }

  // add and edit api

  Future createEvent({
    setEventname,
    setStartDat,
    setEndDate,
    eventPlaces,
    setDescription,
    setCguid,
    setEventIds,
    bool? checkInsert,
  }) async {
    var setbody = {
      "Flag": "A",
      "Event": {
        "EventName": setEventname,
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "StartDate": setStartDat,
        "EndDate": setEndDate,
        "EventPlace": eventPlaces,
        "Description": setDescription,
        "Cguid": setCguid,
      },
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
        "Cguid": setCguid,
      },
    };

    var uri = Uri.parse('${apibaseurl}api/HRM/CreateEvent');
    var responses = await http.post(
      uri,
      body: jsonEncode(checkInsert == true ? setbody : updateBody),
      headers: {
        'Authorization': "bearer ${curentUser['token']}",
        'Content-Type': 'application/json',
      },
    );
    return newEventsFromJson(responses.body);
  }

  // delete ervents

  Future deleteEvents({setEventid}) async {
    var uri = Uri.parse('${apibaseurl}api/HRM/DeleteEvent?EventId=$setEventid');
    var response = await http.get(
      uri,
      headers: {'Authorization': "bearer ${curentUser['token']}"},
    );
    return notesClassFromJson(response.body);
  }

  // Push Notification API
  Future sendPushNotification({
    required String title,
    required String description,
    File? imageFile,
    String? topicOverride,
    String? custIdOverride,
    String? topicTitleOverride,
  }) async {
    try {
      var url = Uri.parse(
        'https://webcrmnode.taxfile.co.in/pushnotification/integration',
      );
      var req = http.MultipartRequest("POST", url);

      String custIdBase = curentUser is Map
          ? curentUser['CustId']?.toString() ??
                curentUser['custid']?.toString() ??
                ''
          : '';
      String companyId = selectedcurentcompany?.companyId?.toString() ?? '';
      String combinedId = 'COMPANY_${custIdBase}_$companyId';

      req.fields['ProjectUkId'] = '6A4FB70F-263F-4644-AFE2-A0E3A9293B7E';
      req.fields['Topic_Title'] = topicTitleOverride ?? selectedcurentcompany?.companyName ?? '';
      req.fields['Topic'] = topicOverride ?? combinedId;
      req.fields['CompanyName'] = selectedcurentcompany?.companyName ?? '';
      req.fields['CustId'] = custIdOverride ?? combinedId;
      req.fields['PushNotificationTitle'] = title;
      req.fields['PushNotificationDescription'] = description;
      req.fields['LinkUkId'] = '1CB62024-EC83-497F-A7E6-CD9D1874D6C1';
      req.fields['SendTime'] = DateTime.now().toIso8601String().substring(
        0,
        19,
      );

      if (imageFile != null) {
        var pic = await http.MultipartFile.fromPath(
          'PushNotificationImage',
          imageFile.path,
        );
        req.files.add(pic);
      }

      var response = await req.send();
      final responseBody = await response.stream.bytesToString();

      log('PushNotification Request URL: ${req.url}');
      log('PushNotification Request Headers: ${req.headers}');
      log('PushNotification Request Fields: ${req.fields}');
      log('PushNotification Request Files: ${req.files.map((e) => e.filename).toList()}');

      log('PushNotification Response Status Code: ${response.statusCode}');
      log('PushNotification Response Headers: ${response.headers}');
      log('PushNotification Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(responseBody);
          log('PushNotification JSON Response: $jsonResponse');
        } catch (_) {
          // Ignore
        }
      }

      return response.statusCode;
    } catch (e) {
      log('PushNotification Error: $e');
      return null;
    }
  }
}
