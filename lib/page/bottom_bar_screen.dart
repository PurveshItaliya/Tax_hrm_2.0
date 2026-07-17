import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/attendance/showviewdata.dart';
import 'package:tax_hrm/page/attendance/viewAttendance_screen.dart';
import 'package:tax_hrm/page/home/home_screen.dart';
import 'package:tax_hrm/page/home/selfie_punch_screen.dart';
import 'package:tax_hrm/page/leave/admin_leave_page.dart';
import 'package:tax_hrm/page/leave/leavepage.dart';
import 'package:tax_hrm/page/setting/setting_page.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/theme_provider.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:get/get.dart';
import 'package:tax_hrm/controllers/main_bottom_bar_controller.dart';
class AnimatedBottomBar extends StatelessWidget {
  AnimatedBottomBar({super.key});

  final MainBottomBarController controller = Get.put(MainBottomBarController());

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
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    Provider.of<ThemeProvider>(context);
    Provider.of<LanguageProvider>(context);
    
    return WillPopScope(
      onWillPop: () => commonDialogBoxDesign(context: context, size: size, title: exitString),
      child: checkInterNetConnection.connectionType == 0 ? const NoInternetViewPage() : Obx(() => Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        body: controller.fabSelected.value ? SelfiePunchScreen() : pageList[controller.selectedIndex.value],
        bottomNavigationBar: Container(
          color: ColorConst.white,
          child: SafeArea(
            child: StylishBottomBar(
              key: ValueKey(Provider.of<LanguageProvider>(context).currentLanguage),
              backgroundColor: ColorConst.white,
            items: [
              BottomBarItem(
                icon: SvgPicture.asset(homeImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(homeImageString, color: controller.fabSelected.value ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(homeString, style: TextStyle(fontSize: controller.selectedIndex.value == 0 && !controller.fabSelected.value ? 12.0 : 12.0, color: controller.selectedIndex.value == 0 && !controller.fabSelected.value? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: controller.selectedIndex.value == 0 && !controller.fabSelected.value? fontInterMediumString: fontInterRegularString, fontWeight: controller.selectedIndex.value == 0 && !controller.fabSelected.value? FontWeight.w500: FontWeight.w400,))
              ),
              BottomBarItem(
                icon: SvgPicture.asset(attendanceImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(attendanceImageString, color: controller.fabSelected.value ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(attendanceString, style: TextStyle(fontSize: controller.selectedIndex.value == 1 && !controller.fabSelected.value ? 12.0 : 12.0, color: controller.selectedIndex.value == 1 && !controller.fabSelected.value? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: controller.selectedIndex.value == 1 && !controller.fabSelected.value? fontInterMediumString: fontInterRegularString, fontWeight: controller.selectedIndex.value == 1 && !controller.fabSelected.value? FontWeight.w500: FontWeight.w400,)),
              ),
              BottomBarItem(
                icon: SvgPicture.asset(leaveImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(leaveImageString, color: controller.fabSelected.value ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(leaveString, style: TextStyle(fontSize: controller.selectedIndex.value == 2 && !controller.fabSelected.value ? 12.0 : 12.0, color: controller.selectedIndex.value == 2 && !controller.fabSelected.value? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: controller.selectedIndex.value == 2 && !controller.fabSelected.value? fontInterMediumString: fontInterRegularString, fontWeight: controller.selectedIndex.value == 2 && !controller.fabSelected.value? FontWeight.w500: FontWeight.w400,)),
              ),
              BottomBarItem(
                icon: SvgPicture.asset(settingImageString, color: ColorConst.bottomIconColor, height: size.width * 0.06, width: size.width * 0.06),
                selectedIcon: SvgPicture.asset(settingImageString, color: controller.fabSelected.value ? ColorConst.bottomIconColor : ColorConst.themeColor, height: size.width * 0.06, width: size.width * 0.06),
                title:  Text(settingString, style: TextStyle(fontSize: controller.selectedIndex.value == 3 && !controller.fabSelected.value ? 12.0 : 12.0, color: controller.selectedIndex.value == 3 && !controller.fabSelected.value? ColorConst.themeColor: ColorConst.bottomIconColor, fontFamily: controller.selectedIndex.value == 3 && !controller.fabSelected.value? fontInterMediumString: fontInterRegularString, fontWeight: controller.selectedIndex.value == 3 && !controller.fabSelected.value? FontWeight.w500: FontWeight.w400,)),
              ),
            ],
            option: AnimatedBarOptions(
              iconStyle: IconStyle.Default,
              barAnimation: BarAnimation.fade,
            ),
            fabLocation: curentUser['Role'] == 'Admin' ? null : StylishBarFabLocation.center,
            currentIndex: controller.selectedIndex.value,
            onTap: (value) {
              controller.changeTab(value);
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
              onTap: controller.selectFab,

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
      )),
    );
  }
}