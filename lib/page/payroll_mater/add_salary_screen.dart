// ignore_for_file: deprecated_member_use, use_build_context_synchronously, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/payrool/getsalarydata.dart';
import 'package:tax_hrm/page/payroll_mater/employee_summry_screen.dart';
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
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:tax_hrm/utils/attendance_perf_logger.dart';

class AddSalaryScreen extends StatefulWidget {
  final bool addEditFlag;final Salarys? getPayrollData;
  const AddSalaryScreen({super.key,required this.addEditFlag,required this.getPayrollData});

  @override
  State<AddSalaryScreen> createState() => _AddSalaryScreenState();
}

class _AddSalaryScreenState extends State<AddSalaryScreen> {

 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AttendancePerformanceLogger.instance.startSession('ADD SALARY SCREEN');
      
      await AttendancePerformanceLogger.instance.track(
        'InternetConnectionProvider.getAllConnectionData',
        () async { Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData(); }
      );
      
      await AttendancePerformanceLogger.instance.track(
        'PayRollProviders.loadAddData [orchestrator]',
        () => Provider.of<PayRollProviders>(context,listen: false).loadAddData(context,0,widget.addEditFlag ?true:false,widget.addEditFlag,widget.getPayrollData)
      );
      
      AttendancePerformanceLogger.instance.printSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final payRollProviders = Provider.of<PayRollProviders>(context);
    final employeMastServices = Provider.of<EmployeMastServices>(context);

    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    return Scaffold(
            backgroundColor:ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(widget.addEditFlag?addEmployeeSalaryString:editEmployeeSalaryString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: payRollProviders.islodering || payRollProviders.selectedAddEmployeeList == null ? SizedBox() : iconWithTextBtnDesign(size,nextString,isIcon: false,onTap: () async {
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
              nextScreen(context,EmployeeSummryScreen(addEditFlag: widget.addEditFlag,getPayrollData: null,),onthenValue: (value) {},);
            },isgradient: true,isImage: false),
            body: payRollProviders.islodering ? addEmployeeSalaryShimmer(size) : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectEmployeeString, style: TextStyle(fontFamily: fontInterMediumString,fontWeight: FontWeight.w500,fontSize: 14)),
                  heightSpacer(size.height*0.01),
                  Row(
                    children: [
                      Expanded(
                        child: IgnorePointer(
                          ignoring: !widget.addEditFlag || (curentUser != null && curentUser['Role'] != 'Admin'),
                          child: AppSearchableDropdown<Employeelists>(
                            dropdownKey: ValueKey(payRollProviders.selectedAddEmployeeList),
                            initialItem: payRollProviders.selectedAddEmployeeList,
                            hintText: selectEmployeeNameString,
                            futureRequest: Provider.of<EmployeMastServices>(context,listen: false).getFilterEmployeeList,
                            items: employeMastServices.emplists,
                            itemAsString: (item) => "${item.firstName.toString()} ${item.lastName.toString()}",
                            headerBuilder: (context, selectedItem, enabled) {
                              return payRollProviders.selectedAddEmployeeList == null?Text(selectEmployeeNameString):Row(
                                children: [
                                  Expanded(child: Text("${payRollProviders.selectedAddEmployeeList!.firstName.toString()} ${payRollProviders.selectedAddEmployeeList!.lastName.toString()}", style: TextStyle(color: ColorConst.black))),
                                  widthSpacer(size.width*0.02),
                                  if (curentUser == null || curentUser['Role'] == 'Admin')
                                    InkWell(onTap: (){
                                      payRollProviders.iconAddOntap(context);
                                    },child: Icon(Icons.close,size: 15,color: ColorConst.black,))
                                ],
                              );
                            },
                            onChanged: (value) async {
                              AttendancePerformanceLogger.instance.startSession('ADD SALARY: EMPLOYEE CHANGE');
                              await AttendancePerformanceLogger.instance.track(
                                'employessAddontap',
                                () async { payRollProviders.employessAddontap(context,value); }
                              );
                              AttendancePerformanceLogger.instance.printSummary();
                            },
                          ),
                        ),
                      ),
                      widthSpacer(size.width*0.02),
                      addIconSetData(size, (){
                        datePickerProvider.selectMonthYear(context, payRollProviders.addPayRollcurrentMonth, (value) async {
                          AttendancePerformanceLogger.instance.startSession('ADD SALARY: MONTH CHANGE');
                          await AttendancePerformanceLogger.instance.track(
                            'updateAddMonth',
                            () async { payRollProviders.updateAddMonth(value, context); }
                          );
                          AttendancePerformanceLogger.instance.printSummary();
                        },);
                      },iconsName: Icons.calendar_month,bgColor: ColorConst.transparent,borderColors: ColorConst.textBorder,iconsColor: ColorConst.textgrey)
                    ],
                  ),
                  heightSpacer(size.height*0.012),
                  Text(
                    dateFormatMMMyyyy(payRollProviders.addPayRollcurrentMonth),
                    style: TextStyle(fontSize: 15,fontWeight: FontWeight.w800,fontFamily: fontInterMediumString,color: ColorConst.textHeadingColor),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if(payRollProviders.selectedAddEmployeeList != null)...[
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.9,
                              padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                              children: [
                                payrollSummaryTile(context, size, "P.Days", payRollProviders.totalPresnts.toString(), const Color(0xff15A04E), bgColors: null),
                                payrollSummaryTile(context, size, "W.Hrs", payRollProviders.getTotalWorkingHours(), ColorConst.themeColor, bgColors: null),
                                payrollSummaryTile(context, size, "Break", payRollProviders.getTotalBreakTime(), Colors.brown, bgColors: null), 
                                payrollSummaryTile(context, size, "P.L.Hrs", payRollProviders.getFormattedPaidLeaveHours(), Colors.purpleAccent, bgColors: null),
                                payrollSummaryTile(context, size, "P.H.Hrs", payRollProviders.getFormattedPaidHolidayHours(), Colors.orangeAccent, bgColors: null),
                                payrollSummaryTile(context, size, "T.Hrs", payRollProviders.getFormattedTotalHours(), ColorConst.darkBlueColor, bgColors: null),
                                payrollSummaryTile(context, size, "P.L", payRollProviders.formattedPaidLeave, ColorConst.paidLeaveColor, bgColors: null), 
                                payrollSummaryTile(context, size, "H.P.L", payRollProviders.totalHolidayCount.toInt().toString(), ColorConst.holidayColor, bgColors: null), 
                                payrollSummaryTile(context, size, "L.W.P", payRollProviders.formattedUnpaidLeave, ColorConst.blueColor, bgColors: null),
                                payrollSummaryTile(context, size, "W.Off", payRollProviders.setWeekOffCount.toInt().toString(), ColorConst.redDarkColors, bgColors: null),
                              ],
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
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: payRollProviders.attendanceListCount,
                              padding: EdgeInsets.only(bottom: 60),
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 1);
                              },
                              itemBuilder: (context, index) {
                                final attendanceData = payRollProviders.getAttendanceDataForIndex(index);
                                String statusText = '';
                                String displayInTime = attendanceData['inTime'];
                                String displayOutTime = attendanceData['outTime'];
                                String displayTotalHours = attendanceData['totalHours'];
                                String displayBreak = attendanceData['totalBreaks'] > 0 
                                    ? payRollProviders.formatBreakTime(attendanceData['totalBreaks']) 
                                    : '0';
                                String displayWorkHours = '0';
                                if (attendanceData['totalHours'] != '-' && attendanceData['totalHours'].isNotEmpty && attendanceData['totalHours'] != '00:00') {
                                  final totalHoursParts = attendanceData['totalHours'].split(':');
                                  if (totalHoursParts.length == 2) {
                                    double totalHoursValue = int.parse(totalHoursParts[0]) + (int.parse(totalHoursParts[1]) / 60);
                                    double breakHoursValue = 0;
                                    if (attendanceData['totalBreaks'] > 0) {
                                      breakHoursValue = attendanceData['totalBreaks'] / 60;
                                    }
                                    double workingHoursValue = totalHoursValue - breakHoursValue;
                                    if (workingHoursValue < 0) workingHoursValue = 0;
                                    int workHrs = workingHoursValue.floor();
                                    int workMins = ((workingHoursValue - workHrs) * 60).round();
                                    displayWorkHours = '${workHrs.toString().padLeft(2, '0')}:${workMins.toString().padLeft(2, '0')}';
                                  }
                                }
                                if (attendanceData['isWeekOff'] == true && (attendanceData['inTime'] == '--:-- --' || attendanceData['inTime'] == '-' || attendanceData['inTime'].isEmpty)) {
                                  statusText = 'Week Off';
                                  displayInTime = '-';
                                  displayOutTime = 'Week Off';
                                  displayTotalHours = '-';
                                  displayBreak = '-';
                                  displayWorkHours = '-';
                                } else if (attendanceData['isOnLeave'] == true) {
                                  final leaveType = attendanceData['leaveTypeName'].toString().toLowerCase();
                                  if (leaveType.contains('paid')) {
                                    statusText = 'PAID LEAVE';
                                  } else {
                                    statusText = attendanceData['leaveTypeName'];
                                  }
                                  displayInTime = '-';
                                  displayOutTime = statusText;
                                  displayTotalHours = '-';
                                  displayBreak = '-';
                                  displayWorkHours = '-';
                                } else if (attendanceData['holidayName'].toString().isNotEmpty) {
                                  statusText = attendanceData['holidayName'];
                                  displayInTime = '-';
                                  displayOutTime = attendanceData['holidayName'];
                                  displayTotalHours = '-';
                                  displayBreak = '-';
                                  displayWorkHours = '-';
                                }
                                              
                                              
                                return attendanceInOutDesign(
                                  size: size,
                                  date: DateFormat('dd EEE').format(attendanceData['date']),
                                  inTimePunch: displayInTime,
                                  outTimepuchOut: displayOutTime,
                                  breakHours: displayBreak,
                                  hoursCount: displayTotalHours,
                                  workingHours: displayWorkHours,
                                  bgColor: ColorConst.attendanceBgColor,
                                  borderColor: ColorConst.themeColor,
                                  attendanceDataList: attendanceData['holidayName'].toString().isNotEmpty,
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
