

// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';

// admin Leave Card design 

Widget adminLeaveCard({size,editOntap,deleteOntap,titles,leaveTypes,yearlyValue,monthlyValue,quarterlyValue,considerWeekly,bgColorValue,considerHoliday,holidayColors,halfYearlyValue}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: ColorConst.white,
      border: Border.all(color: ColorConst.grey,width: 1.5),
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
                  ritchTextDesign(heading: "${selectLeaveTypeString.toString().split("Select ").last.toString()} :- ",titles: leaveTypes,headingColor: ColorConst.textHeadingColor,headingSize: 10.0,titlesSize: 9.0,textAligmnment: TextAlign.left),
                ],
              ),
            ),
            widthSpacer(size.width *0.02),
            iconBtn(Icons.edit, ColorConst.themeColor,editOntap),
            widthSpacer(size.width *0.02),
            iconBtn(Icons.delete, ColorConst.redDarkColors,deleteOntap),
          ],
        ),
        Divider(color: ColorConst.grey,),
        Row(
          children: [
            Expanded(child: ritchTextDesign(heading: "$yearlyLimitString \n",titles: yearlyValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.center,headingSize: 10.0)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$monthlyLimitString \n",titles: monthlyValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.center,headingSize: 10.0)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$quarterlyLimitString \n",titles: quarterlyValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.center,headingSize: 10.0)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$halfYearlyString \n",titles: halfYearlyValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.center,headingSize: 10.0)),
          ],
        ),
        heightSpacer(size.height*0.015),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            leaveAndHoliday(size,titles: considerHolidayString,subTitles: considerHoliday,bgColors: holidayColors),
            leaveAndHoliday(size,titles: considerWeeklyString,subTitles: considerWeekly,bgColors: bgColorValue),
          ],
        )
      ],
    ),
  );
}

Widget leaveAndHoliday(size,{titles,subTitles,required Color bgColors}) {
  return Column(
    children: [
      Text(
        titles,
        style: TextStyle(fontSize: 11,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString),
      ),
      heightSpacer(size.height *0.005),
      Container(
        decoration: BoxDecoration(
          color: bgColors.withOpacity(0.05),
          border: Border.all(color: bgColors),
          borderRadius: BorderRadius.circular(8.0)
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          subTitles,
          style:TextStyle(
            fontSize: 11,
            color: bgColors,
            fontFamily: fontInterBoldString
          ),
        ),
      ),
    ],
  );
}