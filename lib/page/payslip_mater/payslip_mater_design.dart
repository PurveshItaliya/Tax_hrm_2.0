// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';

Widget paySlipMasterCardDesign({size,paySlipOntap,deleteOntap,titles,arrorOntap,salaryValue,pfValue,tdsValue,esicValue,conveyanceValue,hraValue,nextAmountValue,itemHideBoolValue}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(8),
    width: size.width,
    decoration: BoxDecoration(
      color: ColorConst.white,
      border: Border.all(color: ColorConst.grey,width: 1),
      borderRadius: BorderRadius.circular(6.0),
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
              child: Text(
                titles,
                style: TextStyle(fontSize: 15,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString),
              ),
            ),
            widthSpacer(size.width *0.02),
            GestureDetector(
              onTap: paySlipOntap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors:[ColorConst.themeColor, ColorConst.darkGreenColor], begin: Alignment.topCenter,end: Alignment.bottomCenter),
                ),
                child: Row(
                  children:  [
                    Icon(Icons.download, color: ColorConst.white,size: 18,),
                    widthSpacer(6),
                    Text(viewPaySlipString.toString().split(" ").last,style: TextStyle(color: ColorConst.white,fontWeight: FontWeight.w600,),),
                  ],
                ),
              ),
            ),
            widthSpacer(size.width *0.02),
            iconBtn(Icons.delete, ColorConst.redDarkColors,deleteOntap),
            widthSpacer(size.width *0.02),
            iconBtn(itemHideBoolValue?Icons.keyboard_arrow_up:Icons.keyboard_arrow_down, ColorConst.black,arrorOntap),
          ],
        ),
        if(itemHideBoolValue)...[
          heightSpacer(size.height *0.01),
          Row(
            children: [
              Expanded(child: ritchTextDesign(heading: "${salarySlipString.toString().split(" ").first.toString()} \n",titles: salaryValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start,titlesSize: 14.0)),
              widthSpacer(5.0),
              Expanded(child: ritchTextDesign(heading: "$pfString \n",titles: pfValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start,titlesSize: 14.0)),
              widthSpacer(5.0),
              Expanded(child: ritchTextDesign(heading: "$tdsString \n",titles: tdsValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start,titlesSize: 14.0)),
            ],
          ),
          heightSpacer(size.height *0.02),
          Row(
            children: [
              Expanded(child: ritchTextDesign(heading: "$esicString \n",titles: esicValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start,titlesSize: 14.0)),
              widthSpacer(5.0),
              Expanded(child: ritchTextDesign(heading: "$conveyanceString \n",titles: conveyanceValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start,titlesSize: 14.0)),
              widthSpacer(5.0),
              Expanded(child: ritchTextDesign(heading: "$hraString \n",titles: hraValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start,titlesSize: 14.0)),
            ],
          ),
          heightSpacer(size.height *0.025),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    netPayableString,
                    style: TextStyle(fontWeight: FontWeight.w500,fontFamily: fontInterMediumString,fontSize: 15),
                  ),
                ),
                Text("₹$nextAmountValue",style: TextStyle(fontWeight: FontWeight.w600,fontFamily: fontInterSemiBoldString,fontSize: 15),),
              ],
            ),
          ),
          heightSpacer(size.height *0.02),
        ],
      ],
    ),
  );
}