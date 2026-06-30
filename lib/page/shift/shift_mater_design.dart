// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/spacer.dart';

// shift Group design 
void showAddShiftGroupDialog(BuildContext context,formKey,addEditFlag,{size,setdid}) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
      return Consumer<ShiftMasterProvider>(
        builder: (context, shiftMasterProvider, child) {      
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              width: size.width,
              height: size.height * 0.6,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Form(
                key: formKey,
                autovalidateMode: shiftMasterProvider.autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addShiftGroupString,style: TextStyle(color: ColorConst.black,fontSize: 20,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600),),
                    heightSpacer(size.height *0.02),
                    CommonTextField(controller: shiftMasterProvider.shiftFNcontroller,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterShiftFullNameString,fillColors: ColorConst.white,showHeading: shiftFullNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors, validator: (value) {
                      if(value!.isEmpty) {
                        return '$pleaseEnterString $shiftFullNameString';
                      }
                      return null;
                    }),
                    heightSpacer(size.height *0.02),
                    CommonTextField(controller: shiftMasterProvider.shiftSNcontroller,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterShiftShortNameString,fillColors: ColorConst.white,showHeading: shiftShortNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors, validator: (value) {
                      if(value!.isEmpty) {
                        return '$pleaseEnterString $shiftShortNameString';
                      }
                      return null;
                    }),
                    heightSpacer(size.height *0.02),
                    Row(
                      children: [
                        Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                          await shiftMasterProvider.addShiftGroupHandleSubmit(context,formKey,addEditFlag,setdid);
                        }, isgradient: true,)),
                        widthSpacer(size.width *0.02),
                        Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () {Navigator.pop(context);},)),
                      ],
                    ),
                  ],
                ),
              )
            ),
          );
        }
      );
    },
  );
}

// Shift Timing card design 
Widget shiftTimingCard({size,titles,editOntap,deleteOntap,shotName,shiftDuration,shiftBeginTime,shiftEndTime}) {
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
                  ritchTextDesign(heading: "$designationNameString :- ",titles: shotName,headingColor: ColorConst.textHeadingColor,headingSize: 10.0,titlesSize: 9.0,textAligmnment: TextAlign.left),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: ritchTextDesign(heading: "$shiftDurationString \n",titles: shiftDuration,headingColor: ColorConst.textHeadingColor)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$shiftBeginTimeString \n",titles: shiftBeginTime,headingColor: ColorConst.textHeadingColor)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$shiftEndTimeString \n",titles: shiftEndTime,headingColor: ColorConst.textHeadingColor)),
          ],
        ),
      ],
    ),
  );
}

Widget timerDesign(size,{titles,ontaps,textColors,bgColors}) {
  return GestureDetector(
    onTap: ontaps,
    child: Container(
      width: size.width,
      height: size.height*0.07,
      padding: EdgeInsets.only(left: 7,right: 7),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: bgColors ?? ColorConst.white,
        border: Border.all(color: ColorConst.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          Expanded(child: Text(titles,style: TextStyle(fontFamily: fontInterRegularString,fontWeight: FontWeight.w500,color: textColors??ColorConst.grey),)),
          widthSpacer(size.width*0.02),
          Icon(Icons.timer_outlined,color: ColorConst.grey,)
        ],
      ),
    ),
  );
}