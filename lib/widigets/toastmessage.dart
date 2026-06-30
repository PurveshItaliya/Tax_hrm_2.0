// ignore_for_file: strict_top_level_inference

import 'package:fluttertoast/fluttertoast.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

showtoastmessage(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 1,
    backgroundColor: ColorConst.themeColor,
    textColor: ColorConst.white,
    fontSize: 16.0,
  );
}
