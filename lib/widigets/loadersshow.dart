
// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

scanloading(){
  return   Center(child:  SpinKitCubeGrid(
  color: ColorConst.themeColor,
  size: 50.0,
),);
}


circleThemLoader(){
  return  CircularProgressIndicator(
    color: ColorConst.themeColor,
  );
}