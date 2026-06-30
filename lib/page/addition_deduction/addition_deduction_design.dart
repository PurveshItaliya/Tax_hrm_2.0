// ignore_for_file: strict_top_level_inference

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/provider/additionprovider.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/spacer.dart';

// addition Deduction card design 

Widget additionDeductionCard({size,editOntap,deleteOntap,titles,hraValue,daValue,pfValue,tdsValue}) {
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
              child: Text(
                titles,
                style: TextStyle(fontSize: 15,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString),
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
            Expanded(child: ritchTextDesign(heading: "$hraString :-",titles: hraValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$daString :-",titles: daValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start)),
          ],
        ),
        Row(
          children: [
            Expanded(child: ritchTextDesign(heading: "$pfString :-",titles: pfValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$tdsString :-",titles: tdsValue,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start)),
          ],
        ),
      ],
    ),
  );
}

// addtext and  checkBox

Widget addTextAndPercentageDesign(context,size,{titles,checkBoxValue,checkBoxOnChange}) {
  return Row(
    children: [
      Text("$titles :-", style: TextStyle(fontFamily: fontInterBoldString)),
      Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Checkbox(
          activeColor: ColorConst.themeColor,
          value: checkBoxValue,
          onChanged: checkBoxOnChange,
        ),
      ),
      Text(
        inPercentageString,
        style:TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: size.height*0.017),
      ),
    ],
  );
}

// add addition Deduction card design

Widget addadditionDeductionCardDesign({size,editOntap,deleteOntap,titles,date,type,amount,remark}) {
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
                  ritchTextDesign(heading: "$dateString :- ",titles: date,headingColor: ColorConst.textHeadingColor,headingSize: 10.0,titlesSize: 9.0,textAligmnment: TextAlign.left),
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
            Expanded(child: ritchTextDesign(heading: "$typeString :- ",titles: type,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start)),
            widthSpacer(5.0),
            Expanded(child: ritchTextDesign(heading: "$amountString :- ",titles: amount,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start)),
          ],
        ),
        ritchTextDesign(heading: "$eventRemarkString :- ",titles: remark,headingColor: ColorConst.textHeadingColor,textAligmnment: TextAlign.start),
      ],
    ),
  );
}

// add addition deductionDialog design 
void additiondeductionSelectDialog(BuildContext context,{size,datePickerProvider,addEditFlag,index}) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
      return Consumer<AdditionProvider>(
        builder: (context, additionProvider, child) {      
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              width: size.width,
              height: size.height * 0.7,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(addAdditionDeductionString,style: TextStyle(color: ColorConst.black,fontSize: 18,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600),),
                  heightSpacer(size.height *0.01),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${employessNameString.toString().split(" ").first} ", style: normalHeadingText(size)),
                          heightSpacer(size.height * 0.01),
                          IgnorePointer(
                            child: CustomDropdown<Employeelists>.searchRequest(
                              decoration: CustomDropdownDecoration(
                                expandedBorder: Border.all(color: ColorConst.textBorder),
                                closedBorder: Border.all(color: ColorConst.textBorder),
                                closedBorderRadius: BorderRadius.circular(4.0),
                                expandedBorderRadius: BorderRadius.circular(4.0),
                                closedFillColor: ColorConst.transparent,
                                expandedFillColor: ColorConst.white,
                              ),
                              initialItem: additionProvider.selectedEmployeeList,
                              hintText: selectConductedByString,
                              futureRequest:  Provider.of<EmployeMastServices>(context,listen: false).getFilterEmployeeby,items: additionProvider.employesDataList,
                              listItemBuilder: (context, item, isSelected, onItemSelect) {
                                return Text("${item.firstName.toString()} ${item.lastName.toString()}");
                              },
                              headerBuilder: (context, selectedItem, enabled) {
                                return Text(additionProvider.selectedEmployeeList == null ? selectConductedByString : "${additionProvider.selectedEmployeeList!.firstName.toString()} ${additionProvider.selectedEmployeeList!.lastName.toString()}");
                              },
                              onChanged: (value) {},
                            ),
                          ),
                          heightSpacer(size.height*0.01),
                          Text(typeString, style: normalHeadingText(size)),
                          heightSpacer(size.height * 0.01),
                          CustomDropdown(
                            initialItem: additionProvider.selectType,
                            items: additionProvider.selectAdditionSelect,
                            decoration: CustomDropdownDecoration(
                              expandedBorder: Border.all(color: ColorConst.textBorder),
                              closedBorder: Border.all(color: ColorConst.textBorder),
                              closedBorderRadius: BorderRadius.circular(4.0),
                              expandedBorderRadius: BorderRadius.circular(4.0),
                              closedFillColor: ColorConst.transparent,
                              expandedFillColor: ColorConst.white,
                            ),
                            headerBuilder: (context, selectedItem, enabled) {
                              return Text(additionProvider.selectType,);
                            },
                            onChanged: (value) {
                              additionProvider.selectTypeontap(value);
                            },
                          ),
                          heightSpacer(size.height*0.01),
                          CommonTextField(controller: additionProvider.txtAmountController,hintText: enterAmountString,showHeading: amountString,keyboardType: TextInputType.number,
                            inputformat: [FilteringTextInputFormatter.digitsOnly,],
                          ),
                          
                          heightSpacer(size.height*0.01),
                          CommonTextField(controller: additionProvider.txtdateController,readOnly: true,hintText: selectDateString,suffixIcon: IgnorePointer(child: IconButton(onPressed: (){}, icon: Icon(Icons.calendar_today_outlined,color: ColorConst.passwordColor,),)),showHeading: dateString,onTap: () {
                            additionProvider.selectDatePicker(context,size,dateController: datePickerProvider,selectDatePic: additionProvider.selectDate,).then((value) {
                                additionProvider.selectDate = value;
                                additionProvider.txtdateController.text = dateFormatdate(additionProvider.selectDate);
                              },);
                            },
                          ),
                          heightSpacer(size.height*0.01),
                          CommonTextField(controller: additionProvider.txtRemarkController,hintText: enterEventRemarksString,showHeading: eventRemarkString,maxLines: 3,),
                          heightSpacer(size.height*0.01),
                        ],
                      ),
                    ),
                  ),
                  heightSpacer(size.height *0.02),
                  Row(
                    children: [
                      Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                        additionProvider.btnAddAdditionDeduction(context,addEditFlag,index);
                      }, isgradient: true,)),
                      widthSpacer(size.width *0.02),
                      Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () {Navigator.pop(context);},)),
                    ],
                  ),
                ],
              )
            ),
          );
        }
      );
    },
  );
}