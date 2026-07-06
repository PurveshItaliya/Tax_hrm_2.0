// ignore_for_file: use_build_context_synchronously, strict_top_level_inference, empty_catches, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/api/authapi.dart';
import 'package:tax_hrm/api/companiapi.dart';
import 'package:tax_hrm/models/authclass/adminloginclass.dart';
import 'package:tax_hrm/models/authclass/emploginclass.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/authpages/loginpage.dart';
import 'package:tax_hrm/page/bottom_bar_screen.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';

class SplashProvider extends ChangeNotifier {
  bool isVideoFinished = false;
  Widget? pendingNavigationPage;

  void triggerNextScreen(BuildContext context, Widget page) {
    if (isVideoFinished) {
      nextScreen(context, page, onthenValue: (value) {});
    } else {
      pendingNavigationPage = page;
    }
  }

  void onVideoFinished(BuildContext context) {
    isVideoFinished = true;
    if (pendingNavigationPage != null) {
      nextScreen(context, pendingNavigationPage!, onthenValue: (value) {});
      pendingNavigationPage = null;
    }
  }
  
  loadingData(context) {
    try {
      SaveUser().loadAdminSwitch();
      getAllData(context);
    } catch (e) { /* ignored */ }
  }

  // A function to request general permissions (one at a time).
  // NOTE: Notification permission is intentionally NOT requested here.
  // It is requested on the Punch Screen with a custom explanation dialog.
  Future<void> requestAllPermissions() async {
    // Exact Alarm (Android 12+)
    await checkExactAlarmPermission();
  }

  /// Request exact alarm permission (only if not granted)
  Future<void> checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      bool isAndroid12 = await isAndroid12OrAbove();
      if (isAndroid12) {
        bool granted = await hasExactAlarmPermission();
        if (!granted) {
          try {
            await Permission.scheduleExactAlarm.request();
          } catch (e) {
            // ignore
          }
        }
      }
    }
  }

  Future<bool> isAndroid12OrAbove() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    // Android 12 has an SDK version of 31.
    return androidInfo.version.sdkInt >= 31;
  }

  /// Check if exact alarm permission is already granted
  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    var status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  Future<void> _updateAllDataForReminders(BuildContext context) async {
    try {
      final settingProv = Provider.of<SettingProvider>(context, listen: false);
      int retries = 0;
      bool success = false;
      while (retries < 10 && !success) {
        await settingProv.getUserEmployeeData(context);
        final positionName = settingProv.setEmpProfile?.positionName;
        
        if (positionName != null) {
          if (!context.mounted) return;
          await Provider.of<AttendanceEmp>(context, listen: false).fetchAndStoreBeginTime(context, positionName);
          
          final prefs = await SharedPreferences.getInstance();
          final userId = curentUser?['Id'];
          String? beginTimeStr = prefs.getString('user_begin_time_${userId}_$positionName');
          if (beginTimeStr != null && beginTimeStr.isNotEmpty) {
            success = true;
            break;
          }
        }
        await Future.delayed(const Duration(seconds: 3));
        retries++;
      }

      await ReminderNotificationService.updateHolidaysAndLeaves();
      await ReminderNotificationService.scheduleReminders();
    } catch (e) { /* ignored */ }
  }

  getAllData(context) {
    SaveUser().getUserDatas().then((value)async {
      if(value != '') {
        curentUser = jsonDecode(value);
        FcmTokenService.instance.initialize();
        
        _updateAllDataForReminders(context);
        
        await  CompanyDataApis().getCompanyDataList().then((value)async{
          if(value == 401){
            if(curentUser['Role'] =='Admin'){
              adminLogin(context);
            }else{
              empLogin(context);
            }
          } else{
            if(curentUser['Role'] =='Admin'){
              Provider.of<HomeProvider>(context,listen: false,).changeSelectBottomBar(0);
              triggerNextScreen(context, AnimatedBottomBar());
            } else if(curentUser['Role'] =='Sub-Admin') {
              SaveUser().loadAdminSwitch().then((value) async {
                if(switchValue) {
                  Provider.of<HomeProvider>(context,listen: false,).changeSelectBottomBar(0);
                  triggerNextScreen(context, AnimatedBottomBar());
                } else{
                  await Provider.of<HomeProvider>(context, listen: false).companySelect();
                  Provider.of<HomeProvider>(context,listen: false,).selectFloadButton();
                  triggerNextScreen(context, AnimatedBottomBar());
                }
              },);
            } else{
              await Provider.of<HomeProvider>(context, listen: false).companySelect();
              Provider.of<HomeProvider>(context,listen: false,).selectFloadButton();
              triggerNextScreen(context, AnimatedBottomBar());
            }
          }
        });
      } else{
        triggerNextScreen(context, LoginScreen());
      }
    });
  }

  adminLogin(context)async{
    await AuthLoginService().calllogin(curentUser['Username'],curentUser['Password']).then((value) async{
      UserLogin loginReponse =value as UserLogin;
      if(loginReponse.id == 0 && loginReponse.role == null){
        SaveUser().saveUserData('');
        SaveUser().saveselectedcopany('');
        triggerNextScreen(context, LoginScreen());
      } else {
        if(loginReponse.hRM  != null){
          var  holdData =   value;
          String udata = jsonEncode(value);
          SaveUser().saveUserData(udata);
          FcmTokenService.instance.handleTokenSync();
          triggerNextScreen(context, AnimatedBottomBar());
        }
      }
    });
  }

  Future empLogin(context)async{
    await AuthLoginService().callEmployeLogin(curentUser['UserName'],curentUser['Password']).then((value) async{
      EmpUserLogin loginReponse =value as EmpUserLogin;
      if(loginReponse.success == false || loginReponse.hRM  == false){
        SaveUser().saveUserData('');
        SaveUser().saveselectedcopany('');
        triggerNextScreen(context, LoginScreen());
      } else {
        if(loginReponse.hRM  == true){
          String udata = jsonEncode(loginReponse);
          await SaveUser().saveUserData(udata);
          await SaveUser().getUserDatas().then((value)async {
            if (value != '') {
               curentUser = jsonDecode(value);
               FcmTokenService.instance.handleTokenSync();
            }
          });
          triggerNextScreen(context, AnimatedBottomBar());
        }
      }
    });
  }
}
