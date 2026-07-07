// ignore_for_file: unused_local_variable, use_build_context_synchronously, prefer_if_null_operators

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/models/shiftclass/shiftgroup/getallshifts.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/page/department/Department_master_screen.dart';
import 'package:tax_hrm/page/department/designation_master_screen.dart';
import 'package:tax_hrm/page/shift/shift_master_screen.dart';
import 'package:tax_hrm/page/shift/shift_mater_design.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class AddShiftTimingMasterScreen extends StatefulWidget {
  final GetShiftMasterData? getShiftMasterData;
  final bool addEditFlag;
  const AddShiftTimingMasterScreen({super.key,required this.getShiftMasterData, required this.addEditFlag});

  @override
  State<AddShiftTimingMasterScreen> createState() => _AddShiftTimingMasterScreenState();
}

class _AddShiftTimingMasterScreenState extends State<AddShiftTimingMasterScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<ShiftMasterProvider>(context,listen: false).islodering = true;
    await Provider.of<DepartmentServices>(context,listen: false).getDepartmentMasterData();
    await Provider.of<PositionMasterService>(context,listen: false,).designatiionLoadingData();
    await Provider.of<ShiftMasterProvider>(context,listen: false).shiftGroupMasterLoadingData();
  }

  final userShiftTimingFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final shiftTiminigMasterProvider =  Provider.of<ShiftMasterProvider>(context);
    final appPaginationController = Provider.of<AppPaginationProvider>(context);
    final positionMasterService = Provider.of<PositionMasterService>(context);
    return checkInterNetConnection.connectionType == 0
      ? const NoInternetViewPage()
      : Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(newShiftMasterString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);},),
            body: shiftTiminigMasterProvider.islodering ? userProfileShimmer(size) : Padding(
                padding: EdgeInsets.all(size.height*0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: userShiftTimingFormKey,
                          autovalidateMode: shiftTiminigMasterProvider.autoShiftTimingvalidateMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("$shiftFullNameString :", style: normalHeadingText(size)),
                              heightSpacer(size.height * 0.01),
                              IgnorePointer(
                                ignoring: widget.addEditFlag ? false : true,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppSearchableDropdown<ShiftGroup>(
                                        dropdownKey: ValueKey(shiftTiminigMasterProvider.selectedShiftGroup),
                                        initialItem: shiftTiminigMasterProvider.selectedShiftGroup,
                                        validator: (val){
                                          if (val == null) {
                                            return 'Please Select Shift Full Name';
                                          }
                                          return null;
                                        },
                                        hintText: selectShiftFullNameString,
                                        futureRequest: shiftTiminigMasterProvider.getFilterShiftGroup,
                                        items: shiftTiminigMasterProvider.mainShiftGroupList,
                                        itemAsString: (item) => item.shiftGroupFname.toString(),
                                        headerBuilder: (context, selectedItem, enabled) {
                                          return Text(shiftTiminigMasterProvider.selectedShiftGroup == null ? selectShiftFullNameString : shiftTiminigMasterProvider.selectedShiftGroup!.shiftGroupFname.toString());
                                        },
                                        onChanged: (value) {
                                          shiftTiminigMasterProvider.shiftFullNameontap(value);
                                        },
                                      ),
                                    ),
                                    widthSpacer(size.width*0.02),
                                    addIconSetData(size, () {nextScreen(context, ShiftMasterScreen(), onthenValue: (value) {});})
                                  ],
                                ),
                              ),
                              heightSpacer(size.height * 0.01),
                              Text("$shiftShortNameString :", style: normalHeadingText(size)),
                              heightSpacer(size.height * 0.01),
                              CommonTextField(controller: shiftTiminigMasterProvider.addShiftSNcontroller,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterShiftShortNameString,fillColors: ColorConst.white,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,readOnly: true,),
                              heightSpacer(size.height * 0.01),
                              Text("$departmentString :", style: normalHeadingText(size)),
                              heightSpacer(size.height * 0.01),
                              IgnorePointer(
                                ignoring: widget.addEditFlag ? false : true,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppSearchableDropdown<DepartMnetModel>(
                                        dropdownKey: ValueKey(shiftTiminigMasterProvider.selectedDepartment),
                                        initialItem: shiftTiminigMasterProvider.selectedDepartment,
                                        validator: (val){
                                          if (val == null) {
                                            return 'Please Select Department Name';
                                          }
                                          return null;
                                        },
                                        hintText: selectDepartmentNameString,
                                        futureRequest: context.read<DepartmentServices>().getFilterDepartment,
                                        items: context.read<DepartmentServices>().activepartment,
                                        itemAsString: (item) => item.departmentName.toString(),
                                        headerBuilder: (context, selectedItem, enabled) {
                                          return Text(shiftTiminigMasterProvider.selectedDepartment == null ? selectDepartmentNameString : shiftTiminigMasterProvider.selectedDepartment!.departmentName.toString());
                                        },
                                        onChanged: (value) {
                                          shiftTiminigMasterProvider.depatmentontap(value,positionMasterService);
                                        },
                                      ),
                                    ),
                                    widthSpacer(size.width*0.02),
                                    addIconSetData(size, () {nextScreen(context, DepartmentScreen(),onthenValue: (val){},);})
                                  ],
                                ),
                              ),
                              heightSpacer(size.height * 0.01),
                              Text("$designationString :", style: normalHeadingText(size)),
                              heightSpacer(size.height * 0.01),
                              IgnorePointer(
                                ignoring: widget.addEditFlag ? false : true,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppSearchableDropdown<PositionDataL>(
                                        dropdownKey: ValueKey(shiftTiminigMasterProvider.selectedDesignation),
                                        initialItem: shiftTiminigMasterProvider.selectedDesignation,
                                        validator: (val){
                                          if (val == null) {
                                            return 'Please Select Designation Name';
                                          }
                                          return null;
                                        },
                                        hintText: selectDesignationNameString,
                                        futureRequest: shiftTiminigMasterProvider.getFilterDesignation,
                                        items: shiftTiminigMasterProvider.getFiltersPostionList,
                                        itemAsString: (item) => item.positionName.toString(),
                                        headerBuilder: (context, selectedItem, enabled) {
                                          return Text(shiftTiminigMasterProvider.selectedDesignation == null ? selectDesignationNameString : shiftTiminigMasterProvider.selectedDesignation!.positionName.toString());
                                        },
                                        onChanged: (value) {
                                          shiftTiminigMasterProvider.designationontap(value);
                                        },
                                      ),
                                    ),
                                    widthSpacer(size.width*0.02),
                                    addIconSetData(size, () {nextScreen(context, DesignationScreen(),onthenValue: (val){},);}),
                                  ],
                                ),
                              ),
                              heightSpacer(size.height * 0.01),
                              Text("$selectWorkDaysString :", style: normalHeadingText(size)),
                              heightSpacer(size.height * 0.01),
                              Wrap(
                                spacing: size.width * 0.02,      // horizontal space
                                runSpacing: size.height * 0.015, // vertical space
                                children: List.generate(
                                  shiftTiminigMasterProvider.daysOfWeek.length,
                                  (index) {
                                    return GestureDetector(
                                      onTap: () {
                                        shiftTiminigMasterProvider.selectWeekDay(index);
                                      },
                                      child: Container(
                                        width: size.width * 0.15,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.black38),borderRadius: BorderRadius.circular(4.0),color: shiftTiminigMasterProvider.checkBoxValues[index]? ColorConst.themeColor: ColorConst.white,),
                                        child: Center(
                                          child: Text(
                                            shiftTiminigMasterProvider.daysOfWeek[index],
                                            style: TextStyle(
                                              color: shiftTiminigMasterProvider.checkBoxValues[index]? ColorConst.white: ColorConst.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: size.height * 0.02,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if(shiftTiminigMasterProvider.selectWeekDayValue)...[
                                Text(errorWorkingString,style: TextStyle(fontSize: 12,color: ColorConst.redDarkColors,fontWeight: FontWeight.w400),),
                              ],
                              heightSpacer(size.height * 0.01),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("$shiftBeginTimeString :", style: normalHeadingText(size)),
                                        heightSpacer(size.height * 0.01),
                                        timerDesign(size,ontaps: () async {
                                          await shiftTiminigMasterProvider.timerHadleSubmit(context,true);
                                        },titles: shiftTiminigMasterProvider.pickedBeginTime.format(context) ,textColors: ColorConst.black),
                                      ],
                                    ),
                                  ),
                                  widthSpacer(size.width*0.02),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("$shiftEndTimeString :", style: normalHeadingText(size)),
                                        heightSpacer(size.height * 0.01),
                                        timerDesign(size,ontaps: () async {
                                          await shiftTiminigMasterProvider.timerHadleSubmit(context,false);
                                        },titles: shiftTiminigMasterProvider.pickedEndTime.format(context),textColors: ColorConst.black),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              heightSpacer(size.height * 0.01),
                              Text("$shiftDurationString :", style: normalHeadingText(size)),
                              heightSpacer(size.height * 0.01),
                              CommonTextField(controller: shiftTiminigMasterProvider.addShiftDurationcontroller,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterShiftShortNameString,fillColors: ColorConst.white,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,readOnly: true,),
                              heightSpacer(size.height * 0.01),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              activeColor: ColorConst.themeColor,
                                              value: shiftTiminigMasterProvider.break1Value,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                              onChanged: (val) {
                                                shiftTiminigMasterProvider.breakBoolValue(val, true);
                                              },
                                            ),
                                            widthSpacer(size.width * 0.01),
                                            Text("$break1String :", style: normalHeadingText(size)),
                                          ],
                                        ),
                                        heightSpacer(size.height * 0.01),
                                        timerDesign(size,ontaps: () async {
                                          if(shiftTiminigMasterProvider.break1Value) {
                                            await shiftTiminigMasterProvider.breaktimerHadleSubmit(context,true);
                                          }
                                        },titles: "${shiftTiminigMasterProvider.pickedBreak1Time.hour.toString().padLeft(2, '0')}:${shiftTiminigMasterProvider.pickedBreak1Time.minute.toString().padLeft(2, '0')}:${shiftTiminigMasterProvider.pickbreak1Seconds.toString().padLeft(2, '0')}",textColors: shiftTiminigMasterProvider.break1Value?ColorConst.black:ColorConst.grey,bgColors: shiftTiminigMasterProvider.break1Value?ColorConst.white:ColorConst.greyColor),
                                      ],
                                    ),
                                  ),
                                  widthSpacer(size.width*0.02),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              activeColor: ColorConst.themeColor,
                                              value: shiftTiminigMasterProvider.break2Value,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                              onChanged: (val) {
                                                shiftTiminigMasterProvider.breakBoolValue(val, false);
                                              },
                                            ),
                                            widthSpacer(size.width * 0.01),
                                            Text("$break2String :", style: normalHeadingText(size)),
                                          ],
                                        ),
                                        heightSpacer(size.height * 0.01),
                                        timerDesign(size,ontaps: () async {
                                          if(shiftTiminigMasterProvider.break2Value) {
                                            await shiftTiminigMasterProvider.breaktimerHadleSubmit(context,false);
                                          }
                                        },titles: "${shiftTiminigMasterProvider.pickedBreak2Time.hour.toString().padLeft(2, '0')}:${shiftTiminigMasterProvider.pickedBreak2Time.minute.toString().padLeft(2, '0')}:${shiftTiminigMasterProvider.pickbreak2Seconds.toString().padLeft(2, '0')}",textColors: shiftTiminigMasterProvider.break2Value?ColorConst.black:ColorConst.grey,bgColors: shiftTiminigMasterProvider.break2Value?ColorConst.white:ColorConst.greyColor),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              heightSpacer(size.height * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    heightSpacer(size.height*0.02),
                    Row(
                      children: [
                        Expanded(child: btnDesign(size,titles: saveString,onTap: () {
                          shiftTiminigMasterProvider.handleSubmit(context,userShiftTimingFormKey,widget.addEditFlag,widget.addEditFlag ?"":widget.getShiftMasterData);
                        }, isgradient: true,height: size.height*0.06,fontSizes: 12.0)),
                        widthSpacer(size.width *0.02),
                        Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () {Navigator.pop(context);},height: size.height*0.06,fontSizes: 12.0)),
                      ],
                    ),
                  ],
                )
            ),
          );
  }
}
