// ignore_for_file: deprecated_member_use, use_build_context_synchronously, strict_top_level_inference, prefer_typing_uninitialized_variables, unrelated_type_equality_checks

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/customeclass/simpleclass.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/leavemployeeprovider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class AddAdminLeaveMasterScreen extends StatefulWidget {
  final bool addEditFlag;final GetLeaveMaster? getAdminLeaveData;
  const AddAdminLeaveMasterScreen({super.key,required this.addEditFlag,required this.getAdminLeaveData,});

  @override
  State<AddAdminLeaveMasterScreen> createState() => _AddAdminLeaveMasterScreenState();
}

class _AddAdminLeaveMasterScreenState extends State<AddAdminLeaveMasterScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
  }

  final userLeaveMaterFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final leaveEmployeeeMastServices = Provider.of<LeaveEmployeeeMastServices>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor:ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(addLeaveString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            body: leaveEmployeeeMastServices.islodering ? userProfileShimmer(size) : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: userLeaveMaterFormKey,
                        autovalidateMode: leaveEmployeeeMastServices.autoLeaveMatervalidateMode,
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonTextField(controller: leaveEmployeeeMastServices.txtAdminLeaveFullNController,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterleaveTypeFullNameString,fillColors: ColorConst.white,showHeading: leaveTypeFullNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors, validator: (value) {
                              if(value!.isEmpty) {
                                return '$pleaseEnterString $designationNameString';
                              }
                              return null;
                            }),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: leaveEmployeeeMastServices.txtAdminLeaveSNameController,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterleaveTypeSortNameString,fillColors: ColorConst.white,showHeading: leaveTypeSortNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,inputformat: [LengthLimitingTextInputFormatter(5)], validator: (value) {
                              if(value!.isEmpty) {
                                return '$pleaseEnterString $designationNameString';
                              }
                              if(value.trim().length > 5) {
                                return 'Maximum 5 characters';
                              }
                              return null;
                            }),
                            heightSpacer(size.height*0.01),
                            Text(leaveLimitString, style: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500,)),
                            heightSpacer(size.height*0.01),
                            Container(
                              height: size.height*0.07,
                              decoration: BoxDecoration(color: ColorConst.white,border: Border.all(color: ColorConst.textBorder,width: 1.3,),borderRadius: BorderRadius.circular(4.0)),
                              child: DropdownButtonHideUnderline(
                                  child: DropdownButton2<TypedClass>(
                                    isExpanded: true,
                                    hint: Text(leaveEmployeeeMastServices.selectMasterselection == null ?selectLeaveLimitString: leaveEmployeeeMastServices.selectMasterselection!.values,style:TextStyle(color: leaveEmployeeeMastServices.selectMasterselection == null ?ColorConst.hintextColor: ColorConst.black,fontFamily: fontInterMediumString,fontSize: 14,),),
                                    items: leaveTypeMasters.map((TypedClass item) => DropdownItem<TypedClass>(value: item,child: Text(item.values,style: TextStyle(fontSize: size.height * 0.02,fontFamily: fontInterRegularString,fontWeight: FontWeight.w400,color: ColorConst.black,),),)).toList(),
                                    // value:leaveEmployeeeMastServices.selectMasterselection,
                                    onChanged: (TypedClass? value) {leaveEmployeeeMastServices.ontapSelections(value);},
                                    selectedItemBuilder: (context) {
                                      return leaveTypeMasters.map((item) {
                                        return Row(
                                          children: [
                                            Expanded(child: Align(alignment: Alignment.centerLeft,child: Text(item.values,style: TextStyle(fontSize: size.height * 0.021,fontFamily: fontInterBoldString,color: ColorConst.black,fontWeight: FontWeight.w600,),),)),
                                            widthSpacer(size.width*0.02),
                                            InkWell(onTap: (){leaveEmployeeeMastServices.iconAddOntap(context);},child: Icon(Icons.close,size: 15,color: ColorConst.black,))
                                          ],
                                        );
                                      }).toList();
                                    },
                                  // menuItemStyleData: MenuItemStyleData(
                                  //   height: size.height * 0.05,
                                  // ),
                                ),
                              ),
                            ),
                            heightSpacer(size.height*0.01),
                            if(leaveEmployeeeMastServices.selectMasterselection != null) ...[
                              CommonTextField(controller: leaveEmployeeeMastServices.txtAdminLeaveLimitController,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: leaveEmployeeeMastServices.selectMasterselection!.keys == "Monthly" ? "$enterString $monthlyLimitString" : leaveEmployeeeMastServices.selectMasterselection!.keys == "Quarterly" ? "$enterString $quarterlyLimitString" : leaveEmployeeeMastServices.selectMasterselection!.keys == "HalfYearly" ?  "$enterString $halfYearlyString" :  "$enterString $yearlyLimitString",fillColors: ColorConst.white,showHeading: leaveEmployeeeMastServices.selectMasterselection!.keys == "Monthly" ? monthlyLimitString : leaveEmployeeeMastServices.selectMasterselection!.keys == "Quarterly" ? quarterlyLimitString : leaveEmployeeeMastServices.selectMasterselection!.keys == "HalfYearly" ?halfYearlyString:yearlyLimitString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [ FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(2),],),
                            ],
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: leaveEmployeeeMastServices.txtAdminPolicyDateController,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),readOnly: true,hintText: selectPolicyIssueDateString,suffixIcon: IgnorePointer(child: IconButton(onPressed: (){}, icon: Icon(Icons.calendar_today_outlined,color: ColorConst.passwordColor,),)),showHeading: policyIssueDateString,hintColor: ColorConst.hintextFormColors,fillColors: ColorConst.white,onTap: () {
                              leaveEmployeeeMastServices.selectDatePicker(context,size,dateController: datePickerProvider,selectDatePic: leaveEmployeeeMastServices.leavePolicyDate,).then((value) {
                                leaveEmployeeeMastServices.leavePolicyDate = value;
                                leaveEmployeeeMastServices.txtAdminPolicyDateController.text = dateFormatdate(leaveEmployeeeMastServices.leavePolicyDate);
                              },);
                            },),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: leaveEmployeeeMastServices.txtAdminLeaveDesController,showTextStyle: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),hintText: enterDescriptionString,fillColors: ColorConst.white,showHeading: descriptionString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,maxLines: 3,),
                            heightSpacer(size.height*0.01),
                            Row(
                              children: [
                                Checkbox(value: leaveEmployeeeMastServices.considerWeeklyOffValue, onChanged: (val){leaveEmployeeeMastServices.selectConsiderWeeklyOffValue(val);},materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,visualDensity: VisualDensity.compact,),
                                Text(considerWeeklyString,style: normalHeadingText(size),),
                                widthSpacer(size.width*0.01),
                                Checkbox(value: leaveEmployeeeMastServices.considerHolidayValue, onChanged: (val){leaveEmployeeeMastServices.selectConsiderHolidayValue(val);},materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,visualDensity: VisualDensity.compact,),
                                Text(considerHolidayString,style: normalHeadingText(size),),
                              ],
                            ),
                            heightSpacer(size.height*0.01),
                            Row(
                              children: [
                                Radio(activeColor: ColorConst.themeColor,value: paidLeaveString.toString().split(" ").first.toString(), groupValue: leaveEmployeeeMastServices.selectedLeaveType, onChanged: (val){leaveEmployeeeMastServices.selectLeaveType(val);},materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,visualDensity: VisualDensity.compact,),
                                Text(paidLeaveString,style: normalHeadingText(size),),
                                Radio(activeColor: ColorConst.themeColor,value: unPaidLeaveString.toString().split(" ").first.toString(), groupValue: leaveEmployeeeMastServices.selectedLeaveType, onChanged: (val){leaveEmployeeeMastServices.selectLeaveType(val);},materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,visualDensity: VisualDensity.compact,),
                                Text(unPaidLeaveString,style: normalHeadingText(size),),
                              ],
                            ),
                          ],
                        ) 
                      ),
                    ),
                  ),
                  heightSpacer(size.height *0.02),
                  Row(
                    children: [
                      Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                        await leaveEmployeeeMastServices.adminLeaveHandleSubmit(context, userLeaveMaterFormKey, widget.addEditFlag, widget.addEditFlag?"":widget.getAdminLeaveData);
                      }, isgradient: true,)),
                      widthSpacer(size.width *0.02),
                      Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () async {Navigator.pop(context);},)),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
