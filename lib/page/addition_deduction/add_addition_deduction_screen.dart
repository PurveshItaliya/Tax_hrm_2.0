// ignore_for_file: deprecated_member_use, use_build_context_synchronously, strict_top_level_inference, prefer_typing_uninitialized_variables

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/additions/additem.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/page/addition_deduction/addition_deduction_design.dart';
import 'package:tax_hrm/provider/additionprovider.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class AddAdditionDeductionScreen extends StatefulWidget {
  final bool addEditFlag;final getAdditionData;
  const AddAdditionDeductionScreen({super.key,required this.addEditFlag,required this.getAdditionData});

  @override
  State<AddAdditionDeductionScreen> createState() => _AddAdditionDeductionScreenState();
}

class _AddAdditionDeductionScreenState extends State<AddAdditionDeductionScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<AdditionProvider>(context,listen: false,).addEditFunction(context,widget.addEditFlag,getAdditionData: widget.getAdditionData);
  }

  final userAdditionDeductionFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final additionProvider = Provider.of<AdditionProvider>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor:ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(additionOrDeductionString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            body: additionProvider.islodering ? userProfileShimmer(size) : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: userAdditionDeductionFormKey,
                        autovalidateMode: additionProvider.autoAdditionDeductionvalidateMode,
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$employessNameString :-", style: normalHeadingText(size)),
                            heightSpacer(size.height * 0.01),
                            IgnorePointer(
                              ignoring: widget.addEditFlag ?false:true,
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
                                validator: (val){
                                  if (val == null) {
                                    return 'Please Select Employee Name';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  additionProvider.employessontap(value);
                                },
                              ),
                            ),
                            heightSpacer(size.height*0.01),
                            SizedBox(
                              height: size.height * 0.06,
                              width: size.width,
                              child: MaterialSegmentedControl(
                                horizontalPadding: EdgeInsets.zero,
                                children: additionProvider.options,
                                selectionIndex: additionProvider.currentSelection,
                                borderColor: ColorConst.themeColor,
                                selectedColor:ColorConst.themeColor,
                                unselectedColor: ColorConst.white,
                                selectedTextStyle: TextStyle(color: ColorConst.white,fontSize: size.height * 0.02,fontWeight: FontWeight.bold),
                                unselectedTextStyle: TextStyle(color: ColorConst.themeColor,fontSize: size.height * 0.02,fontWeight: FontWeight.bold),
                                borderWidth: 0.7,
                                borderRadius: 10.0,
                                onSegmentTapped: (index) {
                                  additionProvider.ontabMaterioal(index);
                                },
                              ),
                            ),
                            if(additionProvider.currentSelection == 0)...[
                              addTextAndPercentageDesign(context, size,titles: hraString,checkBoxValue: additionProvider.hraValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxhrmValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txthraController,hintText: additionProvider.hintTextValue(hraString,additionProvider.hraValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                              addTextAndPercentageDesign(context, size,titles: daString,checkBoxValue: additionProvider.daValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxdaValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtdaController,hintText: additionProvider.hintTextValue(daString,additionProvider.daValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                              addTextAndPercentageDesign(context, size,titles: conveyanceString,checkBoxValue: additionProvider.conveyanceValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxconveyanceValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtConveyanceController,hintText: additionProvider.hintTextValue(conveyanceString,additionProvider.conveyanceValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                              addTextAndPercentageDesign(context, size,titles: specialAllowanceString,checkBoxValue: additionProvider.specialAllowanceValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxspecialAllowanceValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtSpecialAllowanceController,hintText: additionProvider.hintTextValue(specialAllowanceString,additionProvider.specialAllowanceValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                              addTextAndPercentageDesign(context, size,titles: medicalAllowanceString,checkBoxValue: additionProvider.medicalAllowanceValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxmedicalAllowanceValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtMedicalAllowanceController,hintText: additionProvider.hintTextValue(medicalAllowanceString,additionProvider.medicalAllowanceValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                            ] else ...[
                              addTextAndPercentageDesign(context, size,titles: pfString,checkBoxValue: additionProvider.pfValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxpfValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtPfController,hintText: additionProvider.hintTextValue(pfString,additionProvider.pfValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                              addTextAndPercentageDesign(context, size,titles: esicString,checkBoxValue: additionProvider.esicValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxesicValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtEsicController,hintText: additionProvider.hintTextValue(esicString,additionProvider.esicValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                              addTextAndPercentageDesign(context, size,titles: tdsString,checkBoxValue: additionProvider.tdsValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxtdsValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtTdsController,hintText: additionProvider.hintTextValue(tdsString,additionProvider.tdsValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                              addTextAndPercentageDesign(context, size,titles: professionalTaxString,checkBoxValue: additionProvider.professionalTaxValue,checkBoxOnChange: (value) {
                                additionProvider.checkBoxprofessionalTaxValueChange(value,);
                              }),
                              CommonTextField(controller: additionProvider.txtProfessionalTaxController,hintText: additionProvider.hintTextValue(professionalTaxString,additionProvider.professionalTaxValue),keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputformat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'),),LengthLimitingTextInputFormatter(6),],
                              ),
                              heightSpacer(size.height*0.01),
                            ],
                            btnDesign(size,titles: addAdditionDeductionString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () {
                              additionProvider.addHandleAdditionCardDesign(context,size: size,formKey: userAdditionDeductionFormKey,datePickerProvider: datePickerProvider);
                            },fontSizes: size.height*0.019,height: size.height*0.05),
                            heightSpacer(size.height*0.01),
                            additionList.isEmpty ? SizedBox() : 
                            ListView.builder(
                              itemCount: additionList.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.only(bottom: size.height * 0.075),
                              itemBuilder: (context, index) {
                                return addadditionDeductionCardDesign(size: size,titles: '${additionProvider.selectedEmployeeList!.firstName  ?? ''} ${additionProvider.selectedEmployeeList!.lastName  ?? ''}',date: additionList[index].date,amount: additionList[index].amount.toString(),type: additionList[index].type,remark: additionList[index].remarks,deleteOntap: () {
                                  additionProvider.removeadditionValue(index);
                                },editOntap: () {
                                  additionProvider.editadditionValue(index,context,size,datePickerProvider);
                                });
                              },
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
                        await additionProvider.handleSubmit(context, userAdditionDeductionFormKey, widget.addEditFlag, widget.addEditFlag?"":widget.getAdditionData);
                      }, isgradient: true,)),
                      widthSpacer(size.width *0.02),
                      Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () async {await additionProvider.clearDialogData();Navigator.pop(context);},)),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
