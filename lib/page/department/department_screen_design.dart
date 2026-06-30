// ignore_for_file: strict_top_level_inference

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/spacer.dart';

// Designation design 
void showAddDesignationDialog(BuildContext context,formKey,addEditFlag,{size,setdid}) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
      return Consumer<PositionMasterService>(
        builder: (context, designationServices, child) {      
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
                autovalidateMode: designationServices.autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addDesignationString,style: TextStyle(color: ColorConst.black,fontSize: 20,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600),),
                    heightSpacer(size.height *0.02),
                    Text(departmentNameString,style: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),),
                    heightSpacer(size.height *0.02),
                    CustomDropdown<DepartMnetModel>.searchRequest(
                      decoration: CustomDropdownDecoration(
                        expandedBorder: Border.all(color: ColorConst.black),
                        closedBorder: Border.all(color: Colors.black45)
                      ),
                      initialItem: designationServices.selectedDepartment,
                      validator: (val){
                        if (val == null) {
                          return 'Please Select Department Name';
                        }
                        return null;
                      },
                      hintText: selectDepartmentNameString,
                      futureRequest: (value) => context.read<DepartmentServices>().getFilterDepartment(value),
                      items: context.read<DepartmentServices>().activepartment,
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
                        return Text(item.departmentName.toString());
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(designationServices.selectedDepartment == null ? selectDepartmentNameString : designationServices.selectedDepartment!.departmentName.toString());
                      },
                      onChanged: (value) {
                        designationServices.depatmentontap(value);
                      },
                    ),
                    heightSpacer(size.height *0.02),
                    CommonTextField(controller: designationServices.designationnamecontroller,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterDesignationNameString,fillColors: ColorConst.white,showHeading: designationNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors, validator: (value) {
                      if(value!.isEmpty) {
                        return '$pleaseEnterString $designationNameString';
                      }
                      return null;
                    }),
                    heightSpacer(size.height *0.02),
                    Text(statusString,style: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),textAlign: TextAlign.start,),
                    heightSpacer(size.height *0.005),
                    activeAnmdInactiveDesign(size, designationServices.designationStatus, (value){
                      designationServices.handleChangeValue(value);
                    }),
                    heightSpacer(size.height *0.02),
                    Row(
                      children: [
                        Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                          final paginationProvider = context.read<AppPaginationProvider>();
                          await designationServices.addDesignationHandleSubmit(context,formKey,addEditFlag,setdid).then((value) async {
                            if(addEditFlag){
                              await paginationProvider.countPaginationPage(designationServices.showPositions,0,);
                            }
                          },);
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

// department design 
void showAddDepartmentDialog(BuildContext context,formKey,addEditFlag,{size,setdid}) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
      return Consumer<DepartmentServices>(
        builder: (context, departmentServices, child) {      
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
                autovalidateMode: departmentServices.autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addDepartmentString,style: TextStyle(color: ColorConst.black,fontSize: 20,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600),),
                    heightSpacer(size.height *0.02),
                    CommonTextField(controller: departmentServices.departmentnamecontroller,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterDepartmentNameString,fillColors: ColorConst.white,showHeading: departmentNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors, validator: (value) {
                      if(value!.isEmpty) {
                        return '$pleaseEnterString $departmentNameString';
                      }
                      return null;
                    }),
                    heightSpacer(size.height *0.02),
                    Text(statusString,style: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),textAlign: TextAlign.start,),
                    heightSpacer(size.height *0.005),
                    activeAnmdInactiveDesign(size, departmentServices.departmentStatus, (value){
                      departmentServices.handleChangeValue(value);
                    }),
                    heightSpacer(size.height *0.02),
                    Row(
                      children: [
                        Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                          final paginationProvider = context.read<AppPaginationProvider>();
                          await departmentServices.addDepartHandleSubmit(context,formKey,addEditFlag,setdid).then((value) async {
                            if(addEditFlag){
                              await paginationProvider.countPaginationPage(departmentServices.showedepartment,0,);
                            }
                          },);
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

// department card design 
Widget departmentCard(designationFlag,{size,titles,editOntap,deleteOntap,borderColor,departmentName}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: ColorConst.white,
      border: Border.all(color: borderColor ??ColorConst.transparent,width: 1.5),
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

            iconBtn(Icons.edit, ColorConst.themeColor,editOntap),
            widthSpacer(size.width *0.02),
            iconBtn(Icons.delete, ColorConst.redDarkColors,deleteOntap),
          ],
        ),
        if(!designationFlag)...[
          heightSpacer(size.height *0.01),
          Text(
            departmentName,
            style: TextStyle(fontSize: size.height * 0.014,fontWeight: FontWeight.w300,fontFamily: fontInterRegularString),
          ),  
        ],
      ],
    ),
  );
}

// icons module design
Widget iconBtn(IconData icon, Color color,Function()? ontap,{double? height, double? width, double? iconSize}) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      height: height ?? 36,
      width: width ?? 36,
      decoration: BoxDecoration(
        border: Border.all(color: ColorConst.iconBorderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: iconSize??22, color: color),
    ),
  );
}
