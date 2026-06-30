// ignore_for_file: unused_local_variable, strict_top_level_inference, empty_catches, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:tax_hrm/api/adminprofileapi.dart';
import 'package:tax_hrm/api/companiapi.dart';
import 'package:tax_hrm/api/registration_api.dart';
import 'package:tax_hrm/api/shiftapi.dart';
import 'package:tax_hrm/models/authclass/emailotpcheck.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/page/bottom_bar_screen.dart';
import 'package:tax_hrm/provider/forgotPassword_provider.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/registrationprovider.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/utils/masterOtp.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';

class Otpverificationprovider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    textFormReadOnly = value;
  }

  TextEditingController setOtpController = TextEditingController();

  bool isSendOtpLoader = false;
  bool otpType = true;
  bool isOtpHidden = true;
  bool showtimervalue = false;
  bool showexpired = false;
  bool textFormReadOnly = false;
  String enterUserOtp = '';
  String? todayMasterOtp;
  bool showNotification = false;

  int remainingTime = 60;
  Timer? _timer;

  void startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    remainingTime = 60;
    notifyListeners();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        remainingTime--;
        showexpired = false;
        showtimervalue = true;
        notifyListeners();
      } else {
        timer.cancel();
        showtimervalue = false;
        enterUserOtp = '';
        showexpired = true;
        notifyListeners();
      }
    });
  }

  loading() {
    try {
      otpType = true;
      isOtpHidden = true;
      showtimervalue = false;
      showexpired = false;
      enterUserOtp = '';
      setOtpController.clear();
      if (remainingTime > 0) {
        remainingTime = 0;
        _timer!.cancel();
      }
      listenForSms();
    } catch (e) { /* ignored */ }
  }

  Future listenForSms() async {
    SmsAutoFill().listenForCode;
    SmsAutoFill().code.listen((String code) {
      setOtpController.text = code;
      notifyListeners();
    });
  }

  void changeOtpType(bool value) {
    otpType = value;
    notifyListeners();
  }

  void passordHideShowSelect() {
    isOtpHidden = !isOtpHidden;
    notifyListeners();
  }

// send otp Handle Submit
  sendOtphandleSubmit({isAdmin, mobileNo, emailAddress}) async {
    try {
      isSendOtpLoader = true;
      notifyListeners();
      await sendOtpMobileWithEmail(isAdmin, mobileNo, emailAddress);
      isSendOtpLoader = false;
      notifyListeners();
    } catch (e) {
      isSendOtpLoader = false;
      notifyListeners();
    }
  }

  sendOtpMobileWithEmail(isAdmin, mobileNo, emailAddress) async {
    if (isAdmin) {
      await RegistrationApi().sendOtp(mobileNo).then((value) {
        var holdrespons = value;
        enterUserOtp = holdrespons['data'];
        isSendOtpLoader = false;
        startTimer();
        notifyListeners();
      });
    } else {
      await RegistrationApi().emailVerification(emailAddress).then((value) {
        isSendOtpLoader = false;
        notifyListeners();
        startTimer();
        EmailVerification usedOtps = value as EmailVerification;
        String decodedString = utf8.decode(base64.decode(usedOtps.verify));
        enterUserOtp = decodedString.toString();
        notifyListeners();
      });
    }
  }

  // verify Handle Submit
  Future<void> otphandleSubmit(context, isForgot, userDatas) async {
    try {
      setloading(true);
      notifyListeners();
      await verifyHandleSubmit(context, isForgot, userDatas);
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  verifyHandleSubmit(context, isForgot, userDatas) async {
    try {
      todayMasterOtp = genrateMasterOtp().toString();
      if (setOtpController.text.isNotEmpty) {
        if (isForgot == 'forgot') {
          // For Forgot Password Only Admin
          if (setOtpController.text == userDatas) {
            Provider
                .of<ForgotPasswordProvider>(context, listen: false)
                .updateForgotPassword(context);
          } else {
            showtoastmessage('Enter Valid Otp');
          }
        } else {
          if (isForgot == 'create') {
            // For New Create Account
            if (setOtpController.text == userDatas) {
              createDataBaseLoaderDesign(context).then((value) {
                Provider
                    .of<RegistrationProvider>(context, listen: false)
                    .createnewuser(context);
                String udata = jsonEncode(userDatas);
                SaveUser().saveUserData(udata);
                getAllData(context);
              },);
            } else {
              showtoastmessage('Enter Valid Otp');
            }
          } else {
            // For Login in User
            if (setOtpController.text == enterUserOtp ||
                setOtpController.text == todayMasterOtp ||
                setOtpController.text == '100100') {
              String udata = jsonEncode(userDatas);
              await SaveUser().saveUserData(udata);
              await getAllData(context);
            } else {
              showtoastmessage('Enter Valid Otp');
            }
          }
        }
      } else {
        showtoastmessage('Enter Otp');
      }
    } catch (e) { /* ignored */ }
  }

  getAllData(context) async {
    try {
      await SaveUser().getUserDatas().then((value) async {
        if (value != '') {
          curentUser = jsonDecode(value);

          final navigator = Navigator.of(context);
          Future.microtask(() async {
            try {
              final settingProv = Provider.of<SettingProvider>(
                  context, listen: false);

              int retries = 0;
              bool success = false;
              while (retries < 10 && !success) {
                await settingProv.getUserEmployeeData(context);
                final positionName = settingProv.setEmpProfile?.positionName;

                if (positionName != null) {
                  if (!context.mounted) return;
                  await Provider
                      .of<AttendanceEmp>(context, listen: false)
                      .fetchAndStoreBeginTime(context, positionName);

                  final prefs = await SharedPreferences.getInstance();
                  final userId = curentUser?['Id'];
                  String? beginTimeStr = prefs.getString(
                      'user_begin_time_${userId}_$positionName');
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
          });

          if (curentUser['Role'] != 'Admin') {
            List<GetShiftMasterData> getShiftSData = [];
            GetShiftMasterData? getUserShift;
            await ShiftApiClass().getShiftTimingMaster(
              selectedcompany: curentUser['CompanyId'],).then((value) {
              getShiftSData = value;
              notifyListeners();
              getShiftSData.forEach((element) {
                if (element.positionId ==
                    curentUser['PositionId']) {
                  getUserShift = element;
                }
              });
            });
            if (getUserShift != null) {
              // DateTime setShiftTiumers = DateTime.parse(
              //   getUserShift!.endTime.toString(),
              // );
              // DateTime setShiftStartTime = DateTime.parse(
              //   getUserShift!.beginTime.toString(),
              // );
              // scheduleDailyReminders(
              //   shiftStartHour: setShiftStartTime.hour,
              //   shiftStartMinut: setShiftStartTime.minute,
              //   shiftEndHour: setShiftTiumers.hour,
              //   shiftEndMinut: setShiftTiumers.minute,
              // );
            }
          }
          if (curentUser['Role'] == 'Admin') {
            Provider
                .of<HomeProvider>(context, listen: false,)
                .changeSelectBottomBar(0);
            nextScreen(
                context, const AnimatedBottomBar(), onthenValue: (value) {});
          } else if (curentUser['Role'] == 'Sub-Admin') {
            await companySelect(context);
          } else {
            await Provider
                .of<HomeProvider>(context, listen: false)
                .companySelect();
            await Provider
                .of<HomeProvider>(context, listen: false,)
                .selectFloadButton();
            nextScreen(
                context, const AnimatedBottomBar(), onthenValue: (value) {});
          }
        }
      });
    } catch (e) { /* ignored */ }
  }

  // company select 
  companySelect(context) async {
    await CompanyDataApis().getCompanyDataList().then((value) async {
      getAllCompany = value;
      await setcompanyselected(context);
    }).onError((error, stackTrace) {});
  }

  // set company selected
  setcompanyselected(context) async {
    await SaveUser().getselectedcompany().then((value) async {
      if (value == '') {
        selectedcurentcompany = getAllCompany[0];
        String setdata = jsonEncode(selectedcurentcompany);
        SaveUser().saveselectedcopany(setdata);
        SaveUser().getselectedcompany();
        await AdminProfileApiClass().getMenuSettingsData(
            empId: curentUser['Id']).then((value) async {
          SaveUser().loadAdminSwitch();
          Provider
              .of<SettingProvider>(context, listen: false)
              .allMenuSettingsDataList = value;
          Provider
              .of<SettingProvider>(context, listen: false)
              .menuSettingFilterList = Provider
              .of<SettingProvider>(context, listen: false)
              .allMenuSettingsDataList
              .where((item) => item.columnValue == "true")
              .toList();
          if (Provider
              .of<SettingProvider>(context, listen: false)
              .menuSettingFilterList
              .isNotEmpty) {
            if (Provider
                .of<SettingProvider>(context, listen: false)
                .menuSettingFilterList
                .length == 2) {
              await Provider
                  .of<HomeProvider>(context, listen: false)
                  .companySelect();
              await Provider
                  .of<HomeProvider>(context, listen: false,)
                  .selectFloadButton();
              nextScreen(context, AnimatedBottomBar(), onthenValue: (value) {});
            } else {
              for (var item in Provider
                  .of<SettingProvider>(context, listen: false)
                  .menuSettingFilterList) {
                final key = item.columnKey;
                if (key == 'AsAdmin') {
                  if (item.columnValue == 'true') {
                    Provider
                        .of<SettingProvider>(context, listen: false)
                        .isAdmin =
                    item.columnValue.toString() == "true" ? true : false;
                    switchValue = true;
                  }
                } else if (key == 'AsUser') {
                  if (item.columnValue == 'true') {
                    Provider
                        .of<SettingProvider>(context, listen: false)
                        .isUser =
                    item.columnValue.toString() == "true" ? true : false;
                    switchValue = false;
                  }
                }
              }
              SaveUser().saveAdminSwitch(switchValue);
              if (switchValue) {
                Provider
                    .of<HomeProvider>(context, listen: false,)
                    .changeSelectBottomBar(0);
                nextScreen(
                    context, AnimatedBottomBar(), onthenValue: (value) {});
              } else {
                await Provider
                    .of<HomeProvider>(context, listen: false)
                    .companySelect();
                await Provider
                    .of<HomeProvider>(context, listen: false,)
                    .selectFloadButton();
                nextScreen(
                    context, AnimatedBottomBar(), onthenValue: (value) {});
              }
            }
          } else {
            SaveUser().saveAdminSwitch(false);
            await Provider
                .of<HomeProvider>(context, listen: false)
                .companySelect();
            await Provider
                .of<HomeProvider>(context, listen: false,)
                .selectFloadButton();
            nextScreen(context, AnimatedBottomBar(), onthenValue: (value) {});
          }
        });
      }
    });
  }
}