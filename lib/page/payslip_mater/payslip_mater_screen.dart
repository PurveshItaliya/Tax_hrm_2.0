// ignore_for_file: strict_top_level_inference, use_build_context_synchronously

import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/page/payslip_mater/payslip_mater_design.dart';
import 'package:tax_hrm/page/payslip_mater/view_payslip_screen.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/payslipprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class PaySlipMaterScreen extends StatefulWidget {
  const PaySlipMaterScreen({super.key});

  @override
  State<PaySlipMaterScreen> createState() => _PaySlipMaterScreenState();
}

class _PaySlipMaterScreenState extends State<PaySlipMaterScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  _loadAllData() async {
    Provider.of<PaySlipProviders>(context, listen: false).setloading(true);
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    Provider.of<EmployeMastServices>(context,listen: false).getAllEmployesData();
    Provider.of<PaySlipProviders>(context, listen: false).loadingData(0,true);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final paySlipProviders = Provider.of<PaySlipProviders>(context);
    Provider.of<LanguageProvider>(context);
    safeAreaBgAndTextColor(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(paySlipString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            body: refreshIndicatorDesign(
              onRefreshOntap: () {
                return _loadAllData();
              },
              widgetDesign: paySlipProviders.isloderings ? payslipMasterShimmer(size) 
                : Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectEmployeeString, style: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500,fontSize: 14)),
                      heightSpacer(size.height*0.02),
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchableDropdown<Employeelists>(
                              dropdownKey: ValueKey(paySlipProviders.selectedEmployeeList),
                              initialItem: paySlipProviders.selectedEmployeeList,
                              hintText: selectEmployeeNameString,
                              futureRequest:  Provider.of<EmployeMastServices>(context,listen: false).getFilterEmployeeList,
                              items: Provider.of<EmployeMastServices>(context,listen: false).emplists,
                              itemAsString: (item) => "${item.firstName.toString()} ${item.lastName.toString()}",
                              headerBuilder: (context, selectedItem, enabled) {
                                return paySlipProviders.selectedEmployeeList == null?Text(selectEmployeeNameString):Row(
                                  children: [
                                    Expanded(child: Text("${paySlipProviders.selectedEmployeeList!.firstName.toString()} ${paySlipProviders.selectedEmployeeList!.lastName.toString()}")),
                                    widthSpacer(size.width*0.02),
                                    InkWell(onTap: (){
                                      paySlipProviders.iconOntap();
                                    },child: Icon(Icons.close,size: 15,color: ColorConst.black,))
                                  ],
                                );
                              },
                              onChanged: (value) {
                                paySlipProviders.employessontap(value);
                              },
                            ),
                          ),
                          widthSpacer(size.width*0.02),
                          addIconSetData(size, (){
                            datePickerProvider.selectMonthYear(context, paySlipProviders.paySlipcurrentMonth, (value) {
                              paySlipProviders.updateMonth(value, context);
                            },);
                          },iconsName: Icons.calendar_month,bgColor: ColorConst.transparent,borderColors: ColorConst.textBorder,iconsColor: ColorConst.textgrey)
                        ],
                      ),
                      heightSpacer(size.height*0.012),
                      Text(
                        dateFormatMMMyyyy(paySlipProviders.paySlipcurrentMonth),
                        style: TextStyle(fontSize: 15,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString,color: ColorConst.textHeadingColor),
                      ),
                      heightSpacer(size.height*0.012),
                      paySlipProviders.showPaySlips.isEmpty
                        ? Expanded(child: SingleChildScrollView(child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString)))) 
                        : Expanded(
                          child: ListView.builder(
                            itemCount: paySlipProviders.showPaySlips.length,
                            padding: EdgeInsets.only(bottom: size.height * 0.01),
                            itemBuilder: (context, index) {
                              return paySlipMasterCardDesign(size: size,titles: paySlipProviders.showPaySlips[index].empName,paySlipOntap: () {
                                nextScreen(context, ViewPaySlipScreen(getPaySlipData: paySlipProviders.showPaySlips[index]),onthenValue: (value) {});
                              },deleteOntap: () {
                                 showDeleteDialog(context,size,yesOntap: () {paySlipProviders.deletePaySlipMaster(context,payslipcguid: paySlipProviders.showPaySlips[index].cguid,);},noOnTap: (){Navigator.pop(context);});
                              },arrorOntap: (){
                                if(paySlipProviders.showPaySlips[index].payslipBoolValue == false){
                                  for (var item in paySlipProviders.showPaySlips) {
                                    if (item.payslipBoolValue == true) {
                                      item.payslipBoolValue = false;
                                    }
                                  }
                                }
                                paySlipProviders.arrorHandleSubmit(paySlipProviders.showPaySlips[index]);
                              },itemHideBoolValue: paySlipProviders.showPaySlips[index].payslipBoolValue,salaryValue: "₹${paySlipProviders.showPaySlips[index].basicSalary}",pfValue: paySlipProviders.showPaySlips[index].pF.toString(),tdsValue: paySlipProviders.showPaySlips[index].tDS.toString(),conveyanceValue: paySlipProviders.showPaySlips[index].conveyance.toString(),esicValue: paySlipProviders.showPaySlips[index].eSIC.toString(),hraValue: paySlipProviders.showPaySlips[index].hRA.toString(),nextAmountValue: paySlipProviders.showPaySlips[index].finaleAmt!.toString() == "0.0" ?"0":paySlipProviders.showPaySlips[index].finaleAmt!.toString(),);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ),
          );
  }
}
