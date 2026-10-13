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
import 'package:tax_hrm/services/analytics_service.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';
import 'package:tax_hrm/services/notifications/notification_storage_service.dart';

import '../models/company/getallcompany.dart';

class SplashProvider extends ChangeNotifier {
  bool isVideoFinished = false;
  Widget? pendingNavigationPage;

  void triggerNextScreen(BuildContext context, Widget defaultPage) {
    if (isVideoFinished) {
      nextScreen(context, pendingNavigationPage ?? defaultPage, onthenValue: (value) {});
      pendingNavigationPage = null;
    } else {
      pendingNavigationPage ??= defaultPage;
    }
  }

  void onVideoFinished(BuildContext context) {
    isVideoFinished = true;
    if (pendingNavigationPage != null) {
      nextScreen(context, pendingNavigationPage!, onthenValue: (value) {});
      pendingNavigationPage = null;
    }
  }

  loadingData(context) async {
    try {
      // Await so that switchValue is populated BEFORE getAllData() reads it.
      await SaveUser().loadAdminSwitch();
      getAllData(context);
    } catch (e) {
      /* ignored */
    }
  }

  /// Re-applies the persisted admin-switch override onto curentUser.
  /// Call this after every time curentUser is loaded or refreshed from the
  /// server so that a role toggled in Settings survives hot/cold restarts.
  Future<void> _applyAdminSwitchOverride() async {
    if (curentUser == null) return;
    // Reload from prefs to be safe (in case switchValue hasn't been set yet).
    await SaveUser().loadAdminSwitch();
    if (switchValue) {
      // Preserve the original server role so the toggle can be reversed later.
      curentUser['OriginalRole'] ??= curentUser['Role'];
      curentUser['Role'] = 'Admin';
      // Persist the patched user data so the next cold start also sees 'Admin'.
      await SaveUser().saveUserData(jsonEncode(curentUser));
    }
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
          await Provider.of<AttendanceEmp>(
            context,
            listen: false,
          ).fetchAndStoreBeginTime(context, positionName);

          final prefs = await SharedPreferences.getInstance();
          final userId = curentUser?['Id'];
          String? beginTimeStr = prefs.getString(
            'user_begin_time_${userId}_$positionName',
          );
          if (beginTimeStr != null && beginTimeStr.isNotEmpty) {
            success = true;
            break;
          }
        }
        await Future.delayed(const Duration(seconds: 3));
        retries++;
      }

      if (curentUser != null && selectedcurentcompany != null) {
        await NotificationStorageService.storeUserInfo(
          userId: curentUser['Id'] ?? 0,
          companyId: selectedcurentcompany!.companyId ?? 0,
          role: curentUser['Role']?.toString() ?? 'Employee',
          employeeName:
              '${curentUser['FirstName'] ?? ''} ${curentUser['LastName'] ?? ''}'
                  .trim(),
        );
        await FcmTokenService.instance.subscribeLoginTopics();
      }
      await ReminderNotificationService.scheduleAllNotifications();
    } catch (e) {
      /* ignored */
    }
  }

  void _setupNotificationsAfterSplash() {
    try {
      if (curentUser != null && selectedcurentcompany != null) {
        NotificationStorageService.storeUserInfo(
          userId: curentUser['Id'] ?? 0,
          companyId: selectedcurentcompany!.companyId ?? 0,
          role: curentUser['Role']?.toString() ?? 'Employee',
          employeeName:
              '${curentUser['FirstName'] ?? ''} ${curentUser['LastName'] ?? ''}'
                  .trim(),
        );
        FcmTokenService.instance.subscribeLoginTopics();
      }
      ReminderNotificationService.scheduleAllNotifications();
    } catch (e) {
      /* ignored */
    }
  }

  getAllData(context) {
    SaveUser().getUserDatas().then((value) async {
      if (value != '') {
        curentUser = jsonDecode(value);

        // ── Restore Admin-mode override BEFORE any role-based logic ──
        // This ensures that if the user had toggled Admin mode in Settings,
        // the role is correctly re-applied after a hot/cold restart.
        await _applyAdminSwitchOverride();

        // ── Analytics: identify user right after loading from storage ──
        _identifyUser();
        FcmTokenService.instance.initialize();

        _updateAllDataForReminders(context);

        // 1. Instantly load local cache into memory (Level 1 + 2)
        String savedCompany = await SaveUser().getselectedcompany();
        if (savedCompany.isNotEmpty) {
          try {
            Map<String, dynamic> jsonMap = jsonDecode(savedCompany);
            selectedcurentcompany = GetCompanyData.fromJson(jsonMap);
          } catch (e) {
            // ignore JSON errors
          }
        }

        // 2. Start silent background API refresh (Level 3)
        // Use OriginalRole (the server role) for the login call so we always
        // authenticate with the real credentials, not the locally-overridden role.
        final String serverRole =
            curentUser['OriginalRole']?.toString() ?? curentUser['Role']?.toString() ?? '';
        CompanyDataApis().getCompanyDataList().then((value) async {
          if (value == 401) {
            if (serverRole == 'Admin') {
              adminLogin(context, false);
            } else {
              empLogin(context, false);
            }
          } else {
            getAllCompany = value;
            await Provider.of<HomeProvider>(context, listen: false).setcompanyselected();
            // Silently refresh the user data in the background
            if (serverRole == 'Admin') {
              adminLogin(context, true);
            } else {
              empLogin(context, true);
            }
          }
        });

        // 3. Immediately go to the Dashboard without waiting for the API
        if (curentUser['Role'] == 'Admin') {
          Provider.of<HomeProvider>(
            context,
            listen: false,
          ).changeSelectBottomBar(0);
          _setupNotificationsAfterSplash();
          triggerNextScreen(context, AnimatedBottomBar());
        } else if (curentUser['Role'] == 'Sub-Admin') {
          // Sub-Admin whose admin switch is OFF navigates as employee.
          if (switchValue) {
            Provider.of<HomeProvider>(
              context,
              listen: false,
            ).changeSelectBottomBar(0);
          } else {
            Provider.of<HomeProvider>(
              context,
              listen: false,
            ).selectFloadButton();
          }
          _setupNotificationsAfterSplash();
          triggerNextScreen(context, AnimatedBottomBar());
        } else {
          Provider.of<HomeProvider>(
            context,
            listen: false,
          ).selectFloadButton();
          _setupNotificationsAfterSplash();
          triggerNextScreen(context, AnimatedBottomBar());
        }
      } else {
        await FcmTokenService.instance.handleLogout();
        triggerNextScreen(context, LoginScreen());
      }
    });
  }

  adminLogin(context, [bool silentRefresh = false]) async {
    await AuthLoginService()
        .calllogin(curentUser['Username'], curentUser['Password'])
        .then((value) async {
          UserLogin loginReponse = value as UserLogin;
          if (loginReponse.id == 0 && loginReponse.role == null) {
            if (!silentRefresh) {
              await FcmTokenService.instance.handleLogout();
              SaveUser().saveUserData('');
              SaveUser().saveselectedcopany('');
              triggerNextScreen(context, LoginScreen());
            }
          } else {
            if (loginReponse.hRM != null) {
              String udata = jsonEncode(value);
              SaveUser().saveUserData(udata);
              if (!silentRefresh) {
                FcmTokenService.instance.handleTokenSync();
                _setupNotificationsAfterSplash();
                triggerNextScreen(context, AnimatedBottomBar());
              } else {
                curentUser = jsonDecode(udata);
                // Re-apply admin switch override after silent refresh so that
                // a toggled role is not overwritten by the fresh server data.
                await _applyAdminSwitchOverride();
                // ── Analytics: re-identify after silent refresh ──
                _identifyUser();
              }
            }
          }
        });
  }

  Future empLogin(context, [bool silentRefresh = false]) async {
    await AuthLoginService()
        .callEmployeLogin(curentUser['UserName'], curentUser['Password'])
        .then((value) async {
          EmpUserLogin loginReponse = value as EmpUserLogin;
          if (loginReponse.success == false || loginReponse.hRM == false) {
            if (!silentRefresh) {
              await FcmTokenService.instance.handleLogout();
              SaveUser().saveUserData('');
              SaveUser().saveselectedcopany('');
              triggerNextScreen(context, LoginScreen());
            }
          } else {
            if (loginReponse.hRM == true) {
              String udata = jsonEncode(loginReponse);
              await SaveUser().saveUserData(udata);
              if (!silentRefresh) {
                await SaveUser().getUserDatas().then((value) async {
                  if (value != '') {
                    curentUser = jsonDecode(value);
                    // ── Analytics: identify after emp login ──
                    _identifyUser();
                    FcmTokenService.instance.handleTokenSync();
                  }
                });
                _setupNotificationsAfterSplash();
                triggerNextScreen(context, AnimatedBottomBar());
              } else {
                curentUser = jsonDecode(udata);
                // Re-apply admin switch override after silent refresh so that
                // a toggled role is not overwritten by the fresh server data.
                await _applyAdminSwitchOverride();
              }
            }
          }
        });
  }

  /// Reads curentUser global and sends structured data to AnalyticsService.
  void _identifyUser() {
    try {
      if (curentUser == null) return;
      final userId = curentUser['Id']?.toString() ?? '';
      if (userId.isEmpty) return;

      final firstName = curentUser['FirstName']?.toString() ?? '';
      final lastName  = curentUser['LastName']?.toString() ?? '';
      final fullName  = '$firstName $lastName'.trim();

      AnalyticsService.to.setUserId(
        userId,
        userName:    curentUser['UserName']?.toString() ?? curentUser['Username']?.toString(),
        fullName:    fullName.isEmpty ? null : fullName,
        role:        curentUser['Role']?.toString(),
        companyId:   (selectedcurentcompany?.companyId ?? curentUser['CompanyId'])?.toString(),
        companyName: selectedcurentcompany?.companyName?.toString(),
        email:       curentUser['Email']?.toString(),
        phone:       curentUser['MobileNo']?.toString() ?? curentUser['Mobile']?.toString(),
      );
    } catch (_) {}
  }
}
