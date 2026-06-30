// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';

// recruitment Card design 
Widget recruitmentCard({size,titles,interviewDate,conductedBy,position,departmentName,editOntap,deleteOntap}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: ColorConst.white,
      border: Border.all(color: ColorConst.greyColor,width: 1.5),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: ColorConst.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    titles,
                    style: TextStyle(fontSize: 15,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString),
                  ),
                  ritchTextDesign(heading: "$interviewDateString :- ",titles: interviewDate,headingColor: ColorConst.textHeadingColor,headingSize: 10.0,titlesSize: 9.0,textAligmnment: TextAlign.left),
                ],
              ),
            ),
            iconBtn(Icons.edit, ColorConst.themeColor,editOntap),
            widthSpacer(size.width *0.02),
            iconBtn(Icons.delete, ColorConst.redDarkColors,deleteOntap),
          ],
        ),
        Divider(color: ColorConst.greyColor,),
        ritchTextDesign(heading: "$conductedByString :- ",titles: conductedBy,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.left),
        heightSpacer(size.height*0.005),
        ritchTextDesign(heading: "$departmentNameString :- ",titles: departmentName,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.left),
        heightSpacer(size.height*0.005),
        ritchTextDesign(heading: "$positionString :- ",titles: position,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.left),
      ],
    ),
  );
}