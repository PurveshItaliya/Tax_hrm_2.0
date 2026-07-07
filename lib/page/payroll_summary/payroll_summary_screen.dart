// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/page/payroll_mater/payroll_mater_design.dart';
import 'package:tax_hrm/page/payroll_summary/logviewedit.dart';
import 'package:tax_hrm/provider/admin_payrollslip_provider.dart';
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
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:tax_hrm/utils/attendance_perf_logger.dart';


class PayrollSummaryScreen extends StatefulWidget {
  const PayrollSummaryScreen({super.key});

  @override
  State<PayrollSummaryScreen> createState() => _PayrollSummaryScreenState();
}

class _PayrollSummaryScreenState extends State<PayrollSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AttendancePerformanceLogger.instance.startSession('PAYROLL SUMMARY SCREEN');
      
      await AttendancePerformanceLogger.instance.track(
        'InternetConnectionProvider.getAllConnectionData',
        () async { Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData(); },
      );
      
      await AttendancePerformanceLogger.instance.track(
        'loadAddData [top-level orchestrator]',
        () => Provider.of<AdminPayrollslipProvider>(context, listen: false).loadAddData(context),
      );
      
      AttendancePerformanceLogger.instance.printSummary();
    });
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final payrollAdminProvider = Provider.of<AdminPayrollslipProvider>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final employeMastServices = Provider.of<EmployeMastServices>(context);
    final payrollProvider = Provider.of<PayRollProviders>(context);
    return Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar:  showCustomeAppBar(adminPayrollSummary, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);},actions: [
          if (payrollAdminProvider.selectedAddEmployeeList != null && payrollProvider.getPayRollAttendanceData.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 28),
                        SizedBox(width: size.width * 0.02),
                        Text(
                          'Delete Payroll Data',
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.bold,
                            color: ColorConst.black,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      'Are you sure you want to delete the payroll attendance data for the selected month? This action cannot be undone.',
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    actionsPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.015),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: size.width * 0.035,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: size.height * 0.01),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await payrollAdminProvider.deletePayrollData(context);
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: size.width * 0.035,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_forever_rounded),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          if (payrollAdminProvider.selectedAddEmployeeList != null)
            IconButton(onPressed: (){payrollAdminProvider.downloadAndShareCsv('${payrollAdminProvider.selectedAddEmployeeList!.firstName}_${payrollAdminProvider.selectedAddEmployeeList!.lastName} ${payrollAdminProvider.addPaySummarycurrentMonth.month} - ${payrollAdminProvider.addPaySummarycurrentMonth.year}');}, icon: const Icon(Icons.download_for_offline_rounded),visualDensity: VisualDensity.compact,padding: EdgeInsets.zero,),
        ]),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: payrollAdminProvider.islodering || payrollAdminProvider.selectedAddEmployeeList == null ? const SizedBox() : iconWithTextBtnDesign(size,updateDataString,isIcon: false,onTap: () async {
          await payrollAdminProvider.updatePayrollData(context);
        },isgradient: true,isImage: false),
        body: payrollAdminProvider.islodering ? addEmployeeSalaryShimmer(size) : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectEmployeeString, style: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500,fontSize: 14)),
                  heightSpacer(size.height*0.01),
                  Row(
                    children: [
                      Expanded(
                        child: AppSearchableDropdown<Employeelists>(
                          dropdownKey: ValueKey(payrollAdminProvider.selectedAddEmployeeList?.id ?? 'empty_dropdown'),
                          initialItem: payrollAdminProvider.selectedAddEmployeeList,
                          hintText: selectEmployeeNameString,
                          futureRequest:  Provider.of<EmployeMastServices>(context,listen: false).getFilterEmployeeList,
                          items: employeMastServices.emplists,
                          itemAsString: (item) => "${item.firstName.toString()} ${item.lastName.toString()}",
                          headerBuilder: (context, selectedItem, enabled) {
                            return payrollAdminProvider.selectedAddEmployeeList == null?Text(selectEmployeeNameString):Row(
                              children: [
                                Expanded(child: Text("${payrollAdminProvider.selectedAddEmployeeList!.firstName.toString()} ${payrollAdminProvider.selectedAddEmployeeList!.lastName.toString()}")),
                                widthSpacer(size.width*0.02),
                                InkWell(onTap: (){
                                  payrollAdminProvider.iconAddOntap(context);
                                },child: Icon(Icons.close,size: 15,color: ColorConst.black,))
                              ],
                            );
                          },
                          onChanged: (value) async {
                            AttendancePerformanceLogger.instance.startSession('PAYROLL SUMMARY: EMPLOYEE CHANGE');
                            await AttendancePerformanceLogger.instance.track(
                              'employessAddontap [top-level orchestrator]',
                              () async { payrollAdminProvider.employessAddontap(context,value); }
                            );
                            AttendancePerformanceLogger.instance.printSummary();
                          },
                        ),
                      ),
                      widthSpacer(size.width*0.02),
                      addIconSetData(size, (){
                        datePickerProvider.selectMonthYear(context, payrollAdminProvider.addPaySummarycurrentMonth, (value) async {
                          AttendancePerformanceLogger.instance.startSession('PAYROLL SUMMARY: MONTH CHANGE');
                          await AttendancePerformanceLogger.instance.track(
                            'updateAddMonth [top-level orchestrator]',
                            () async { await payrollAdminProvider.updateAddMonth(value, context); }
                          );
                          AttendancePerformanceLogger.instance.printSummary();
                        },);
                      },iconsName: Icons.calendar_month,bgColor: ColorConst.transparent,borderColors: ColorConst.textBorder,iconsColor: ColorConst.textgrey)
                    ],
                  ),
                  heightSpacer(size.height*0.012),
                  Text(
                    dateFormatMMMyyyy(payrollAdminProvider.addPaySummarycurrentMonth),
                    style: TextStyle(fontSize: 15,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString,color: ColorConst.textHeadingColor),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if(payrollAdminProvider.selectedAddEmployeeList != null)...[
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.9,
                              padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                              children: [
                                payrollSummaryTile(context, size, presentString, payrollAdminProvider.totalPresnts.toString(), const Color(0xff15A04E),bgColors: ColorConst.white),
                                payrollSummaryTile(context, size, totalTimeString, payrollAdminProvider.getFormattedTotalHours(), ColorConst.transparent,bgColors: ColorConst.white),
                                payrollSummaryTile(context, size, totalBreakString, payrollAdminProvider.getTotalBreakTime(), ColorConst.transparent,bgColors: ColorConst.white), 
                                payrollSummaryTile(context, size, lwpString, payrollAdminProvider.formattedUnpaidLeave, ColorConst.blueColor,bgColors: ColorConst.white,),
                                payrollSummaryTile(context, size, plString, payrollAdminProvider.formattedPaidLeave, ColorConst.paidLeaveColor,bgColors: ColorConst.white), 
                                payrollSummaryTile(context, size, weekOffString, payrollAdminProvider.weekOffCount.toString(), ColorConst.greyColor,bgColors: ColorConst.white),
                              ],
                            ),
                            heightSpacer(size.height * 0.001),
                            Container(height: size.height*0.08,
                              decoration: BoxDecoration(color: ColorConst.white,borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(totalHoursString, style:  TextStyle( fontSize: size.width * 0.055, color: Colors.grey, fontFamily: fontInterMediumString, fontWeight: FontWeight.w500)),
                                  widthSpacer(size.width*0.01),
                                  verticalBorder(),
                                  widthSpacer(size.width*0.01),
                                  Text(payrollAdminProvider.getTotalWorkingHours(), style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w700, fontFamily: fontInterBoldString)),
                                ],
                              ),
                            ),
                            heightSpacer(size.height * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
                              decoration: BoxDecoration(
                                color: ColorConst.themeColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  buildTableHeaderCell(size, 'Date', width: size.width*0.2),
                                  buildTableHeaderCell(size, 'In Time', width: size.width*0.15),
                                  buildTableHeaderCell(size, 'Out Time', width: size.width*0.15),
                                  buildTableHeaderCell(size, 'Break', width: size.width*0.14),
                                  buildTableHeaderCell(size, 'Total\nHrs', width: size.width*0.14),
                                  buildTableHeaderCell(size, 'Work\nHrs', width: size.width*0.14),
                                ],
                              ),
                            ),
                            heightSpacer(size.height * 0.005),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: payrollAdminProvider.attendanceDataList.length,
                              padding: const EdgeInsets.only(bottom: 60),
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 1);
                              },
                              itemBuilder: (itemContext, index) {
                                final data = payrollAdminProvider.attendanceDataList[index];
                                final holidayName = data['holidayName']?.toString() ?? '';
                                final currentDate = data['date'] as DateTime;
                                final employeeId = payrollAdminProvider.selectedAddEmployeeList!.id!;
                                final attendanceCguid = generateCustomUuid();
                                final attendanceId = '';
                                return GestureDetector(
                                  onTap: () {
                                    showAddPunchDialog(context, size, currentDate,attendanceCguid,attendanceId,employeeId,).then((_) {
                                      payrollAdminProvider.updatePayrollData(context);
                                      setState(() {});
                                    });
                                  },
                                  child: attendanceInOutDesign(
                                    size: size,
                                    date: DateFormat('dd/MM/yyyy').format(data['date']),
                                    inTimePunch: data['inTime'].toString().isEmpty ? '--:--' : data['inTime'],
                                    outTimepuchOut: holidayName.isNotEmpty
                                        ? holidayName
                                        : data['outTime'].toString().isEmpty ? '--:--' : data['outTime'],
                                    breakHours: data['breakTime'],
                                    hoursCount: data['totalHours'].toString().isEmpty ? '0.0' : data['totalHours'],
                                    workingHours: data['workingHours'],
                                    bgColor: ColorConst.attendanceBgColor,
                                    borderColor: ColorConst.themeColor,
                                    attendanceDataList: holidayName.isNotEmpty,
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString)) 
                          ]
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
      );
  }
}
