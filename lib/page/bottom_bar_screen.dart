import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/attendance/showviewdata.dart';
import 'package:tax_hrm/page/attendance/viewAttendance_screen.dart';
import 'package:tax_hrm/page/home/home_screen.dart';
import 'package:tax_hrm/page/home/selfie_punch_screen.dart';
import 'package:tax_hrm/page/leave/admin_leave_page.dart';
import 'package:tax_hrm/page/leave/leavepage.dart';
import 'package:tax_hrm/page/setting/setting_page.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/splashprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/theme_provider.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';


class AnimatedBottomBar extends StatefulWidget {
  const AnimatedBottomBar({super.key});

  @override
  State<AnimatedBottomBar> createState() => _AnimatedBottomBarState();  
}

class _AnimatedBottomBarState extends State<AnimatedBottomBar> {
  

  List<Widget> get pageList => curentUser['Role'] == 'Admin' ? [
    HomeScreen(),
    ShowAttenDanceEmployeData(),
    AdminLeavePage(),
    SettingPage(),
  ] : [
    HomeScreen(),
    AttendanceScreen(empData: null),
    LeaveViewPage(),
    SettingPage(),
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SplashProvider>(context, listen: false).requestAllPermissions();
      FcmTokenService.instance.checkPendingNotification();
    });
    SharedPreferences.getInstance().then((p) {
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final homeProvider = Provider.of<HomeProvider>(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    Provider.of<ThemeProvider>(context);
    Provider.of<LanguageProvider>(context);
    
    return WillPopScope(
      onWillPop: () => commonDialogBoxDesign(context: context, size: size, title: exitString),
      child: checkInterNetConnection.connectionType == 0 ? const NoInternetViewPage() : Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        body: fabSelected ? SelfiePunchScreen() : pageList[selectedIndex],
        bottomNavigationBar: Container(
          color: ColorConst.white,
          child: SafeArea(
            child: StylishBottomBar(
              key: ValueKey(Provider.of<LanguageProvider>(context).currentLanguage),
              backgroundColor: ColorConst.white,
            items: [
              BottomBarItem(
                icon: SvgPicture.asset(homeImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(homeImageString, color: fabSelected ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(homeString, style: TextStyle(fontSize: selectedIndex == 0 && !fabSelected ? 12.0 : 12.0, color: selectedIndex == 0 && !fabSelected? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: selectedIndex == 0 && !fabSelected? fontInterMediumString: fontInterRegularString, fontWeight: selectedIndex == 0 && !fabSelected? FontWeight.w500: FontWeight.w400,))
              ),
              BottomBarItem(
                icon: SvgPicture.asset(attendanceImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(attendanceImageString, color: fabSelected ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(attendanceString, style: TextStyle(fontSize: selectedIndex == 1 && !fabSelected ? 12.0 : 12.0, color: selectedIndex == 1 && !fabSelected? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: selectedIndex == 1 && !fabSelected? fontInterMediumString: fontInterRegularString, fontWeight: selectedIndex == 1 && !fabSelected? FontWeight.w500: FontWeight.w400,)),
              ),
              BottomBarItem(
                icon: SvgPicture.asset(leaveImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(leaveImageString, color: fabSelected ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(leaveString, style: TextStyle(fontSize: selectedIndex == 2 && !fabSelected ? 12.0 : 12.0, color: selectedIndex == 2 && !fabSelected? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: selectedIndex == 2 && !fabSelected? fontInterMediumString: fontInterRegularString, fontWeight: selectedIndex == 2 && !fabSelected? FontWeight.w500: FontWeight.w400,)),
              ),
              BottomBarItem(
                icon: SvgPicture.asset(settingImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(settingImageString, color: fabSelected ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(settingString, style: TextStyle(fontSize: selectedIndex == 3 && !fabSelected ? 12.0 : 12.0, color: selectedIndex == 3 && !fabSelected? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: selectedIndex == 3 && !fabSelected? fontInterMediumString: fontInterRegularString, fontWeight: selectedIndex == 3 && !fabSelected? FontWeight.w500: FontWeight.w400,)),
              ),
            ],
            option: AnimatedBarOptions(
              iconStyle: IconStyle.Default,
              barAnimation: BarAnimation.fade,
            ),
            fabLocation: curentUser['Role'] == 'Admin' ? null : StylishBarFabLocation.center,
            currentIndex: selectedIndex,
            onTap: (value) {
              homeProvider.changeSelectBottomBar(value);
            },
          ),
         ),
        ),
        floatingActionButton: curentUser['Role'] == 'Admin' ? SizedBox() : Container(
          height: size.width * 0.15,
          width: size.width * 0.15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorConst.themeColor,
                ColorConst.darkGreenColor,
              ],
            ),
            border: Border.all(
              color: ColorConst.white,
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: homeProvider.selectFloadButton,

              child: Center(
                child: Image.asset(
                  tapImageString,
                  height: size.width * 0.075,
                  width: size.width * 0.075,
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}