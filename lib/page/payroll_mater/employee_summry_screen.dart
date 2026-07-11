// ignore_for_file: deprecated_member_use, use_build_context_synchronously, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/payrool/getsalarydata.dart';
import 'package:tax_hrm/page/payroll_mater/payroll_mater_design.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/payrollprovider.dart';
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
import 'package:tax_hrm/utils/attendance_perf_logger.dart';

class EmployeeSummryScreen extends StatefulWidget {
  final bool addEditFlag;
  final Salarys? getPayrollData;
  const EmployeeSummryScreen({super.key, required this.addEditFlag, required this.getPayrollData});

  @override
  State<EmployeeSummryScreen> createState() => _EmployeeSummryScreenState();
}

class _EmployeeSummryScreenState extends State<EmployeeSummryScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      AttendancePerformanceLogger.instance.startSession('EMPLOYEE SUMMARY SCREEN');
      
      await AttendancePerformanceLogger.instance.track(
        'InternetConnectionProvider.getAllConnectionData',
        () async { await Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData(); }
      );
      
      final payRollProviders = Provider.of<PayRollProviders>(context, listen: false);
      if (widget.getPayrollData != null) {
        payRollProviders.setExistingEmployeeSalaryData(widget.getPayrollData!);
        AttendancePerformanceLogger.instance.printSummary();
        return;
      }

      if (payRollProviders.selectedAddEmployeeList != null && payRollProviders.salaryAmount.isEmpty) {
        payRollProviders.setEmployeeSalaryData(
          selectedEmployes: payRollProviders.selectedAddEmployeeList!,
          workingHoursview: payRollProviders.holdworkingHours.isEmpty ? '00:00' : payRollProviders.holdworkingHours,
          totalWorkingHoursminuts: payRollProviders.holdworkingMinuts,
          setYear: payRollProviders.addPayRollcurrentMonth.year.toString(),
          setMonth: payRollProviders.addPayRollcurrentMonth.month.toString(),
          paidLeavecount: payRollProviders.paidLeave.toString(),
          paidleavhours: payRollProviders.showUserTotalHours,
          settotalBreak: payRollProviders.showMainBreak,
          settotalPresent: payRollProviders.totalPresnts.toString(),
          setweeklyOff: payRollProviders.setWeekOffCount.toString(),
          setweeklyOffHour: '0',
          saveType: widget.addEditFlag ? 'A' : 'U',
        );
      }

      await AttendancePerformanceLogger.instance.track(
        'PayRollProviders.initializeEmployeeSalaryData',
        () => payRollProviders.initializeEmployeeSalaryData(context)
      );
      
      AttendancePerformanceLogger.instance.printSummary();
      if (mounted) setState(() {});
    } catch (e) { /* ignored */ }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final payRollProviders = Provider.of<PayRollProviders>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(employeeSummryString, size, titleColors: ColorConst.appbarTextColor, iconsOntap: () { backScreen(context); }),
            body: payRollProviders.islodering 
                ? addEmployeeSummryShimmer(size) 
                : Padding(
                    padding: EdgeInsets.all(size.width * 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: refreshIndicatorDesign(
                            onRefreshOntap: () async {
                              await _initializeData();
                            },
                            widgetDesign: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                // Employee Details
                                employeeSummryDesign(size, headingTitle: "$departmentString :", subHeadingTitle: payRollProviders.department.isEmpty ? "-" : payRollProviders.department),
                                heightSpacer(size.height * 0.01),
                                employeeSummryDesign(size, headingTitle: "$designationString :", subHeadingTitle: payRollProviders.designation.isEmpty ? "-" : payRollProviders.designation),
                                heightSpacer(size.height * 0.01),
                                employeeSummryDesign(size, headingTitle: "$bankNameString :", subHeadingTitle: payRollProviders.bankName.isEmpty ? "-" : payRollProviders.bankName),
                                heightSpacer(size.height * 0.01),
                                employeeSummryDesign(size, headingTitle: "$bankAccountNoString :", subHeadingTitle: payRollProviders.bankNumber.isEmpty ? "-" : payRollProviders.bankNumber),
                                heightSpacer(size.height * 0.015),
                                
                                // Salary Details Container
                                Container(
                                  width: size.width,
                                  padding: EdgeInsets.all(size.height * 0.01),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: ColorConst.textBorder, width: 1),
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Column(
                                    children: [
                                      employeeSummryDesign(size, headingTitle: "$salaryAmountString :", subHeadingTitle: payRollProviders.salaryAmount.isEmpty ? "0" : payRollProviders.salaryAmount),
                                      heightSpacer(size.height * 0.01),
                                      CommonTextField(
                                        controller: payRollProviders.txtEffectiveDateController,
                                        readOnly: true,
                                        hintText: selectEventStartDateString,
                                        suffixIcon: IgnorePointer(
                                          child: IconButton(
                                            onPressed: () {},
                                            icon: Icon(Icons.calendar_today_outlined, color: ColorConst.passwordColor),
                                          ),
                                        ),
                                        showHeading: effectiveDateString,
                                        onTap: () async {
                                          await payRollProviders.selectDatePicker(context, size, dateController: datePickerProvider, selectDatePic: payRollProviders.effectiveDate);
                                          if (mounted) setState(() {});
                                        },
                                        heightValue: size.height * 0.01,
                                      ),
                                      heightSpacer(size.height * 0.01),
                                      employeeSummryDesign(size, headingTitle: "$workingHoursString :", subHeadingTitle: payRollProviders.workingHours.isEmpty ? "0" : payRollProviders.workingHours),
                                      heightSpacer(size.height * 0.01),
                                      employeeSummryDesign(size, headingTitle: "$totalHoursString :", subHeadingTitle: payRollProviders.totalHours.isEmpty ? "0" : payRollProviders.totalHours),
                                      heightSpacer(size.height * 0.01),
                                      employeeSummryDesign(size, headingTitle: "$otHoursString :", subHeadingTitle: payRollProviders.otHours.isEmpty ? "0" : payRollProviders.otHours),
                                      heightSpacer(size.height * 0.01),
                                    ],
                                  ),
                                ),
                                heightSpacer(size.height * 0.015),
                                
                                // Material Segmented Control
                                SizedBox(
                                  height: size.height * 0.06,
                                  width: size.width,
                                  child: MaterialSegmentedControl(
                                    horizontalPadding: EdgeInsets.zero,
                                    children: payRollProviders.options,
                                    selectionIndex: payRollProviders.currentSelection,
                                    borderColor: ColorConst.themeColor,
                                    selectedColor: ColorConst.themeColor,
                                    unselectedColor: ColorConst.white,
                                    selectedTextStyle: TextStyle(color: ColorConst.white, fontSize: size.height * 0.02, fontWeight: FontWeight.bold),
                                    unselectedTextStyle: TextStyle(color: ColorConst.themeColor, fontSize: size.height * 0.02, fontWeight: FontWeight.bold),
                                    borderWidth: 0.7,
                                    borderRadius: 10.0,
                                    onSegmentTapped: (index) {
                                      payRollProviders.ontabMaterioal(index);
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ),
                                heightSpacer(size.height * 0.01),
                                
                                // Addition Section
                                if (payRollProviders.currentSelection == 0) ...[
                                  employeeSummryDesign(size, headingTitle: "$hraString :", subHeadingTitle: payRollProviders.hra.isEmpty ? "0" : payRollProviders.hra),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$daString :", subHeadingTitle: payRollProviders.da.isEmpty ? "0" : payRollProviders.da),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$conveyanceString :", subHeadingTitle: payRollProviders.conveyance.isEmpty ? "0" : payRollProviders.conveyance),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "${medicalAllowanceString.toString().split(" ").first.toString()} :", subHeadingTitle: payRollProviders.medical.isEmpty ? "0" : payRollProviders.medical),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$specialAllowanceString :", subHeadingTitle: payRollProviders.allowance.isEmpty ? "0" : payRollProviders.allowance),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$otherAditionString :", subHeadingTitle: payRollProviders.otherAddition.isEmpty ? "0" : payRollProviders.otherAddition),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$otString :", subHeadingTitle: payRollProviders.ot.isEmpty ? "0" : payRollProviders.ot),
                                  heightSpacer(size.height * 0.01),
                                ] 
                                // Deduction Section
                                else ...[
                                  employeeSummryDesign(size, headingTitle: "$pfString :", subHeadingTitle: payRollProviders.pf.isEmpty ? "0" : payRollProviders.pf),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$esicString :", subHeadingTitle: payRollProviders.esic.isEmpty ? "0" : payRollProviders.esic),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$professionalTaxString :", subHeadingTitle: payRollProviders.professionalTax.isEmpty ? "0" : payRollProviders.professionalTax),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$tdsString :", subHeadingTitle: payRollProviders.tds.isEmpty ? "0" : payRollProviders.tds),
                                  heightSpacer(size.height * 0.01),
                                  employeeSummryDesign(size, headingTitle: "$otherDeducationString :", subHeadingTitle: payRollProviders.otherDeduction.isEmpty ? "0" : payRollProviders.otherDeduction),
                                  heightSpacer(size.height * 0.01),
                                ],
                              ],
                            ),
                          ),
                        ),
                        ),
                        
                        // Net Payable Container
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: ColorConst.themeColor, width: 1.5),
                            borderRadius: BorderRadius.circular(4)
                          ),
                          height: size.width * 0.15,
                          width: size.width,
                          padding: EdgeInsets.only(right: 5, left: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  totalNetPayableString,
                                  style: TextStyle(
                                    fontSize: size.height * 0.025,
                                    fontFamily: fontInterBoldString,
                                    color: ColorConst.themeColor,
                                  ),
                                ),
                              ),
                              widthSpacer(size.width * 0.02),
                              Text(
                                "₹ ${payRollProviders.finalAmountPay}",
                                style: TextStyle(
                                  fontSize: size.height * 0.02,
                                  fontFamily: fontInterBoldString,
                                  color: ColorConst.themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        heightSpacer(size.height * 0.02),
                        
                        // Save and Cancel Buttons
                        Row(
                          children: [
                            Expanded(
                              child: btnDesign(
                                size,
                                titles: saveString,
                                onTap: () async {
                                  await payRollProviders.saveEmployeeSalary(context);
                                },
                                isgradient: true,
                              ),
                            ),
                            widthSpacer(size.width * 0.02),
                            Expanded(
                              child: btnDesign(
                                size,
                                titles: cancelString,
                                bgColor: Colors.transparent,
                                borderColors: ColorConst.themeColor,
                                textColors: ColorConst.themeColor,
                                onTap: () { 
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          );
  }
}
