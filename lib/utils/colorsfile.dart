// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ColorConst {
  static bool isDark = false;

  static Color get themeColor => const Color(0xff1864EC);
  static Color get darkGreenColor => const Color(0xff0f49bb);
  
  static Color get scaffoldColor => isDark ? const Color(0xff121212) : const Color(0xFFF6F6F6);
  static Color get white => isDark ? const Color(0xff1C1C1E) : const Color(0xffffffff);
  static Color get black => isDark ? const Color(0xffffffff) : const Color(0xff000000);
  static Color get grey => Colors.grey;
  static Color get red => Colors.red;
  static Color get present => const Color(0xFF009688);
  static Color get textBorder => isDark ? const Color(0xff2C2C2E) : const Color(0xffCCCBD0);
  static Color get textgrey => isDark ? const Color(0xffA9A9A9) : const Color(0xff696969);
  static Color get transparent => Colors.transparent;
  static Color get hintextColor => isDark ? const Color(0xff8E8E93) : const Color(0xff767A7D);
  static Color get passwordColor => isDark ? const Color(0xff333333) : const Color(0xffBFBFBF);
  static Color get themeOpicityColor => const Color(0xFF009688).withOpacity(.4);
  static Color get bottomIconColor => isDark ? const Color(0xffA9A9A9) : const Color(0xFF6A6B6E);
  static Color get appBarTitleColor => isDark ? const Color(0xffffffff) : const Color(0xFF565D67);
  static Color get otpTitleColor => isDark ? const Color(0xffffffff) : const Color(0xFF1D242E);
  static Color get greyOpicityColor => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F6FA);

  static Color get leaveTextColor => isDark ? const Color(0xffA9A9A9) : const Color(0xff8D8D8D);
  static Color get leaveHeadingColor => isDark ? const Color(0xffE5E5EA) : const Color(0xff5F5F5F);
  static Color get leaveSubHeadingColor => isDark ? const Color(0xffffffff) : const Color(0xff2B2B2B);
  static Color get leaveTypeColor => isDark ? const Color(0xffD1D1D6) : const Color(0xff7B7B7B);
  
  static Color get appbarTextColor => isDark ? const Color(0xffffffff) : const Color(0xff191919);
  static Color get textFiedBgColor => isDark ? const Color(0xff2C2C2E) : const Color(0xff9A9A9A);
  static Color get containerBorderColor => isDark ? const Color(0xff3A3A3C) : const Color(0xff9A9A9A);
  static Color get circleBgColors => isDark ? const Color(0xff3A2022) : const Color(0xffFFE2E5);

  static Color get holidayTitleColors => isDark ? const Color(0xffffffff) : const Color(0xff3C3C3C);
  static Color get holidaySubTitleColors => isDark ? const Color(0xffD1D1D6) : const Color(0xff515151);

  static Color get nodataTitleColors => isDark ? const Color(0xffA9A9A9) : const Color(0xff5A5A5A);
  static Color get commatextIconsColors => isDark ? const Color(0xffA9A9A9) : const Color(0xff7A797E);
  static Color get notesTitlesColors => isDark ? const Color(0xffffffff) : const Color(0xff585858);
  static Color get notesSubTitlesColors => isDark ? const Color(0xffD1D1D6) : const Color(0xff8C8C8C);
  static Color get notesCommandTitlesColors => isDark ? const Color(0xff1C1C1E) : const Color(0xffF9F9F9);
  static Color get iconsColors => isDark ? const Color(0xffE5E5EA) : const Color(0xff444444);
  static Color get addNoteImageColors => isDark ? const Color(0xffE5E5EA) : const Color(0xff4A4A4A);
  static Color get settingTextColors => isDark ? const Color(0xffffffff) : const Color(0xff313131);
  static Color get settingIconsColors => isDark ? const Color(0xffA9A9A9) : const Color(0xff727272);

  static Color get redDarkColors => const Color(0xffC14840);
  static Color get blueColors => const Color(0xff2314CC);
  static Color get hintextFormColors => isDark ? const Color(0xff8E8E93) : const Color(0xff98A2B3);
  static Color get selectDateColors => isDark ? const Color(0xffE5E5EA) : const Color(0xff344054);

  static Color get greenColor => const Color(0xff009619);

  static Color get blueColor => const Color(0xff5FB1E2);  
  static Color get greyColor => const Color(0xffAEC1BA);  
  static Color get paidLeaveColor => const Color(0xffA258F6);  
  static Color get holidayColor => const Color(0xffE0AA0A);  

  static Color get iconBorderColor => isDark ? const Color(0xff3A3A3C) : const Color(0xffD0D5DD);  
  static Color get textHeadingColor => isDark ? const Color(0xff8E8E93) : const Color(0xffA1A1A1);  
  static Color get darkBlueColor => const Color(0xff1492C7);

  static Color get verticalborderColor => isDark ? const Color(0xff2C2C2E) : const Color(0xffD5D5D5);
  static Color get attendanceBgColor => isDark ? const Color(0xff112211) : const Color(0xffF3FFF8);

  static Color get gold         => const Color(0xFFFFB300);
  static Color get goldLight    => isDark ? const Color(0xFF2A2315) : const Color(0xFFFFF8E1);
  static Color get goldBorder   => isDark ? const Color(0xFF4A3F25) : const Color(0xFFFFE082);
  static Color get goldText     => isDark ? const Color(0xFFFFD54F) : const Color(0xFF6D4C00);
  static Color get goldShadow   => isDark ? const Color(0x11FFB300) : const Color(0x33FFB300);
  static Color get silver       => const Color(0xFF78909C);
  static Color get silverLight  => isDark ? const Color(0xFF202528) : const Color(0xFFECEFF1);
  static Color get silverBorder => isDark ? const Color(0xFF373E43) : const Color(0xFFB0BEC5);
  static Color get silverText   => isDark ? const Color(0xFFCFD8DC) : const Color(0xFF263238);
  static Color get silverShadow => isDark ? const Color(0x1178909C) : const Color(0x3378909C);
  static Color get bronze       => const Color(0xFFBF6A00);
  static Color get bronzeLight  => isDark ? const Color(0xFF2A1F15) : const Color(0xFFFFF3E0);
  static Color get bronzeBorder => isDark ? const Color(0xFF4A3725) : const Color(0xFFFFCC80);
  static Color get bronzeText   => isDark ? const Color(0xFFFFB74D) : const Color(0xFF4E2600);
  static Color get bronzeShadow => isDark ? const Color(0x11BF6A00) : const Color(0x33BF6A00);
  static Color get othersHeader      => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6);
  static Color get othersHeaderText  => isDark ? const Color(0xFFE5E5EA) : const Color(0xFF374151);
  static Color get othersBadge       => const Color(0xFF6B7280);
  static Color get greenProgress     => const Color(0xFF10B981);
  static Color get othersAvatar      => isDark ? const Color(0xFF252A3A) : const Color(0xFFEEF2FF);
  static Color get othersAvatarText  => isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
  static Color get othersRankBg      => isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);
  static Color get othersRankText    => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  static Color get logoutBg     => isDark ? const Color(0xFF2D1515) : const Color(0xFFFFF1F1);
  static Color get logoutBorder => isDark ? const Color(0xFF6B2222) : const Color(0xFFFFCDD2);
  static Color get logoutText   => isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F);
}
