// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';

Widget payrollMasterCardDesign({size,editOntap,deleteOntap,titles,arrorOntap,salaryValue,pfValue,tdsValue,esicValue,conveyanceValue,hraValue,nextAmountValue,itemHideBoolValue}) {
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
            iconBtn(Icons.edit, ColorConst.themeColor,editOntap),
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

Widget attendanceHeading({headingTitles}) {
  return Text(headingTitles,textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500,fontSize: 13,fontFamily: fontInterMediumString,color: ColorConst.black));
}

Widget attendanceInOutDesign({size,bgColor,borderColor,date,inTimePunch,outTimepuchOut,hoursCount,workingHours,breakHours,attendanceDataList}) {
  return Container(
    height: size.height *0.06,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(4.0),
      border: Border.all(color: borderColor,width: 1.5)
    ),
    child: Row(
      children: [
        buildTableHeaderCell(size, date, width: size.width * 0.2,textColors: ColorConst.black),
        verticalBorder(),
        buildTableHeaderCell(size, inTimePunch, width: size.width * 0.15, textColors: ColorConst.black),
        verticalBorder(),
        buildTableHeaderCell(size, outTimepuchOut, width: size.width * 0.15, textColors: outTimepuchOut == 'Week Off' ? Colors.red : outTimepuchOut == 'PAID LEAVE' ? Colors.green : outTimepuchOut == 'UNPAID LEAVE' ? Colors.orange : attendanceDataList == true ? Colors.deepPurple : ColorConst.black,),
        verticalBorder(),
        buildTableHeaderCell(size, breakHours, width: size.width * 0.12,textColors: ColorConst.black),
        verticalBorder(),
        buildTableHeaderCell(size, hoursCount, width: size.width * 0.12,textColors: ColorConst.black),
        verticalBorder(),
        buildTableHeaderCell(size, workingHours, width: size.width * 0.12,textColors: ColorConst.black),
      ],
    )
  );
}

Widget verticalBorder() {
  return Padding(
    padding: EdgeInsets.only(top: 5,bottom: 5),
    child: VerticalDivider(     
      color: ColorConst.verticalborderColor,
      thickness: 1,
      width: 1,
    ),
  );
}


Widget headingTextGet({titles}) {
  return Center(child: Text(titles,style: TextStyle(fontSize: 12.0,fontWeight: FontWeight.w600,fontFamily: fontInterSemiBoldString),));
}

// Only For attendance Counting
Widget payrollSummaryTile(BuildContext context, Size size, String title, String value, Color color, {bgColors,onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: bgColors??ColorConst.greyOpicityColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          widthSpacer(size.width * 0.02),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style:  TextStyle( fontSize: size.width * 0.035, color: Colors.grey, fontFamily: fontInterMediumString, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w700, fontFamily: fontInterBoldString)),
            ],
          )
        ],
      ),
    ),
  );
}

Widget employeeSummryDesign(size,{subHeadingTitle,headingTitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(headingTitle,style:TextStyle(fontFamily: fontInterBoldString,fontSize: 15,fontWeight: FontWeight.w600)),
      heightSpacer(size.height*0.008),
      Container(
        width: size.width,
        height: size.height*0.06,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.09),
          border: Border.all(color: ColorConst.textBorder,width: 1)
        ),
        padding: EdgeInsets.only(left: 10),
        alignment: Alignment.centerLeft,
        child: Text(subHeadingTitle,style:TextStyle(fontFamily: fontInterMediumString,fontSize: 15,fontWeight: FontWeight.w500)),
      )
    ],
  );
}

Widget buildTableHeaderCell(Size size, String text, {required double width,textColors}) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size.width * 0.032,
        fontWeight: FontWeight.w600,
        color: textColors??ColorConst.white,
      ),
    ),
  );
}

Widget buildTableCellFixed(Size size, String value, {required double width, bool isBold = false, String? status}) {
  Color textColor = Colors.black87;
  
  if (status != null && status.isNotEmpty) {
    if (status == 'WeekOff') {
      textColor = Colors.red;
    } else if (status == 'PAID LEAVE') {
      textColor = Colors.green;
    } else if (status == 'DHULETI') {
      textColor = Colors.purple;
    }
  }
  
  return SizedBox(
    width: width,
    child: Text(
      value.isEmpty ? '-' : value,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size.width * 0.03,
        color: textColor,
        fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );
}