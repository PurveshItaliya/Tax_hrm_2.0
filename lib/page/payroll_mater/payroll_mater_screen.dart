// ignore_for_file: strict_top_level_inference, use_build_context_synchronously

import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/page/payroll_mater/add_salary_screen.dart';
import 'package:tax_hrm/page/payroll_mater/payroll_mater_design.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/payrollprovider.dart';
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
import 'package:tax_hrm/utils/attendance_perf_logger.dart';

class PayrollMaterScreen extends StatefulWidget {
  const PayrollMaterScreen({super.key});

  @override
  State<PayrollMaterScreen> createState() => _PayrollMaterScreenState();
}

class _PayrollMaterScreenState extends State<PayrollMaterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    },);
  }

  _loadAllData() async {
    AttendancePerformanceLogger.instance.startSession('PAYROLL MASTER SCREEN');
    Provider.of<PayRollProviders>(context,listen: false).islodering = true;
    
    await AttendancePerformanceLogger.instance.track(
      'InternetConnectionProvider.getAllConnectionData',
      () async { Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData(); }
    );
    
    await AttendancePerformanceLogger.instance.track(
      'PayRollProviders.loadingData [orchestrator]',
      () => Provider.of<PayRollProviders>(context,listen: false).loadingData(0,true)
    );
    
    await AttendancePerformanceLogger.instance.track(
      'EmployeMastServices.getAllEmployesData',
      () => Provider.of<EmployeMastServices>(context,listen: false).getAllEmployesData()
    );

    AttendancePerformanceLogger.instance.printSummary();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final payRollProviders = Provider.of<PayRollProviders>(context);
    safeAreaBgAndTextColor(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(payrollMasterString.toString().split(" ").first.toString(), size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: payRollProviders.islodering ? SizedBox() : Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.03),
              child: iconWithTextBtnDesign(size,addEmployeeSalaryString,isIcon: false,onTap: () async {
                payRollProviders.clearAddPayrollData();
                nextScreen(context, AddSalaryScreen(addEditFlag: true, getPayrollData: null),onthenValue: (value) {
                  _loadAllData();
                });
              },isgradient: true,isImage: false),
            ),
            body: refreshIndicatorDesign(
              onRefreshOntap: () {
                return _loadAllData();
              },
              widgetDesign: payRollProviders.isloderings ? payrollMasterShimmer(size) 
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
                              dropdownKey: ValueKey(payRollProviders.selectedEmployeeList),
                              initialItem: payRollProviders.selectedEmployeeList,
                              hintText: selectEmployeeNameString,
                              futureRequest:  Provider.of<EmployeMastServices>(context,listen: false).getFilterEmployeeList,
                              items: Provider.of<EmployeMastServices>(context,listen: false).emplists,
                              itemAsString: (item) => "${item.firstName.toString()} ${item.lastName.toString()}",
                              headerBuilder: (context, selectedItem, enabled) {
                                return payRollProviders.selectedEmployeeList == null?Text(selectEmployeeNameString):Row(
                                  children: [
                                    Expanded(child: Text("${payRollProviders.selectedEmployeeList!.firstName.toString()} ${payRollProviders.selectedEmployeeList!.lastName.toString()}")),
                                    widthSpacer(size.width*0.02),
                                    InkWell(onTap: (){
                                      payRollProviders.iconOntap();
                                    },child: Icon(Icons.close,size: 15,color: ColorConst.black,))
                                  ],
                                );
                              },
                              onChanged: (value) {
                                payRollProviders.employessontap(value);
                              },
                            ),
                          ),
                          widthSpacer(size.width*0.02),
                          addIconSetData(size, (){
                            datePickerProvider.selectMonthYear(context, payRollProviders.payRollcurrentMonth, (value) {
                              payRollProviders.updateMonth(value, context);
                            },);
                          },iconsName: Icons.calendar_month,bgColor: ColorConst.transparent,borderColors: ColorConst.textBorder,iconsColor: ColorConst.textgrey)
                        ],
                      ),
                      heightSpacer(size.height*0.012),
                      Text(
                        dateFormatMMMyyyy(payRollProviders.payRollcurrentMonth),
                        style: TextStyle(fontSize: 15,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString,color: ColorConst.textHeadingColor),
                      ),
                      heightSpacer(size.height*0.012),
                      payRollProviders.getSalaryList.isEmpty
                        ? Expanded(child: SingleChildScrollView(child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString)))) 
                        : Expanded(
                          child: ListView.builder(
                            itemCount: payRollProviders.getSalaryList.length,
                            padding: EdgeInsets.only(bottom: size.height * 0.12),
                            itemBuilder: (context, index) {
                              return payrollMasterCardDesign(size: size,titles: "${payRollProviders.getSalaryList[index].firstName} ${payRollProviders.getSalaryList[index].lastName}",editOntap: () {
                                nextScreen(context, AddSalaryScreen(addEditFlag: false, getPayrollData: payRollProviders.getSalaryList[index],), onthenValue: (value) {
                                  _loadAllData();
                                });
                              },deleteOntap: () {
                                 showDeleteDialog(context,size,yesOntap: () {payRollProviders.deletePayrollSalaryMaster(context,setRecuritmentid: payRollProviders.getSalaryList[index].salaryStructureId);},noOnTap: (){Navigator.pop(context);});
                              },arrorOntap: (){
                                if(payRollProviders.getSalaryList[index].salaryBoolValue == false){
                                  for (var item in payRollProviders.getSalaryList) {
                                    if (item.salaryBoolValue == true) {
                                      item.salaryBoolValue = false;
                                    }
                                  }
                                }
                                payRollProviders.arrorHandleSubmit(payRollProviders.getSalaryList[index]);
                              },itemHideBoolValue: payRollProviders.getSalaryList[index].salaryBoolValue,salaryValue: "₹${payRollProviders.getSalaryList[index].basicSalary}",pfValue: payRollProviders.getSalaryList[index].pF,tdsValue: payRollProviders.getSalaryList[index].tDS,conveyanceValue: payRollProviders.getSalaryList[index].conveyance,esicValue: payRollProviders.getSalaryList[index].eSIC,hraValue: payRollProviders.getSalaryList[index].hRA,nextAmountValue: payRollProviders.getSalaryList[index].finaleAmt!.toString() == "0.0" ?"0":payRollProviders.getSalaryList[index].finaleAmt!.toString(),);
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
