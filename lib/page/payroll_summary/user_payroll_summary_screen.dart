// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/payroll_mater/payroll_mater_design.dart';
import 'package:tax_hrm/provider/admin_payrollslip_provider.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
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

class UserPayrollSummaryScreen extends StatefulWidget {
  const UserPayrollSummaryScreen({super.key});

  @override
  State<UserPayrollSummaryScreen> createState() => _UserPayrollSummaryScreenState();
}

class _UserPayrollSummaryScreenState extends State<UserPayrollSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AttendancePerformanceLogger.instance.startSession('USER PAYROLL SUMMARY SCREEN');
      
      await AttendancePerformanceLogger.instance.track(
        'InternetConnectionProvider.getAllConnectionData',
        () async {
          Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
        },
      );
      
      await AttendancePerformanceLogger.instance.track(
        'loadUserData [top-level orchestrator]',
        () => Provider.of<AdminPayrollslipProvider>(context, listen: false).loadUserData(context),
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
    
    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: showCustomeAppBar(
        payrollSummeryString,
        size,
        titleColors: ColorConst.appbarTextColor,
        iconsOntap: () {
          backScreen(context);
        },
        actions: [
          if (payrollAdminProvider.selectedAddEmployeeList != null)
            IconButton(
              onPressed: () {
                payrollAdminProvider.downloadAndShareCsv(
                  '${payrollAdminProvider.selectedAddEmployeeList!.firstName}_${payrollAdminProvider.selectedAddEmployeeList!.lastName} ${payrollAdminProvider.addPaySummarycurrentMonth.month} - ${payrollAdminProvider.addPaySummarycurrentMonth.year}'
                );
              },
              icon: const Icon(Icons.download_for_offline_rounded),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
      body: payrollAdminProvider.islodering
          ? addEmployeeSalaryShimmer(size)
          : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Details Card with Month/Year Selection
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: ColorConst.textBorder),
                    ),
                    color: ColorConst.white,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.height * 0.015,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: ColorConst.themeColor.withOpacity(0.1),
                            child: Text(
                              "${payrollAdminProvider.selectedAddEmployeeList?.firstName?.isNotEmpty == true ? payrollAdminProvider.selectedAddEmployeeList!.firstName![0] : ''}${payrollAdminProvider.selectedAddEmployeeList?.lastName?.isNotEmpty == true ? payrollAdminProvider.selectedAddEmployeeList!.lastName![0] : ''}",
                              style: TextStyle(
                                color: ColorConst.themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          widthSpacer(size.width * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${payrollAdminProvider.selectedAddEmployeeList?.firstName ?? ''} ${payrollAdminProvider.selectedAddEmployeeList?.lastName ?? ''}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: fontInterMediumString,
                                    color: ColorConst.black,
                                  ),
                                ),
                                if (payrollAdminProvider.selectedAddEmployeeList?.positionName != null &&
                                    payrollAdminProvider.selectedAddEmployeeList!.positionName!.isNotEmpty) ...[
                                  heightSpacer(2),
                                  Text(
                                    payrollAdminProvider.selectedAddEmployeeList!.positionName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              datePickerProvider.selectMonthYear(
                                context,
                                payrollAdminProvider.addPaySummarycurrentMonth,
                                (value) async {
                                  AttendancePerformanceLogger.instance.startSession('PAYROLL SUMMARY: MONTH CHANGE');
                                  await AttendancePerformanceLogger.instance.track(
                                    'updateAddMonth [top-level orchestrator]',
                                    () async {
                                      await payrollAdminProvider.updateAddMonth(value, context);
                                    },
                                  );
                                  AttendancePerformanceLogger.instance.printSummary();
                                },
                              );
                            },
                            icon: Icon(Icons.calendar_month, color: ColorConst.textgrey),
                            tooltip: 'Select Month/Year',
                          ),
                        ],
                      ),
                    ),
                  ),
                  heightSpacer(size.height * 0.012),
                  Text(
                    dateFormatMMMyyyy(payrollAdminProvider.addPaySummarycurrentMonth),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: fontInterMediumString,
                      color: ColorConst.textHeadingColor,
                    ),
                  ),
                  Expanded(
                    child: refreshIndicatorDesign(
                      onRefreshOntap: () async {
                        await Provider.of<AdminPayrollslipProvider>(context, listen: false).loadUserData(context);
                      },
                      widgetDesign: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            if (payrollAdminProvider.selectedAddEmployeeList != null) ...[
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.9,
                                padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                                children: [
                                  payrollSummaryTile(
                                    context,
                                    size,
                                    presentString,
                                    payrollAdminProvider.totalPresnts.toString(),
                                    const Color(0xff15A04E),
                                    bgColors: ColorConst.white,
                                  ),
                                  payrollSummaryTile(
                                    context,
                                    size,
                                    totalTimeString,
                                    payrollAdminProvider.getFormattedTotalHours(),
                                    ColorConst.transparent,
                                    bgColors: ColorConst.white,
                                  ),
                                  payrollSummaryTile(
                                    context,
                                    size,
                                    totalBreakString,
                                    payrollAdminProvider.getTotalBreakTime(),
                                    ColorConst.transparent,
                                    bgColors: ColorConst.white,
                                  ),
                                  payrollSummaryTile(
                                    context,
                                    size,
                                    lwpString,
                                    payrollAdminProvider.formattedUnpaidLeave,
                                    ColorConst.blueColor,
                                    bgColors: ColorConst.white,
                                  ),
                                  payrollSummaryTile(
                                    context,
                                    size,
                                    plString,
                                    payrollAdminProvider.formattedPaidLeave,
                                    ColorConst.paidLeaveColor,
                                    bgColors: ColorConst.white,
                                  ),
                                  payrollSummaryTile(
                                    context,
                                    size,
                                    weekOffString,
                                    payrollAdminProvider.weekOffCount.toString(),
                                    ColorConst.greyColor,
                                    bgColors: ColorConst.white,
                                  ),
                                ],
                              ),
                              heightSpacer(size.height * 0.001),
                              Container(
                                height: size.height * 0.08,
                                decoration: BoxDecoration(
                                  color: ColorConst.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      totalHoursString,
                                      style: TextStyle(
                                        fontSize: size.width * 0.055,
                                        color: Colors.grey,
                                        fontFamily: fontInterMediumString,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    widthSpacer(size.width * 0.01),
                                    verticalBorder(),
                                    widthSpacer(size.width * 0.01),
                                    Text(
                                      payrollAdminProvider.getTotalWorkingHours(),
                                      style: TextStyle(
                                        fontSize: size.width * 0.04,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: fontInterBoldString,
                                      ),
                                    ),
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
                                    buildTableHeaderCell(size, dateString, width: size.width * 0.2),
                                    buildTableHeaderCell(size, inTimeString, width: size.width * 0.15),
                                    buildTableHeaderCell(size, outTimeString, width: size.width * 0.15),
                                    buildTableHeaderCell(size, breakString, width: size.width * 0.14),
                                    buildTableHeaderCell(size, '$totalString\n$hrsString', width: size.width * 0.14),
                                    buildTableHeaderCell(size, '$workString\n$hrsString', width: size.width * 0.14),
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
                                  return attendanceInOutDesign(
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
                                  );
                                },
                              ),
                            ] else ...[
                              SizedBox(
                                width: size.width,
                                height: size.height * 0.65,
                                child: noDataFoundsDesign(
                                  size,
                                  noDataFoundsString,
                                  nodataFoundsImagString,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
