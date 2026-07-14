// ignore_for_file: strict_top_level_inference, file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

// SafeArea bgColor and text color

void safeAreaBgAndTextColor(BuildContext context,{Color? safeAreaBgColor,Brightness? safeAreaBrightness}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor:
          isDark ? ColorConst.black : (safeAreaBgColor ?? ColorConst.white),
      statusBarIconBrightness:
          isDark ? Brightness.light : (safeAreaBrightness ??Brightness.dark),
      statusBarBrightness:
          isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ),
  );

}

bool isDarkColor(Color color) {
  return color.computeLuminance() < 0.5;
}

class SelectLoginClass{
  final String title;
  final String description;
  final IconData icon;
  SelectLoginClass({required this.title,required this.description,required this.icon,});
}

Widget loaderDesign() {
  return Center(child: CircularProgressIndicator(color: ColorConst.themeColor,));
}

String maskMobile(String mobile) {
  if (mobile.length < 4) return mobile;
  return '******${mobile.substring(mobile.length - 4)}';
}

String maskEmail(String email) {
  if (!email.contains('@')) return email;

  final parts = email.split('@');
  final name = parts[0];
  final domain = parts[1];

  if (name.length <= 3) {
    return '${name[0]}***@$domain';
  }

  return '${name.substring(0, 7)}*****************.${domain.split('.').last}';
}

class HomeGridClass{
  final String image;
  final String title;
  Color? color;
  Widget? pageNavigator;
  Function()? onTap;
  HomeGridClass({required this.image, required this.title, this.color, this.pageNavigator, this.onTap});
}

TimeOfDay amPmToTimeOfDay(String time) {
  final parts = time.split(' ');
  final hm = parts[0].split(':');

  int hour = int.parse(hm[0]);
  int minute = int.parse(hm[1]);

  if (parts[1] == 'PM' && hour != 12) hour += 12;
  if (parts[1] == 'AM' && hour == 12) hour = 0;

  return TimeOfDay(hour: hour, minute: minute);
}