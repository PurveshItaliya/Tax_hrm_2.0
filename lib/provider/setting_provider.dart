// ignore_for_file: strict_top_level_inference, empty_catches

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tax_hrm/api/adminprofileapi.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/getMenuSettings_model.dart';
import 'package:tax_hrm/models/usermaster/userbyid.dart';
import 'package:tax_hrm/page/document/showdocument_screen.dart';
import 'package:tax_hrm/page/personal_info/profilepage.dart';
import 'package:tax_hrm/page/setting/contact_us_screen.dart';
import 'package:tax_hrm/page/whats_new/whats_new_screen.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';

class SettingProvider extends ChangeNotifier {
  bool islodering = false;

  setloading(bool value) {
    islodering = value;
  }
  // user profile data
  Employeelists? setEmpProfile;

  // admin profile data
  AdminProfiles? setAdminProfile;

  // setting menu list
  List<HomeGridClass> settingGridOptionList = [];

  // current user role Rights
  bool isAdmin = false;
  bool isUser = false;

  Employeelists? selectedEmployeeList;

  List<GetMenuSettingsModel> allMenuSettingsDataList = [];
  List<GetMenuSettingsModel> menuSettingFilterList = [];

  final settingFormKey = GlobalKey<FormState>();

  settingMenuGet(context,) {
    settingGridOptionList = curentUser['Role'] == 'Admin' ? [
      HomeGridClass(image: personalImgString, title: personalInfoString,onTap: () {
        nextScreen(context, ProfileViewPage(isEdit: true),onthenValue: (value) {
          safeAreaBgAndTextColor(context,safeAreaBgColor: ColorConst.themeColor,safeAreaBrightness: Brightness.light);
        },);
      }),
      HomeGridClass(image: settingsImgString, title: roleRightsString,onTap: () {
        selectedEmployeeList = null;
        isAdmin = false;
        isUser = false;
        showRoleRightsSelectDialog(context,size: MediaQuery.of(context).size);
      }),
      HomeGridClass(image: contactUsImgString, title: contactUsString,onTap: () {
        nextScreen(context, const ContactUsScreen(),onthenValue: (value) {
          safeAreaBgAndTextColor(context,safeAreaBgColor: ColorConst.themeColor,safeAreaBrightness: Brightness.light);
        },);
      }),
      HomeGridClass(image: whatsNewImgString, title: whatsNewString,onTap: () {
        nextScreen(context, WhatsNewPage(),onthenValue: (value) {
          safeAreaBgAndTextColor(context,safeAreaBgColor: ColorConst.themeColor,safeAreaBrightness: Brightness.light);
        },);
      }),
      HomeGridClass(image: shareImgString, title: shareString,onTap: () {
        Share.shareUri(Uri.parse(rateLinkUrl));
      }),
      HomeGridClass(image: rateImgString, title: rateString,),
    ] :[
      HomeGridClass(image: personalImgString, title: personalInfoString,onTap: () {
        nextScreen(context, ProfileViewPage(isEdit: true),onthenValue: (value) {
          safeAreaBgAndTextColor(context,safeAreaBgColor: ColorConst.themeColor,safeAreaBrightness: Brightness.light);
        },);
      }),
      HomeGridClass(image: documentImageString, title: documentString,onTap: () {
         nextScreen(context, ShowDocumentScreen(),onthenValue: (value){
          safeAreaBgAndTextColor(context,safeAreaBgColor: ColorConst.themeColor,safeAreaBrightness: Brightness.light);
        },);
      }),
      HomeGridClass(image: contactUsImgString, title: contactUsString,onTap: () {
        nextScreen(context, const ContactUsScreen(),onthenValue: (value) {
          safeAreaBgAndTextColor(context,safeAreaBgColor: ColorConst.themeColor,safeAreaBrightness: Brightness.light);
        },);
      }),
      HomeGridClass(image: whatsNewImgString, title: whatsNewString,onTap: () {
        nextScreen(context, WhatsNewPage(),onthenValue: (value) {
          safeAreaBgAndTextColor(context,safeAreaBgColor: ColorConst.themeColor,safeAreaBrightness: Brightness.light);
        },);
      }),
      HomeGridClass(image: shareImgString, title: shareString,onTap: () {
        Share.shareUri(Uri.parse(rateLinkUrl));
      }),
      HomeGridClass(image: rateImgString, title: rateString,),
    ]; 
  }

  settingMenuLoading(context) async {
    try {
      setloading(false); // Never show full screen loader for settings
      await settingMenuGet(context);
      // Run profile fetch in background without awaiting or blocking UI
      settingLoadding(context);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  settingLoadding(context) async {
    // SWR fetch without loader
    try {
      await getUserEmployeeData(context);
    } catch (e) {
      /* ignored */
    }
  }

  getUserEmployeeData(context) async {
    const cacheKey = 'emp_profile_cache';
    const adminCacheKey = 'admin_profile_cache';
    const ttlMs = 12 * 60 * 60 * 1000; // 12 hours TTL for profile

    // ── Step 1: Load from local cache immediately ───────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      if (setEmpProfile == null && curentUser['Role'] != 'Admin') {
        final cachedJson = prefs.getString(cacheKey);
        final cachedTs = prefs.getInt('${cacheKey}_ts') ?? 0;
        if (cachedJson != null && (DateTime.now().millisecondsSinceEpoch - cachedTs) < ttlMs) {
          setEmpProfile = Employeelists.fromJson(jsonDecode(cachedJson));
          notifyListeners();
        }
      } else if (setAdminProfile == null && curentUser['Role'] == 'Admin') {
        final cachedJson = prefs.getString(adminCacheKey);
        final cachedTs = prefs.getInt('${adminCacheKey}_ts') ?? 0;
        if (cachedJson != null && (DateTime.now().millisecondsSinceEpoch - cachedTs) < ttlMs) {
          setAdminProfile = AdminProfiles.fromJson(jsonDecode(cachedJson));
          notifyListeners();
        }
      }
    } catch (_) {}

    // ── Step 2: Background API refresh ─────────────────────────────────────
    try {
      if (curentUser['Role'] == 'Admin' && curentUser['OriginalRole'] == null) {
        await Provider.of<EmployeMastServices>(context, listen: false).getemployee();
        final adminProfile = await AdminProfileApiClass().getAdminProfileData();
        setAdminProfile = adminProfile;
        
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(adminCacheKey, jsonEncode(adminProfile.toJson()));
          await prefs.setInt('${adminCacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
        } catch (_) {}
        notifyListeners();
      } else {
        await Provider.of<EmployeMastServices>(context, listen: false).getemployee();
        for (var element in Provider.of<EmployeMastServices>(context, listen: false).emplists) {
          if (curentUser['UserName'] == element.userName.toString() &&
              curentUser['Mobile1'] == element.mobile1) {
            setEmpProfile = element;
            // Persist fresh profile to cache
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(cacheKey, jsonEncode(element.toJson()));
              await prefs.setInt('${cacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
            } catch (_) {}
            break;
          }
        }
        notifyListeners();
      }
    } catch (_) {
      setloading(false);
    }
  }

    //----------------------------------------- Post Create Menu Settings ------------------------\\

  Future createMenuSettings(context) async {
    await AdminProfileApiClass().addCreateMenuSettings(flag: menuSettingFilterList.isEmpty ? "A" : "U",isUserFlag: isUser ? 'true' : 'false',isAdminFlag: isAdmin ? 'true' : 'false',companyId: selectedcurentcompany!.companyId.toString(),empId: selectedEmployeeList!.id.toString(),).then((value) {
      Map<String, dynamic> dataGet = json.decode(value);
      if (dataGet["Success"] == true) {
        Navigator.pop(context);
      }
    });
  }

  //----------------------------------------- Post Create Menu Settings ------------------------\\
  
  // list handle submit ontap
  settingMenuiHandleSubmit(size,context, HomeGridClass selectedSettingMenu) async {
    try {
      setloading(true);
      notifyListeners();
      if (selectedSettingMenu.title == rateString) {
        setloading(false);
        notifyListeners();
        String urlString = rateLinkUrl;
        final Uri url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        await selectedSettingMenu.onTap?.call();
      } 
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  // role rights value
  userRightsValue(bool value, bool setValue) {
    if(setValue){
      isUser = value;
    } else {
      isAdmin = value;
    }
    notifyListeners();
  }

  // role rights select sub-admin user 
  Future getselectUserAdmin(value) async {
    try {
      isAdmin = false;
      isUser = false;
      selectedEmployeeList = value;
      notifyListeners();
      await AdminProfileApiClass().getMenuSettingsData(empId: selectedEmployeeList!.id).then((value) {
        allMenuSettingsDataList = value;
        menuSettingFilterList = allMenuSettingsDataList;
        if (menuSettingFilterList.isNotEmpty) {
          for (var item in menuSettingFilterList) {
            final key = item.columnKey;
            if (key == 'AsAdmin') {
              if (item.columnValue == 'true') {
                isAdmin = item.columnValue.toString()== 'true' ? true : false;
              }
            } else if (key == 'AsUser') {
              if (item.columnValue == 'true') {
                isUser = item.columnValue.toString()== 'true' ? true : false;
              }
            }
          }
        }
        notifyListeners();
      }).onError((error, stackTrace) {},);
    } catch (e) { /* ignored */ }
  }
}
