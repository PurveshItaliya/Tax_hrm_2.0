// ignore_for_file: use_build_context_synchronously, strict_top_level_inference, avoid_function_literals_in_foreach_calls, empty_catches, body_might_complete_normally_catch_error, library_prefixes, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' as dateTimers;
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/setTimeline.dart';
import 'package:tax_hrm/api/visit_api.dart';
import 'package:tax_hrm/models/company/timelines.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';

class TimeLineServices with ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  DateTime setDates = DateTime.now();
  double thresholdInMeters = 50; // 100 meters
  List<LocationTimelInes>  showUserTimeLines = [];
  List<LocationTimelInes>  mainUserTimeLines = [];
  List<dynamic> showVisits = [];

  // *************************************************  get timeLine View ******************************************************************
  
  timeViewLoadData({setEmpId}) async {
    developer.log('timeViewLoadData: Started for EmpId: $setEmpId', name: 'TimeLineProvider');
    try {
      showUserTimeLines.clear();
      setloading(true);
      developer.log('timeViewLoadData: Calling gettimeLines', name: 'TimeLineProvider');
      await gettimeLines(setEmpId: setEmpId);
      developer.log('timeViewLoadData: gettimeLines completed', name: 'TimeLineProvider');
      setloading(false);
      
    } catch (e, stackTrace) {
      developer.log('timeViewLoadData: Error occurred - $e', name: 'TimeLineProvider', error: e, stackTrace: stackTrace);
      setloading(false);
    }
    notifyListeners();
  }

  gettimeLines({setEmpId}) async {
    try {
      String formattedDate = dateTimers.DateFormat('yyyy-MM-dd').format(setDates);
      
      // 1. Fetch Timeline Points
      Future<void> timelineFuture = LocationTimeLineClass().getUserTimeLine(selectedDate: formattedDate, setUserId: setEmpId).then((value) {
        mainUserTimeLines = value;
        int processedCount = 0;
        int addedCount = 0;
        mainUserTimeLines.forEach((element) {
          processedCount++;
          if (element.latitude != null && element.logitude != null && element.latitude != 'null' && element.logitude != 'null') {
            if (showUserTimeLines.isEmpty) {
              showUserTimeLines.add(element);
              addedCount++;
            } else {
              bool isInValidRange = isLocationInRange(
                previousLatitude: double.parse(showUserTimeLines.last.latitude!),
                previousLongitude: double.parse(showUserTimeLines.last.logitude!),
                currentLatitude: double.parse(element.latitude!),
                currentLongitude: double.parse(element.logitude!),
                thresholdInMeters: thresholdInMeters,
              );
              if (!isInValidRange) {
                showUserTimeLines.add(element);
                addedCount++;
              }
            }
          }
        });
      }).catchError((error) {
      });

      // 2. Fetch Visits
      Future<void> visitsFuture = () async {
        try {
          String companyId = selectedcurentcompany?.companyId.toString() ?? '';
          String empIdStr = setEmpId?.toString() ?? '0';
          
          var allVisits = await VisitApis().getVisitList(companyId, '', empIdStr);
          showVisits.clear();
          
          
          for (var visit in allVisits) {
            String assignTo = visit['VisitAssignTo']?.toString() ?? '';
            List<String> assignedIds = assignTo.split(',').map((e) => e.trim()).toList();
            String status = visit['VisitStatus']?.toString() ?? '';
            String visitTimeStr = visit['VisitTime']?.toString() ?? '';
            String entryTimeStr = visit['EntryTime']?.toString() ?? '';
            String normStatus = status.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
            
            bool isDateMatch = visitTimeStr.startsWith(formattedDate) || entryTimeStr.startsWith(formattedDate);
            bool isAssignMatch = assignedIds.contains(empIdStr.trim());
            bool isStatusMatch = !(normStatus == 'pending' || normStatus == '' || normStatus == '0');
            
            
            if (isDateMatch && isAssignMatch && isStatusMatch) {
              showVisits.add(visit);
            }
          }
        } catch (e) {
        }
      }();

      await Future.wait([timelineFuture, visitsFuture]);
      
    } catch (e) { 
    }
  }

  bool isLocationInRange({
    required double previousLatitude,
    required double previousLongitude,
    required double currentLatitude,
    required double currentLongitude,
    required double thresholdInMeters,
  }) {
    // Calculate the distance
    double distance = Geolocator.distanceBetween(
      previousLatitude,
      previousLongitude,
      currentLatitude,
      currentLongitude,
    );

    // Check if the distance is within the threshold
    return distance <= thresholdInMeters;
  }

  // *************************************************  get timeLine View ******************************************************************

  //**************************************************  get Location Time Lines *********************************************************************

  bool showLocationLoader = false;
  String? setlongitude;
  String? setlatitude;
  LocationPermission? permission;
  Position? currentPosition;
  String? currentLocation;
  String? postalCode;
  String deviceName = "Unknown Device";

  Future<void> getCurrentLocation({BuildContext? context}) async {
    try {
      showLocationLoader = true;
      currentPosition = await getPosition(context: context);

      setlongitude = currentPosition!.longitude.toString();
      setlatitude = currentPosition!.latitude.toString();

      await getAddressFromLatLng(currentPosition!.longitude, currentPosition!.latitude);

      showLocationLoader = false;
    } catch (e) {
      showLocationLoader = false;
    }
    notifyListeners();
  }

  Future<Position> getPosition({BuildContext? context}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null) {
        bool? openSettings = await showGpsDisabledDialog(context);
        if (openSettings == true) {
          return await getPosition(context: context);
        }
      } else {
        await Geolocator.openLocationSettings();
      }
      return Future.error(locationServicesAreDisabledString);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (permission == LocationPermission.denied) {
        return Future.error(locationPermissionsAreDeniedString);
      } else {
        notifyListeners();
      }
    }else{}
    return await Geolocator.getCurrentPosition();
  }

  Future<void> getAddressFromLatLng(double long, double lat) async {
    try {
      List<Placemark> placemark = await Geocoding().placemarkFromCoordinates(lat, long);
      Placemark place = placemark[0];
      postalCode = placemark[0].postalCode;
      currentLocation = '${place.subThoroughfare} ${place.thoroughfare}, '
          '${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea},'
          '${place.administrativeArea} ${place.postalCode}, ${place.country}';

     notifyListeners();
    } catch (e) { /* ignored */ }
  }

  Future<String> getDeviceName() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.name;
      }
    } catch (e) { /* ignored */ }
    return deviceName;
  }

  callAddTimeLines(context)async{
    showLocationLoader = true;
    notifyListeners();

    deviceName = await getDeviceName();
    await Provider.of<AttendanceEmp>(context, listen: false).checkLastPunch(curentUser['Id']).then((value) async {
      if(Provider.of<AttendanceEmp>(context, listen: false).checkStatus!.attendenceLog!.isNotEmpty){
        if(Provider.of<AttendanceEmp>(context, listen: false).checkStatus!.attendenceLog!.last.status == 'IN'){
          await LocationBatchStorage.appendLocation(
            latitude: double.parse(setlatitude!),
            longitude: double.parse(setlongitude!),
            entryTime: DateTime.now(),
          );
          
          final String userDataStr = await SaveUser().getUserDatas();
          if (userDataStr.isNotEmpty) {
            final dynamic userData = jsonDecode(userDataStr);
            await LocationBatchStorage.uploadPendingBatch(userData: userData, isMapScreen: false, isAppForeground: true);
          }
        } else {
        }
      } else {
      }
    },);

    showLocationLoader = false;
    notifyListeners();
    Navigator.pop(context);
  }
  
  //**************************************************  get Location Time Lines *********************************************************************

}

bool isLocationInRange({
  required double previousLatitude,
  required double previousLongitude,
  required double currentLatitude,
  required double currentLongitude,
  required double thresholdInMeters,
}) {
  // Calculate the distance
  double distance = Geolocator.distanceBetween(
    previousLatitude,
    previousLongitude,
    currentLatitude,
    currentLongitude,
  );

  // Check if the distance is within the threshold
  return distance <= thresholdInMeters;
}