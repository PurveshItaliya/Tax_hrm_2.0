import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:provider/provider.dart';

import 'package:tax_hrm/controllers/main_bottom_bar_controller.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/attendance/showviewdata.dart';
import 'package:tax_hrm/page/attendance/viewAttendance_screen.dart';
import 'package:tax_hrm/page/home/home_screen.dart';
import 'package:tax_hrm/page/home/selfie_punch_screen.dart';
import 'package:tax_hrm/page/leave/admin_leave_page.dart';
import 'package:tax_hrm/page/leave/leavepage.dart';
import 'package:tax_hrm/page/setting/setting_page.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/theme_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widgets/native_liquid_glass_bar.dart';

class AnimatedBottomBar extends StatelessWidget {
  AnimatedBottomBar({super.key});

  final MainBottomBarController controller =
  Get.put(MainBottomBarController());

  bool get isAdmin => curentUser['Role'] == 'Admin';

  List<Widget> get pageList {
    if (isAdmin) {
      return [
        HomeScreen(),
        ShowAttenDanceEmployeData(),
        AdminLeavePage(),
        SettingPage(),
      ];
    }

    return [
      HomeScreen(),
      AttendanceScreen(empData: null),
      LeaveViewPage(),
      SettingPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final internetProvider =
    context.watch<InternetConnectionProvider>();

    // Keep listening for theme and language changes.
    context.watch<ThemeProvider>();
    context.watch<LanguageProvider>();

    return WillPopScope(
      onWillPop: () => commonDialogBoxDesign(
        context: context,
        size: size,
        title: exitString,
      ),
      child: internetProvider.connectionType == 0
          ? const NoInternetViewPage()
          : Obx(() {
        final selectedPage = controller.fabSelected.value
            ? SelfiePunchScreen()
            : pageList[controller.selectedIndex.value];

        // ── iOS: use the real native UITabBar (Liquid Glass on iOS 26+) ──
        if (Platform.isIOS && !controller.fabSelected.value) {
          return Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            extendBody: true,
            body: selectedPage,
            bottomNavigationBar: NativeLiquidGlassBar(
              key: ValueKey(
                context.watch<LanguageProvider>().currentLanguage,
              ),
              currentIndex: controller.selectedIndex.value,
              onTap: controller.changeTab,
              tintColor: ColorConst.themeColor,
              items: isAdmin
                  ? [
                      LiquidTabItem(
                        label: homeString,
                        symbol: 'house',
                        selectedSymbol: 'house.fill',
                      ),
                      LiquidTabItem(
                        label: attendanceString,
                        symbol: 'calendar',
                        selectedSymbol: 'calendar',
                      ),
                      LiquidTabItem(
                        label: leaveString,
                        symbol: 'doc.text',
                        selectedSymbol: 'doc.text.fill',
                      ),
                      LiquidTabItem(
                        label: settingString,
                        symbol: 'gearshape',
                        selectedSymbol: 'gearshape.fill',
                      ),
                    ]
                  : [
                      LiquidTabItem(
                        label: homeString,
                        symbol: 'house',
                        selectedSymbol: 'house.fill',
                      ),
                      LiquidTabItem(
                        label: attendanceString,
                        symbol: 'calendar',
                        selectedSymbol: 'calendar',
                      ),
                      LiquidTabItem(
                        label: leaveString,
                        symbol: 'doc.text',
                        selectedSymbol: 'doc.text.fill',
                      ),
                      LiquidTabItem(
                        label: settingString,
                        symbol: 'gearshape',
                        selectedSymbol: 'gearshape.fill',
                      ),
                    ],
            ),
          );
        }

        // ── iOS FAB / other platforms: Flutter Liquid Glass bar ──
        return Scaffold(
          backgroundColor: ColorConst.scaffoldColor,
          extendBody: true,
          body: LiquidGlassView(
            backgroundWidget: selectedPage,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _LiquidNavigationBar(
                    key: ValueKey(
                      context
                          .watch<LanguageProvider>()
                          .currentLanguage,
                    ),
                    isAdmin: isAdmin,
                    selectedIndex: controller.selectedIndex.value,
                    fabSelected: controller.fabSelected.value,
                    onTabSelected: controller.changeTab,
                    onPunchSelected: controller.selectFab,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LiquidNavigationBar extends StatelessWidget {
  const _LiquidNavigationBar({
    super.key,
    required this.isAdmin,
    required this.selectedIndex,
    required this.fabSelected,
    required this.onTabSelected,
    required this.onPunchSelected,
  });

  final bool isAdmin;
  final int selectedIndex;
  final bool fabSelected;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPunchSelected;


  static const LiquidGlassStyle _punchGlassStyle =
  LiquidGlassStyle(
    shape: LiquidGlassShape.roundedRectangle(
      cornerRadius: 40,
      borderWidth: 1.8,
    ),
    appearance: LiquidGlassAppearance(
      color: Color(0x32FFFFFF),
      saturation: 1.20,
      blur: LiquidGlassBlur(
        sigmaX: 7,
        sigmaY: 7,
      ),
    ),
    refraction: LiquidGlassRefraction(
      refractionType: OpticalRefraction(
        refraction: 1.55,
        refractionWidth: 20,
        depth: 0.80,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    const double extraBottomForCorners = 20.0;

    final barGlassStyle = LiquidGlassStyle(
      shape: const LiquidGlassShape.continuousRoundedRectangle(
        cornerRadius: 18,
        borderWidth: 1.2,
      ),
      appearance: LiquidGlassAppearance(
        color: isDark ? const Color(0x258A8A8A) : const Color(0x12505050),
        saturation: 2.18,
        blur: const LiquidGlassBlur(
          sigmaX: 5,
          sigmaY: 5,
        ),
      ),
      refraction: const LiquidGlassRefraction(
        refractionType: OpticalRefraction(
          refraction: 1.45,
          refractionWidth: 15,
          depth:1.1,
        ),
      ),
    );

    return SizedBox(
      height: (isAdmin ? 72 : 86) + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: -extraBottomForCorners,
            right: -extraBottomForCorners,
            bottom: -extraBottomForCorners,
            height: 60 + bottomPadding + extraBottomForCorners,
            child: RepaintBoundary(
              child: LiquidGlassLens(
                style: barGlassStyle,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isAdmin ? 14 : 10,
                    right: isAdmin ? 14 : 10,
                    bottom: bottomPadding + extraBottomForCorners,
                  ),
                  child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: isAdmin  ?_buildAdminItems(): _buildEmployeeItems(),
                      )

                ),
              ),
            ),
          ),

          if (!isAdmin)
            Positioned(
              top: 0,
              child: _LiquidPunchButton(
                selected: fabSelected,
                onTap: onPunchSelected,
                glassStyle: _punchGlassStyle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminItems() {
    return Row(
      children: [
        _expandedItem(
          index: 0,
          asset: homeImageString,
          title: homeString,
        ),
        _expandedItem(
          index: 1,
          asset: attendanceImageString,
          title: attendanceString,
        ),
        _expandedItem(
          index: 2,
          asset: leaveImageString,
          title: leaveString,
        ),
        _expandedItem(
          index: 3,
          asset: settingImageString,
          title: settingString,
        ),
      ],
    );
  }

  Widget _buildEmployeeItems() {
    return Row(
      children: [
        _expandedItem(
          index: 0,
          asset: homeImageString,
          title: homeString,
        ),
        _expandedItem(
          index: 1,
          asset: attendanceImageString,
          title: attendanceString,
        ),

        // Space for the center Punch button.
        const SizedBox(width: 72),

        _expandedItem(
          index: 2,
          asset: leaveImageString,
          title: leaveString,
        ),
        _expandedItem(
          index: 3,
          asset: settingImageString,
          title: settingString,
        ),
      ],
    );
  }

  Widget _expandedItem({
    required int index,
    required String asset,
    required String title,
  }) {
    final selected = selectedIndex == index && !fabSelected;

    return Expanded(
      child: _LiquidNavigationItem(
        selected: selected,
        asset: asset,
        title: title,
        onTap: () => onTabSelected(index),
      ),
    );
  }
}

class _LiquidNavigationItem extends StatelessWidget {
  const _LiquidNavigationItem({
    required this.selected,
    required this.asset,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final String asset;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final selectedColor = isDark ? Colors.white : ColorConst.black;
    final unselectedColor = isDark ? Colors.white.withOpacity(0.60) : ColorConst.bottomIconColor;

    final selectedTabGlassStyle = LiquidGlassStyle(
      shape: const LiquidGlassShape.roundedRectangle(
        cornerRadius: 25,
      ),
      appearance: LiquidGlassAppearance(
        color: isDark ? const Color(0x18FFFFFF) : Color(0x20707070),
        saturation: 2.30,
        blur: const LiquidGlassBlur(
          sigmaX: 8,
          sigmaY: 8,
        ),
      ),
      refraction: const LiquidGlassRefraction(
        refractionType: OpticalRefraction(
          refraction: 1.40,
          refractionWidth: 12,
          depth: 1.5,
        ),
      ),
    );

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: SvgPicture.asset(
              asset,
              colorFilter: ColorFilter.mode(
                selected ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: 8.5,
              color: selected ? selectedColor : unselectedColor,
              fontFamily: fontInterMediumString,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Center(
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                child: selected
                    ? LiquidGlassLens(
                        style: selectedTabGlassStyle,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: content,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.transparent,
                        ),
                        child: content,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidPunchButton extends StatelessWidget {
  const _LiquidPunchButton({
    required this.selected,
    required this.onTap,
    required this.glassStyle,
  });

  final bool selected;
  final VoidCallback onTap;
  final LiquidGlassStyle glassStyle;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.08 : 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      child: SizedBox(
        height: 66,
        width: 66,
        child: RepaintBoundary(
          child: LiquidGlassLens(
            style: glassStyle,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selected
                          ? [
                        ColorConst.darkGreenColor,
                        ColorConst.themeColor,
                      ]
                          : [
                        ColorConst.themeColor,
                        ColorConst.darkGreenColor,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.80),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConst.themeColor
                            .withOpacity(selected ? 0.40 : 0.22),
                        blurRadius: selected ? 18 : 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      tapImageString,
                      height: 31,
                      width: 31,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}