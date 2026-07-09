// ignore_for_file: strict_top_level_inference, use_build_context_synchronously, unused_local_variable, avoid_function_literals_in_foreach_calls

import 'package:cached_network_image/cached_network_image.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/models/attendance/allemployeattendance.dart';
import 'package:tax_hrm/models/attendance/attendanceBlog.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/attendance/custom.dart';
import 'package:tax_hrm/page/attendance/customdialog.dart';
import 'package:tax_hrm/page/attendance/viewimage.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/leaveProviders.dart';
import 'package:tax_hrm/provider/leavemployeeprovider.dart';
import 'package:tax_hrm/provider/payrollprovider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:tax_hrm/utils/attendance_perf_logger.dart';

class AttendanceScreen extends StatefulWidget {
  final  AllEmployeAttendance?  empData; 
  const AttendanceScreen({super.key, this.empData});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isFirstLoad = true;
  bool _isMonthChanging = false;
  AllEmployeAttendance? _currentEmpData;
  final TextEditingController textEditingController = TextEditingController();
  GlobalKey<MonthViewState> _monthViewKey = GlobalKey<MonthViewState>();

  // ─── Performance Logger (debug-only, zero impact on production logic) ───
  // Using AttendancePerformanceLogger.instance directly

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Re-create the key every time the screen opens so MonthView always
    // re-initialises to the current month (not a stale persisted page).
    _monthViewKey = GlobalKey<MonthViewState>();
    if (widget.empData != null) {
      _currentEmpData = widget.empData;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // ── Performance monitoring: screen-open API calls ─────────────────
        // All calls below are SEQUENTIAL (each awaits the previous one).
        // loadingData internally fires several sub-calls; getDuration fires two
        // more (getMonthsBreaks → getPayRollData + calculateTime → getPayRollData
        // + getAllHoliday). We track both top-level orchestrator methods here.
        // ─────────────────────────────────────────────────────────────────
        AttendancePerformanceLogger.instance.startSession(
          _currentEmpData == null
              ? 'AttendanceScreen (self)'
              : 'AttendanceScreen (admin: ${_currentEmpData!.firstName} ${_currentEmpData!.lastName})',
        );

        try {
          // ── API Call #1 : loadingData ─────────────────────────────────
          // Internally calls (all sequential):
          //   • LeaveMastServices.getUserLeaveLists()
          //   • setShiftData   → PositionMasterService.getpositionfiles()
          //                   → ShiftMasterProvider.getShiftTimintgMasterData()
          //   • fetchAndStoreBeginTime → ShiftApiClass.getShiftTimingMaster()
          //   • getEmpAttendanceData:
          //       • AttendanceApis.getEmpMonathCounting()
          //       • HolidayAPIS.getHolidays()
          //       • AttendanceApis.getEmpMonathAttendace()
          //       • setShiftData  (again, inside getEmpAttendanceData)
          await AttendancePerformanceLogger.instance.track(
            'loadingData [top-level orchestrator]',
            () => Provider.of<AttendanceEmp>(context, listen: false)
                .loadingData(_currentEmpData, context),
            executionMode: 'sequential',
          );

          AttendancePerformanceLogger.instance.milestone('loadingData complete — starting getDuration');

          // ── API Call #2 : getDuration ─────────────────────────────────
          // Internally calls (sequential):
          //   • PayRollProviders.getMonthsBreaks()
          //   • calculateTime:
          //       • PayRollProviders.getPayRollData()
          //       • HolidayeMastServices.getAllHoliday()
          await AttendancePerformanceLogger.instance.track(
            'getDuration [top-level orchestrator]',
            () => Provider.of<AttendanceEmp>(context, listen: false)
                .getDuration(context, _currentEmpData),
            executionMode: 'sequential',
          );
        } catch (e) {
          // ignore error
        } finally {
          // ── Print full summary to debug console ───────────────────────
          AttendancePerformanceLogger.instance.printSummary();

          if (mounted) {
            setState(() {
              _isFirstLoad = false;
            });
          }
        }
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    int setindexs = 0;
    if (Provider.of<AttendanceEmp>(context).showDateType == 2) {
      setindexs = Provider.of<AttendanceEmp>(context, listen: false).curentMonthHoliday.indexWhere((element) => DateTime.parse(element.holidayDate.toString()) == DateTime.parse(Provider.of<AttendanceEmp>(context).showTimeValues.toString()));
    }
    Size size = MediaQuery.of(context).size;
    final attendanceEmp = Provider.of<AttendanceEmp>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final leaveProviders =  Provider.of<LeaveMastServices>(context);
    safeAreaBgAndTextColor(context,);
    // Show full-screen shimmer on very first load
    if (_isFirstLoad) {
      return Scaffold(
          backgroundColor: ColorConst.scaffoldColor,
          appBar: showBottomAppBar(isAdminBack: _currentEmpData == null ? false : true, _currentEmpData == null ? attendanceString : '${_currentEmpData!.firstName} ${_currentEmpData!.lastName}', size, centerTitles: false, actions: const <Widget>[]),
          body: viewCalenderShimmer(size),
        );
    }
    return Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: showBottomAppBar(isAdminBack: _currentEmpData == null ? false : true, _currentEmpData == null ? attendanceString : '${_currentEmpData!.firstName} ${_currentEmpData!.lastName}', size, centerTitles: false, actions: const <Widget>[]),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (_currentEmpData != null && Provider.of<AdminAttenDanceServices>(context, listen: false).mainHoldEmpList.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: size.height * 0.005, top: size.height * 0.005, left: size.width * 0.02, right: size.width * 0.02),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<int>(
                      isExpanded: true,
                      hint: Text(
                        _currentEmpData != null ? '${_currentEmpData!.firstName} ${_currentEmpData!.lastName}' : 'Select Employee',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _currentEmpData != null ? FontWeight.w600 : FontWeight.normal,
                          color: _currentEmpData != null ? ColorConst.black : Theme.of(context).hintColor,
                        ),
                      ),
                      items: Provider.of<AdminAttenDanceServices>(context, listen: false).mainHoldEmpList.map((emp) {
                        return DropdownItem<int>(
                          value: emp.empId,
                          child: Text(
                            '${emp.firstName} ${emp.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newEmpId) async {
                        if (newEmpId != null && newEmpId != _currentEmpData?.empId) {
                          final adminProv = Provider.of<AdminAttenDanceServices>(context, listen: false);
                          final newEmp = adminProv.mainHoldEmpList.firstWhere((e) => e.empId == newEmpId);
                          setState(() {
                            _currentEmpData = newEmp;
                            _monthViewKey = GlobalKey<MonthViewState>();
                          });
                          // ── Perf log: employee switch ─────────────────
                          AttendancePerformanceLogger.instance.startSession('EmployeeSwitch → ${newEmp.firstName} ${newEmp.lastName}');
                          try {
                            await AttendancePerformanceLogger.instance.track(
                              'loadingData [top-level orchestrator]',
                              () => Provider.of<AttendanceEmp>(context, listen: false).loadingData(_currentEmpData, context),
                            );
                            await AttendancePerformanceLogger.instance.track(
                              'getDuration [top-level orchestrator]',
                              () => Provider.of<AttendanceEmp>(context, listen: false).getDuration(context, _currentEmpData),
                            );
                          } finally {
                            AttendancePerformanceLogger.instance.printSummary();
                          }
                        }
                      },
                      buttonStyleData: ButtonStyleData(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ColorConst.grey,
                          ),
                          color: ColorConst.white,
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: ColorConst.white,
                        ),
                      ),
                      dropdownSearchData: DropdownSearchData(
                        searchController: textEditingController,
                        searchBarWidgetHeight: 50,
                        searchBarWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: textEditingController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: searchForAnEmployeeString,
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {
                          final label = (item.child as Text).data.toString().toLowerCase();
                          return label.contains(searchValue.toLowerCase());
                        },
                      ),
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {
                          textEditingController.clear();
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(size.width * 0.02),
                  decoration: BoxDecoration(
                    color: ColorConst.white,
                    boxShadow: [
                      BoxShadow(color: ColorConst.grey, spreadRadius: 1.1, blurRadius: 0.8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heightSpacer(size.height * 0.005),
  
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _isMonthChanging ? null : () async {
                              if (_isMonthChanging) return;
                              setState(() => _isMonthChanging = true);
                              // ── Perf log: previous-month navigation ───
                              AttendancePerformanceLogger.instance.startSession('PreviousMonth Navigation');
                              try {
                                await AttendancePerformanceLogger.instance.track(
                                  'previousMonth [top-level orchestrator]',
                                  () => attendanceEmp.previousMonth(context, _currentEmpData),
                                );
                                _monthViewKey.currentState?.animateToMonth(attendanceEmp.currentMonth);
                                await AttendancePerformanceLogger.instance.track(
                                  'getDuration [top-level orchestrator]',
                                  () => attendanceEmp.getDuration(context, _currentEmpData),
                                );
                              } finally {
                                AttendancePerformanceLogger.instance.printSummary();
                                if (mounted) setState(() => _isMonthChanging = false);
                              }
                            },
                            child: Icon(Icons.arrow_back_ios_new, size: size.width * 0.05,
                              color: _isMonthChanging ? ColorConst.grey : ColorConst.black),
                          ),
                          GestureDetector(
                            onTap: _isMonthChanging ? null : () {
                              datePickerProvider.selectMonthYear(context, attendanceEmp.currentMonth, (value) async {
                                if (_isMonthChanging) return;
                                setState(() => _isMonthChanging = true);
                                // ── Perf log: month picker navigation ───
                                AttendancePerformanceLogger.instance.startSession('MonthPicker Navigation → ${value.year}-${value.month}');
                                try {
                                  await AttendancePerformanceLogger.instance.track(
                                    'updateMonth [top-level orchestrator]',
                                    () => attendanceEmp.updateMonth(value, _currentEmpData, context),
                                  );
                                  _monthViewKey.currentState?.animateToMonth(attendanceEmp.currentMonth);
                                  await AttendancePerformanceLogger.instance.track(
                                    'getDuration [top-level orchestrator]',
                                    () => attendanceEmp.getDuration(context, _currentEmpData),
                                  );
                                } finally {
                                  AttendancePerformanceLogger.instance.printSummary();
                                  if (mounted) setState(() => _isMonthChanging = false);
                                }
                              });
                            },
                            child: Text(
                              dateFormatMMMyyyy(attendanceEmp.currentMonth),
                              style: TextStyle(fontSize: size.width * 0.045, fontWeight: FontWeight.w700, color: ColorConst.textgrey),
                            ),
                          ),
                          GestureDetector(
                            onTap: (!_isMonthChanging && attendanceEmp.currentMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month)))
                                ? () async {
                                    if (_isMonthChanging) return;
                                    setState(() => _isMonthChanging = true);
                                    // ── Perf log: next-month navigation ───
                                    AttendancePerformanceLogger.instance.startSession('NextMonth Navigation');
                                    try {
                                      await AttendancePerformanceLogger.instance.track(
                                        'nextMonth [top-level orchestrator]',
                                        () => attendanceEmp.nextMonth(context, _currentEmpData),
                                      );
                                      _monthViewKey.currentState?.animateToMonth(attendanceEmp.currentMonth);
                                      await AttendancePerformanceLogger.instance.track(
                                        'getDuration [top-level orchestrator]',
                                        () => attendanceEmp.getDuration(context, _currentEmpData),
                                      );
                                    } finally {
                                      AttendancePerformanceLogger.instance.printSummary();
                                      if (mounted) setState(() => _isMonthChanging = false);
                                    }
                                  }
                                : null,
                            child: Icon(Icons.arrow_forward_ios_outlined, size: size.width * 0.05,
                              color: (!_isMonthChanging && attendanceEmp.currentMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month)))
                                  ? ColorConst.black
                                  : ColorConst.grey),
                          ),
                        ],
                      ),
                      heightSpacer(size.height * 0.005),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.9,
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                        children: [
                          summaryTile(context, size, presentString, attendanceEmp.totalPresent.toString(), Color(0xff15A04E)),
                          summaryTile(context, size, absentString, attendanceEmp.totalAbset.toString(), Color(0xffE02B49)),
                          summaryTile(context, size, unPaidLeaveString, attendanceEmp.setEmpAttendanc ==null ? '0' : attendanceEmp.setEmpAttendanc!.first.totalUnPaidLeave.toString(), ColorConst.blueColor),
                          summaryTile(context, size, weekOffString, attendanceEmp.totakWeekOff.toString(), ColorConst.greyColor),
                          summaryTile(context, size, paidLeaveString, attendanceEmp.totalPaidLeave.toString(), ColorConst.paidLeaveColor),
                          summaryTile(context, size, holidayString, attendanceEmp.totalHoliday.toString(), ColorConst.holidayColor),
                        ],
                      ),
                      heightSpacer(size.height * 0.005),
                      Builder(
                        builder: (context) {
                          if (attendanceEmp.isloderings) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: size.height * 0.01),
                              child: Row(
                                children: List.generate(7, (index) {
                                  if (index.isOdd) return const SizedBox(width: 8);
                                  return Expanded(
                                    child: Shimmer(
                                      child: Container(
                                        height: size.height * 0.055,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }

                          String adminTotal = attendanceEmp.selectedEmploye?.totalhours?.toString() ?? '0';
                          String userTotal = curentUser['Totalhours']?.toString() ?? '0';
                          String dynamicTotal = (curentUser['Role'] == 'Admin' ? adminTotal : userTotal);
                          if (dynamicTotal == '0' || dynamicTotal == '0.0' || dynamicTotal == '0:0' || dynamicTotal == '') {
                            dynamicTotal = attendanceEmp.expectedTotalHours.isEmpty ? '0' : attendanceEmp.expectedTotalHours;
                          }
                          
                            final totalHoursVal = '${attendanceEmp.showUserTotalHours} / $dynamicTotal';
                          final totalBreakVal = attendanceEmp.totalBreakHours.isEmpty ? '0 : 0' : attendanceEmp.totalBreakHours;
                          final paidLeaveVal = attendanceEmp.paidLeaveHours.isEmpty ? '0 : 0' : attendanceEmp.paidLeaveHours;
                          final holidayVal = attendanceEmp.holidayHoursCount.isEmpty ? '0 : 0' : attendanceEmp.holidayHoursCount;
  
                          final activeWidgets = <Widget>[];
  
                          if (!_isZeroValue(totalHoursVal)) {
                            activeWidgets.add(_compactSummaryTile(context, size, totalHoursString, totalHoursVal, ColorConst.themeColor));
                          }
                          if (!_isZeroValue(totalBreakVal)) {
                            activeWidgets.add(_compactSummaryTile(context, size, totalBreakString, totalBreakVal, ColorConst.red));
                          }
                          if (!_isZeroValue(paidLeaveVal)) {
                            activeWidgets.add(_compactSummaryTile(context, size, paidLeaveHrsString, paidLeaveVal, ColorConst.paidLeaveColor));
                          }
                          if (!_isZeroValue(holidayVal)) {
                            activeWidgets.add(_compactSummaryTile(context, size, holidayHrsString, holidayVal, ColorConst.holidayColor));
                          }
  
                          if (activeWidgets.isEmpty) {
                            return const SizedBox.shrink();
                          }
  
                          return Padding(
                            padding: EdgeInsets.only(bottom: size.height * 0.01),
                            child: Row(
                              children: List.generate(activeWidgets.length * 2 - 1, (index) {
                                if (index.isOdd) {
                                  return const SizedBox(width: 8);
                                }
                                return Expanded(child: activeWidgets[index ~/ 2]);
                              }),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
          
              heightSpacer(size.height * 0.02),
          
              Padding(
padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                child: Column(
                  children: [
                        
                    heightSpacer(size.height * 0.015),
                    SizedBox(
                      height: size.height * 0.45,
                      // Show the same clean shimmer for BOTH arrow-button nav and
                      // manual swipe by checking islodering at the widget level.
                      child: (_isMonthChanging || attendanceEmp.islodering)
                          ? _buildCalendarShimmer(size)
                          : MonthView(
                        key: _monthViewKey,
                        controller: attendanceEmp.eventController,
                        monthViewStyle: MonthViewStyle(
                          showBorder: false,
                          showWeekTileBorder: false,
                          minMonth: DateTime(2020),
                          maxMonth: DateTime(DateTime.now().year, DateTime.now().month),
                          cellAspectRatio: 1,
                          startDay: WeekDays.sunday,
                          initialMonth: attendanceEmp.currentMonth,
                        ),
                        monthViewBuilders: MonthViewBuilders(
                          headerBuilder: (date) {
                          return const SizedBox.shrink();
                        },
                          weekDayBuilder: (day) {
                          final weekDays = [monString, tueString, wedString, thuString, friString, satString, sunString];
                          return Center(
                            child: Text(
                              weekDays[day % 7],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                          onPageChange: (date, pageIndex) async {
                          // _isMonthChanging stays true for the entire arrow-tap sequence
                          // (including animateToMonth), so this correctly blocks the
                          // duplicate API call that causes shimmer flicker.
                          if (_isMonthChanging) return;
                          // ── Perf log: calendar swipe navigation ───────
                          AttendancePerformanceLogger.instance.startSession('CalendarSwipe → ${date.year}-${date.month}');
                          try {
                            await AttendancePerformanceLogger.instance.track(
                              'onMonthChanged [top-level orchestrator]',
                              () => attendanceEmp.onMonthChanged(date, _currentEmpData, context),
                            );
                            await AttendancePerformanceLogger.instance.track(
                              'getDuration [top-level orchestrator]',
                              () => attendanceEmp.getDuration(context, _currentEmpData),
                            );
                          } finally {
                            AttendancePerformanceLogger.instance.printSummary();
                          }
                        },
                          cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
                          int showType = 0;
                          bool isAfter10AM = false;
                          if(date.isAfter(DateTime.now())){
                            showType = 3;
                          } else{
                            bool isDataLoadedForCurrentMonth = attendanceEmp.getMonthAttenDance.isNotEmpty && 
                                attendanceEmp.loadedMonth.year == attendanceEmp.currentMonth.year &&
                                attendanceEmp.loadedMonth.month == attendanceEmp.currentMonth.month;
                            if (!isDataLoadedForCurrentMonth) {
                              showType = 8;
                            } else {
                              if(attendanceEmp.getUserShift != null){
                              //---------------------------Check Monday Holiday-------------------\\
                              if(attendanceEmp.getUserShift!.mon == false && date.weekday == 1){
                                   showType = 7;
                                  }
                                  //---------------------------Check Tuesday Holiday-------------------\\
                                  if(attendanceEmp.getUserShift!.tue == false && date.weekday == 2){
                                   showType = 7;
                                  }
                                //---------------------------Check Wednesday Holiday-------------------\\
                                 if(attendanceEmp.getUserShift!.wed == false && date.weekday == 3){
                                   showType = 7;
                                  }
                                      //---------------------------Check Thursday Holiday-------------------\\
                              if(attendanceEmp.getUserShift!.thu == false && date.weekday == 4){
                                   showType = 7;
                                  }
                                        //---------------------------Check Friday Holiday-------------------\\
                                  if(attendanceEmp.getUserShift!.fri == false && date.weekday == 5){
                                   showType = 7;
                                  }
                                        //---------------------------Check Saturday Holiday-------------------\\
                                if(attendanceEmp.getUserShift!.sat == false && date.weekday == 6){
                                   showType = 7;
                                  }
                                //---------------------------Check  Sunday Holiday  -------------------\\
                                 if(attendanceEmp.getUserShift!.sun == false && date.weekday == 7){
                                  //  attendanceEmp.totalAbset = attendanceEmp.totalAbset + 1;
                                   showType = 7;
                                  }
                             }

                             //----------------------------------Check For  Holidays --------------------------------------------\\
                              for (var element in attendanceEmp.curentMonthHoliday) { 
                                if (element.holidayDate == null) continue;
                                DateTime setDate = DateTime.parse(element.holidayDate.toString()).toLocal();
                                if (setDate.year == date.year && setDate.month == date.month && setDate.day == date.day) {
                                 showType = 2;
                                }
                              }

                              for (var element in attendanceEmp.getMonthAttenDance) { 
                                if (element.attendenceDate == null) continue;
                                DateTime setDate = DateTime.parse(element.attendenceDate.toString()).toLocal();
                                bool isSameDay = setDate.year == date.year && setDate.month == date.month && setDate.day == date.day;
                                
                                if (isSameDay) {
                                  bool present = element.present == true;
                                  bool isOnLeave = _parseBool(element.isOnLeave);
                                  String leaveGroup = (element.leaveGroup ?? '').toString().toLowerCase().trim();

                                  bool isonleaves = isOnLeave && leaveGroup == "paid";
                                  bool isonleavesUnPaid = isOnLeave && leaveGroup == "unpaid";

                                  if(isonleaves){
                                    showType = 4;
                                  }
                                  if(isonleavesUnPaid){
                                    showType = 9;
                                  }

                                  if(present){
                                    if(element.inTime != null){
                                       String? beginTimeStr = attendanceEmp.shiftBeginTime ?? (attendanceEmp.getUserShift?.beginTime?.toString());
                                       if(beginTimeStr != null && beginTimeStr != 'null'){
                                         try {
                                           DateTime useTime = DateTime.parse(beginTimeStr);
                                           DateTime currentTime = DateTime.parse(element.inTime.toString());
                                           DateTime punchInTimeOnly = DateTime(2000, 1, 1, currentTime.hour, currentTime.minute, currentTime.second);
                                           DateTime beginTimeOnly = DateTime(2000, 1, 1, useTime.hour, useTime.minute, useTime.second);
                                           isAfter10AM = punchInTimeOnly.isAfter(beginTimeOnly);
                                         } catch (e) {
                                           isAfter10AM = false;
                                         }
                                       }else{
                                         isAfter10AM = false;
                                       }
                                    }
                                    showType = 1;
                                  }

                                  for (var holiday in attendanceEmp.curentMonthHoliday) { 
                                    if (holiday.holidayDate == null) continue;
                                    DateTime holidaydates = DateTime.parse(holiday.holidayDate.toString()).toLocal();
                                    if (setDate.year == holidaydates.year && setDate.month == holidaydates.month && setDate.day == holidaydates.day) {
                                      showType = 5;
                                    }
                                  }
                                }
                              }
                            }
                          }
                          return date.month == attendanceEmp.currentMonth.month ?  Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: showType == 8 ? ColorConst.grey.withOpacity(0.4) : showType == 7 ? ColorConst.greyColor :  showType == 3?ColorConst.greyColor : showType == 1 ? isAfter10AM == true ?     ColorConst.present :  ColorConst.present.withOpacity(0.7) :  showType == 2 ? ColorConst.holidayColor : showType == 4 ? ColorConst.paidLeaveColor   : showType== 9 ? ColorConst.blueColor :   ColorConst.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: ColorConst.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ) : Container();
                        },

                        onCellTap: (events, date) async {
                          _triggerCellTap(date);
                        },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _triggerCellTap(DateTime date) async {
    final attendanceEmp = Provider.of<AttendanceEmp>(context, listen: false);
    final leaveProviders =  Provider.of<LeaveMastServices>(context, listen: false);
    final adminAttenDanceServices = Provider.of<AdminAttenDanceServices>(context, listen: false);
    final size = MediaQuery.of(context).size;

    attendanceEmp.setloading(true);
                          leaveDurationTypesShow = '';
                          leaveStatusShow = '';

                          leaveProviders.mainallLeavesData.forEach((element) {
                            if (element.fromDate != null && element.toDate != null) {
                              DateTime fDate = DateTime.parse(element.fromDate!).toLocal();
                              DateTime tDate = DateTime.parse(element.toDate!).toLocal();
                              DateTime checkDate = DateTime(date.year, date.month, date.day);
                              DateTime fDateOnly = DateTime(fDate.year, fDate.month, fDate.day);
                              DateTime tDateOnly = DateTime(tDate.year, tDate.month, tDate.day);

                              if (checkDate.isAtSameMomentAs(fDateOnly) || 
                                  checkDate.isAtSameMomentAs(tDateOnly) || 
                                  (checkDate.isAfter(fDateOnly) && checkDate.isBefore(tDateOnly))) {
                                
                                leaveDurationTypesShow = element.leaveDuration == '0.5' ? 'Half Day' :'';
                                leaveStatusShow = element.approveStatus == 'A' ? 'Approved' : element.approveStatus == 'P' ? 'Pending' : element.approveStatus == 'R' ? 'Rejected' : '';
                                leaveResons = element.remarks;
                              }
                            } else if (element.fromDate != null) {
                               DateTime setDate = DateTime.parse(element.fromDate ??'');
                               if(setDate.day == date.day && setDate.month == date.month  && setDate.year == date.year){
                                 leaveDurationTypesShow = element.leaveDuration == '0.5' ? 'Half Day' :'';
                                 leaveStatusShow = element.approveStatus == 'A' ? 'Approved' : element.approveStatus == 'P' ? 'Pending' : element.approveStatus == 'R' ? 'Rejected' : '';
                                 leaveResons = element.remarks;
                               }
                            }
                          },);

                          attendanceEmp.setShowTimeValues(date);
                          DateTime usedTapDate = DateTime(date.year,date.month,date.day);

                          Provider.of<PayRollProviders>(context, listen: false).getMonthsBreaks(setMonth: usedTapDate.month, setYear: usedTapDate.year, setEmployeId: curentUser['Id']);
                          if (date.isBefore(DateTime.now())) {
                            String showdayname = DateFormat('EEEE').format(
                                    DateTime(date.year, date.month, date.day));
                             int finderindex = attendanceEmp.getMonthAttenDance.indexWhere((element) => date.isAtSameMomentAs(DateTime.parse(element.attendenceDate.toString())));

                             if (attendanceEmp.getUserShift != null) {
                                  if (attendanceEmp.getUserShift!.mon != null && attendanceEmp.getUserShift!.sun == false &&
                                          showdayname.toString().substring(0, 3).toLowerCase() == 'sun' ||
                                      attendanceEmp.getUserShift!.mon == false &&
                                          showdayname.toString().substring(0, 3).toLowerCase() == 'mon' ||
                                      attendanceEmp.getUserShift!.tue! == false &&
                                          showdayname.toString().substring(0, 3).toLowerCase() == 'tue' ||
                                      attendanceEmp.getUserShift!.wed == false &&
                                          showdayname.toString().substring(0, 3).toLowerCase() =='wed' ||
                                      attendanceEmp.getUserShift!.thu == false &&
                                          showdayname.toString().substring(0, 3).toLowerCase() == 'thru' ||
                                      attendanceEmp.getUserShift!.fri == false &&
                                          showdayname.toString().substring(0, 3).toLowerCase() == 'fri' ||
                                      attendanceEmp.getUserShift!.sat == false &&
                                          showdayname.toString().substring(0, 3).toLowerCase() == 'sat') {
                                
                                          attendanceEmp.setShowDateType(7);
                                          if(attendanceEmp.showDateType == 7){
                             
                                            int findweekOffPunch = Provider.of<AttendanceEmp>(context, listen: false).getMonthAttenDance.indexWhere((element) =>  DateTime.parse(element.attendenceDate.toString()) == usedTapDate && element.present  == true);

                                            if(findweekOffPunch != -1){
                                              String timestampString = date.toString();
                                              String formattedTimestampString = timestampString.replaceAll('Z', '');
                                              attendanceEmp.setShowDateType(1);
                                              await attendanceEmp.getDateBloges(formattedTimestampString, _currentEmpData != null ? _currentEmpData!.empId : '${curentUser['Id']}');
                                            }
                                          }
                                          showDayDetails(context,size, attendanceEmp.selectedDateLog,date.toString(),7, attendanceEmp, Provider.of<AdminAttenDanceServices>(context, listen: false), curentUser, _currentEmpData, leaveTypesShow: leaveTypesShow, leaveDurationTypesShow: leaveDurationTypesShow, leaveStatusShow: leaveStatusShow, leaveResons: leaveResons);
                                      } else {
                                        int findHoliday = attendanceEmp.curentMonthHoliday.indexWhere((element) => date.isAtSameMomentAs(DateTime.parse(element.holidayDate.toString())));

                                        if (findHoliday != -1) {
                                          
                                          attendanceEmp.setShowDateType(2);
                                            showDayDetails(context,size, attendanceEmp.selectedDateLog,date.toString(),2, attendanceEmp, Provider.of<AdminAttenDanceServices>(context, listen: false), curentUser, _currentEmpData, leaveTypesShow: leaveTypesShow, leaveDurationTypesShow: leaveDurationTypesShow, leaveStatusShow: leaveStatusShow, leaveResons: leaveResons);
                                        } else {
                                          String timestampString = date.toString();
                                          String formattedTimestampString = timestampString.replaceAll('Z', '');
                                          await attendanceEmp.getDateBloges(formattedTimestampString,_currentEmpData != null ? _currentEmpData!.empId : '${curentUser['Id']}');
                                          
                                          // Check for leaves
                                          int leaveIndex = attendanceEmp.getMonthAttenDance.indexWhere((element) {
                                            if (element.attendenceDate == null) return false;
                                            DateTime asusedData = DateTime.parse(element.attendenceDate.toString()).toLocal();
                                            return asusedData.year == date.year && asusedData.month == date.month && asusedData.day == date.day;
                                          });

                                          int typeToPass = 1;
                                          if (leaveIndex != -1) {
                                            var element = attendanceEmp.getMonthAttenDance[leaveIndex];
                                            bool isOnLeave = _parseBool(element.isOnLeave);
                                            String leaveGroup = (element.leaveGroup ?? '').toString().toLowerCase().trim();
                                            if (isOnLeave && leaveGroup == "paid") {
                                              typeToPass = 4;
                                            } else if (isOnLeave && leaveGroup == "unpaid") {
                                              typeToPass = 9;
                                            }
                                            
                                            if (isOnLeave) {
                                              leaveTypesShow = element.leaveTypeFName?.toString() ?? '';
                                              leaveResons = element.remarks?.toString() ?? leaveResons;
                                            }
                                          }

                                        attendanceEmp.setShowDateType(typeToPass);
                                        showDayDetails(context,size,attendanceEmp.selectedDateLog,date.toString(),typeToPass, attendanceEmp, Provider.of<AdminAttenDanceServices>(context, listen: false), curentUser, _currentEmpData, leaveTypesShow: leaveTypesShow, leaveDurationTypesShow: leaveDurationTypesShow, leaveStatusShow: leaveStatusShow, leaveResons: leaveResons);
                                      }
                                  }
                                }
                          }
                          attendanceEmp.setloading(false);
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    String valStr = value.toString().toLowerCase().trim();
    return valStr == 'true' || valStr == '1' || valStr == 'yes';
  }

  bool _isZeroValue(String value) {
    String check = value.trim().toLowerCase();
    if (check.isEmpty) return true;
    if (check.contains('/')) {
      check = check.split('/').first.trim();
    }
    check = check.replaceAll(' ', '');
    if (check == '0' || check == '0:0' || check == '0.0' || check == '0min' || check == '0hr') {
      return true;
    }
    return false;
  }

  /// A calendar-shaped shimmer shown while arrow-button month navigation
  /// is in progress. Replaces the whole MonthView widget so there are no
  /// blank cells or half-rendered shimmer rows during loading.
  Widget _buildCalendarShimmer(Size size) {
    return Column(
      children: [
        // Week-day label row (Mon … Sun)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: List.generate(7, (_) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: shimmerBox(height: 14, radius: BorderRadius.circular(4)),
              ),
            )),
          ),
        ),
        // Calendar cell grid (5 weeks × 7 days)
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 35,
            itemBuilder: (context, index) => shimmerBox(radius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }


}

Widget _compactSummaryTile(BuildContext context, Size size, String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConst.greyOpicityColor,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: size.width * 0.026,
              color: Colors.grey,
              fontFamily: fontInterMediumString,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          num.tryParse(value) != null
              ? AnimatedCountText(
                  value: num.parse(value),
                  style: TextStyle(
                    fontSize: size.width * 0.030,
                    fontWeight: FontWeight.w700,
                    fontFamily: fontInterBoldString,
                    color: ColorConst.black,
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: size.width * 0.030,
                    fontWeight: FontWeight.w700,
                    fontFamily: fontInterBoldString,
                    color: ColorConst.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }


  String? leaveTypesShow;
  String? leaveDurationTypesShow;
  String? leaveStatusShow;
  String?  leaveResons;

  Future<void> showDayDetails(BuildContext context,Size size,AttendanceDayBlog? setDataLog,String? showdate,int selectedDatTypes, AttendanceEmp attendanceEmp, AdminAttenDanceServices adminAttenDanceServices, dynamic curentUser, dynamic currentEmpData, {String? leaveTypesShow, String? leaveDurationTypesShow, String? leaveStatusShow, String? leaveResons}) async {
    attendanceEmp.totalHour = '';
    attendanceEmp.totalWorkHour = '';
    attendanceEmp.totalbreaks = '';
    if (setDataLog != null && setDataLog.attendence != null && setDataLog.attendence!.attendenceDate != null) {
      attendanceEmp.getMonthAttenDance.forEach((element) {
        DateTime asusedData = DateTime.parse(element.attendenceDate.toString());
        if (DateTime.parse(setDataLog.attendence!.attendenceDate.toString()) == asusedData) {
          leaveTypesShow = element.leaveTypeFName.toString();
          leaveResons= element.remarks.toString();
        }
      });
      attendanceEmp.attendanceCalculate(context);
    }
    if(curentUser['Role'] == 'Admin') {
      await adminAttenDanceServices.leaveEditTypeSet(context, currentEmpData!);
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ColorConst.white,
      builder: (BuildContext context) {

        int setindexs = 0;

        if(selectedDatTypes == 2){
          setindexs = Provider.of<AttendanceEmp>(context,listen: false).curentMonthHoliday.indexWhere((element) => DateTime.parse(element.holidayDate.toString()) == DateTime.parse(showdate.toString()));
        }
        //-------------------  Showing Absent -------------------\\
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: setDataLog == null ? 0.7 : (setDataLog.attendenceLog == null || setDataLog.attendenceLog!.isEmpty) ? 0.4 : 0.7,
            minChildSize: 0.25,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
                    return selectedDatTypes == 0 ? SizedBox(
                      height: size.height * 0.2,
                      width: size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          heightSpacer(size.height *0.02),
                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                            child: Text(dateFormatddMMMyyyy(DateTime.parse(setDataLog!.attendence!.attendenceDate.toString())),style: TextStyle(fontSize: size.height *0.022,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                          ),

                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.03,top: size.height * 0.02),
                            child:  AttendancTypeContainer(size, 'Absent', ColorConst.red),
                          ),
                          const  Divider()
                        ],
                      ),
                    ):
                    //--------------------------  WeekOff----------------------\\
                    selectedDatTypes == 7 ? SizedBox(
                      height: size.height * 0.2,
                      width: size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          heightSpacer(size.height *0.02),
                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                            child: Text(dateFormatddMMMyyyy(DateTime.parse(showdate.toString())),style: TextStyle(fontSize: size.height *0.022,fontWeight: FontWeight.bold),    textAlign: TextAlign.end,),
                          ),

                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.03,top: size.height * 0.02),
                            child:  AttendancTypeContainer(size, weekOffString, Colors.grey.shade800),
                          ),
                          const  Divider()

                        ],
                      ),
                    ) : selectedDatTypes == 2 ? SizedBox(
                      height: size.height * 0.25,
                      width: size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heightSpacer(size.height *0.02),
                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                            child: Text(dateFormatddMMMyyyy(DateTime.parse(showdate.toString())),style: TextStyle(fontSize: size.height *0.022,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                          ),

                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.03,top: size.height * 0.02),
                            child:  AttendancTypeContainer(size, 'Holiday', ColorConst.holidayColor),
                          ),
                          const  Divider(),
                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.02,right: size.width * 0.02),
                            child: Text('Holiday Name :-  ${Provider.of<AttendanceEmp>(context,listen: false).curentMonthHoliday[setindexs].holidayName}',style: normalHeadingText      (size),maxLines: 1,overflow: TextOverflow.ellipsis,),
                          ),

                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.02,right: size.width * 0.02,top: size.height * 0.01),
                            child: Text('Description :- ${Provider.of<AttendanceEmp>(context,listen: false).curentMonthHoliday[setindexs].description}',style:       customeHeadingTextsize(size,size.height * 0.017),maxLines: 2,overflow: TextOverflow.ellipsis,),
                          ),
                        ],
                      ),
                    ): selectedDatTypes == 4 || selectedDatTypes == 9 ? SizedBox(
                      height: size.height * 0.25,
                      width: size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heightSpacer(size.height *0.02),
                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                            child: Text(dateFormatddMMMyyyy(DateTime.parse(showdate.toString())),style: TextStyle(fontSize: size.height *0.022,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                          ),

                          Padding(
                            padding:  EdgeInsets.only(left: size.width * 0.03,top: size.height * 0.02),
                            child: Wrap(
                              spacing: size.width * 0.02,
                              runSpacing: size.height * 0.01,
                              children: [
                                AttendancTypeContainer(size, 'On Leave', Colors.red.shade400),
                                AttendancTypeContainer(size, (leaveTypesShow != null && leaveTypesShow != 'null' && leaveTypesShow!.isNotEmpty) ? '$leaveTypesShow' : (selectedDatTypes == 4 ? 'Paid Leave' : 'Unpaid Leave'), selectedDatTypes == 4 ? ColorConst.paidLeaveColor : ColorConst.blueColor),
                                if (leaveDurationTypesShow != null && leaveDurationTypesShow.isNotEmpty)
                                  AttendancTypeContainer(size, leaveDurationTypesShow, selectedDatTypes == 4 ? ColorConst.paidLeaveColor : ColorConst.blueColor),
                                if (leaveStatusShow != null && leaveStatusShow.isNotEmpty)
                                  AttendancTypeContainer(size, leaveStatusShow, leaveStatusShow == 'Approved' ? Colors.green : leaveStatusShow == 'Pending' ? Colors.orange : Colors.red),
                              ],
                            ),
                          ),
                          const  Divider(),
                          
                          if (leaveResons != null && leaveResons != 'null' && leaveResons!.isNotEmpty) ...[
                            Padding(
                              padding:  EdgeInsets.only(left: size.width * 0.03,right: size.width * 0.02,top: size.height * 0.01),
                              child: Text('Reason : $leaveResons',style: TextStyle(fontWeight: FontWeight.bold),maxLines: 2,overflow: TextOverflow.ellipsis,),
                            ),
                          ]
                        ],
                      ),
                    ):   Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heightSpacer(5),
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        heightSpacer(size.height *0.01),

                        heightSpacer(size.height *0.01),

                        setDataLog!.attendence != null?
                        Padding(
                          padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                          child: Text(dateFormatddMMMyyyy(DateTime.parse(setDataLog.attendence!.attendenceDate.toString())),style: TextStyle(fontSize: size.height *0.022,fontWeight: FontWeight.bold),textAlign: TextAlign.end,),
                        ):Container(),

                        curentUser['Role'] == 'Admin' ? Container() :
                        Padding(
                          padding:  EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
                          child: Row(
                            children: [
                              Expanded(child: _compactSummaryTile(context, size, 'Total Hours', '${attendanceEmp.totalHour.isEmpty ? '0' : attendanceEmp.totalHour} Hr', ColorConst.themeColor)),
                              SizedBox(width: 8),
                              Expanded(child: _compactSummaryTile(context, size, 'Break Time', '${attendanceEmp.totalbreaks == null || attendanceEmp.totalbreaks == '' || attendanceEmp.totalbreaks == 0 || attendanceEmp.totalbreaks == '0' ? '0 Min' : attendanceEmp.totalbreaks}', ColorConst.red)),
                              SizedBox(width: 8),
                              Expanded(child: _compactSummaryTile(context, size, 'Work Hours', attendanceEmp.totalWorkHour.isEmpty ? '0 Min' : attendanceEmp.totalWorkHour, ColorConst.greenColor)),
                            ],
                          ),
                        ),

                        curentUser['Role'] == 'Admin' ? Padding(
                          padding:  EdgeInsets.symmetric(horizontal: size.width *0.015),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SelectionView(presentString, adminAttenDanceServices.selectedPresent == true ? Colors.green :  ColorConst.white,
                                      adminAttenDanceServices.selectedPresent == true ? ColorConst.white  : Colors.green,(){
                                        adminAttenDanceServices.setPresentSelection(true);

                                        showDialog(context: context, builder: (context) => AddPunchFromAdmin(currentEmpData!, showdate.toString())).then((value){

                                          String timestampString =   DateTime.parse(showdate.toString()).toString();
                                          String formattedTimestampString = timestampString.replaceAll('Z', '');

                                          attendanceEmp.getDateBloges(formattedTimestampString,currentEmpData!.empId);
                                          attendanceEmp.onMonthChanged(attendanceEmp.currentMonth, currentEmpData, context);
                                          attendanceEmp.getDuration(context, currentEmpData);
                                        });
                                      }),
                                  widthSpacer(size.width *0.02),
                                  SelectionView(absentString,adminAttenDanceServices.selectedPresent == false ? Colors.redAccent : ColorConst.white, adminAttenDanceServices.selectedPresent == false ? ColorConst.white: Colors.red,(){
                                    adminAttenDanceServices.setAbsentEmployes(
                                      attendanceDate: setDataLog.attendence!.attendenceDate,
                                      context: context,
                                      setEmpid: currentEmpData!.empId,
                                      setattendanceCguid: currentEmpData!.cguid,
                                    ).then((value) {
                                      attendanceEmp.onMonthChanged(attendanceEmp.currentMonth, currentEmpData, context);
                                      attendanceEmp.getDuration(context, currentEmpData);
                                      Navigator.pop(context);
                                    },);
                                  }),

                                ],
                              ),
                              heightSpacer(size.height *0.01),

                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: Provider.of<LeaveEmployeeeMastServices>(context,listen: false).getAllleaveTypesList.map((item) {
                                  return    SelectionView(item.leaveTypeFName.toString(),
                                      adminAttenDanceServices.selectedLeaveTypes == null ? ColorConst.white : adminAttenDanceServices.selectedLeaveTypes!.leaveTypeId == item.leaveTypeId ? Colors.blue :ColorConst.white,
                                      adminAttenDanceServices.selectedLeaveTypes == null ? Colors.blue: adminAttenDanceServices.selectedLeaveTypes!.leaveTypeId == item.leaveTypeId ? ColorConst.white :Colors.blue,(){
                                        adminAttenDanceServices.toggleLeaveType(item);
                                        adminAttenDanceServices.applyLeaveData(context, currentEmpData!).then((_) {
                                          attendanceEmp.onMonthChanged(attendanceEmp.currentMonth, currentEmpData, context);
                                          attendanceEmp.getDuration(context, currentEmpData);
                                        });
                                        Navigator.pop(context);
                                      });
                                }).toList(),
                              ),
                            ],
                          ),
                        ) :

                        setDataLog.attendence!= null?
                        setDataLog.attendence!.present == true?   Padding(
                          padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                          child:  AttendancTypeContainer(size, 'Present', ColorConst.themeColor),
                        ):
                        setDataLog.attendence!.isOnLeave  == true ?
                        Padding(
                          padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: size.width * 0.02,
                                runSpacing: size.height * 0.01,
                                children: [
                                  AttendancTypeContainer(size, 'On Leave', Colors.red.shade400),
                                  AttendancTypeContainer(size, (leaveTypesShow != null && leaveTypesShow != 'null' && leaveTypesShow!.isNotEmpty) ? '$leaveTypesShow' : 'Paid Leave', (leaveTypesShow?.toUpperCase() == 'PAID LEAVE' || leaveTypesShow == null || leaveTypesShow == 'null' || leaveTypesShow!.isEmpty) ? ColorConst.paidLeaveColor : ColorConst.blueColor),
                                  if (leaveDurationTypesShow != null && leaveDurationTypesShow.isNotEmpty)
                                    AttendancTypeContainer(size, leaveDurationTypesShow, (leaveTypesShow?.toUpperCase() == 'PAID LEAVE' || leaveTypesShow == null || leaveTypesShow == 'null' || leaveTypesShow!.isEmpty) ? ColorConst.paidLeaveColor : ColorConst.blueColor),
                                  if (leaveStatusShow != null && leaveStatusShow.isNotEmpty)
                                    AttendancTypeContainer(size, leaveStatusShow, leaveStatusShow == 'Approved' ? Colors.green : leaveStatusShow == 'Pending' ? Colors.orange : Colors.red),
                                ],
                              ),
                              heightSpacer(size.height * 0.01),

                              if (leaveResons != null && leaveResons != 'null' && leaveResons!.isNotEmpty)
                                Text('Reason : $leaveResons',style: TextStyle(fontWeight: FontWeight.bold, ),maxLines: 2,overflow: TextOverflow.ellipsis,),
                            ],
                          ),
                        ):


                        Padding(
                          padding:  EdgeInsets.only(left: size.width * 0.05,top: size.height * 0.01),
                          child: AttendancTypeContainer(size, 'Absent', Colors.red.shade400),
                        ): Container(),
                        heightSpacer(size.height * 0.01),

                        if (setDataLog.attendenceLog != null && setDataLog.attendenceLog!.isNotEmpty)
                          Expanded(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: setDataLog.attendenceLog!.length,
                              padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                              separatorBuilder: (context, index) {
                                return heightSpacer(size.height * 0.015);
                              },
                              itemBuilder: (context, index) {
                                final isDark = Theme.of(context).brightness == Brightness.dark;
                                return Container(
                                  padding: EdgeInsets.all(size.width * 0.03),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.transparent : Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if(setDataLog.attendenceLog![index].fileURL != null) {
                                            nextScreen(context, FullPageImage(setDataLog.attendenceLog![index].fileURL ?? '', ''), onthenValue: (value) {});
                                          }
                                        },
                                        child: Container(
                                          height: size.width * 0.16,
                                          width: size.width * 0.16,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey.shade800 : ColorConst.grey.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadiusGeometry.circular(10),
                                            child: CachedNetworkImage(
                                              imageUrl: setDataLog.attendenceLog![index].fileURL ?? '',
                                              placeholder: (context, url) =>  Center(child: CircularProgressIndicator(color: ColorConst.themeColor, strokeWidth: 2)),
                                              errorWidget: (context, url, error) => Icon(Icons.person, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 30),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),

                                      widthSpacer(size.width * 0.03),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.005),
                                                  decoration: BoxDecoration(
                                                    color: setDataLog.attendenceLog![index].status == "IN" ? ColorConst.themeColor.withOpacity(0.15) : ColorConst.red.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: setDataLog.attendenceLog![index].status == "IN" ? ColorConst.themeColor.withOpacity(0.3) : ColorConst.red.withOpacity(0.3)),
                                                  ),
                                                  child: Text(
                                                    setDataLog.attendenceLog![index].status == "IN" ? punchInString : punchOutString,
                                                    style:  TextStyle(color: setDataLog.attendenceLog![index].status == "IN" ? ColorConst.themeColor : ColorConst.red, fontSize: 12, fontFamily: fontInterSemiBoldString, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                widthSpacer(size.width * 0.02),
                                                Text(setDataLog.attendenceLog![index].time == null? '' : DateFormat.jm().format(DateTime.parse(setDataLog.attendenceLog![index].time.toString())), style: TextStyle(fontFamily: fontInterBoldString, fontWeight: FontWeight.bold, fontSize: 14)),

                                              if(curentUser['Role'] == 'Admin') ...{
                                                Spacer(),
                                                GestureDetector(
                                                  onTap: () async {
                                                    showDialog(context: context, builder: (context) => CustomDialog(setDataLog.attendenceLog![index], setDataLog.attendence?.cguid ?? currentEmpData!.cguid ?? '', (setDataLog.attendence?.attendenceID ?? currentEmpData!.attendenceID).toString(), 'Log Update', false)).then((value) {
                                                      String timestampString = DateTime.parse(showdate.toString()).toString();
                                                      String formattedTimestampString = timestampString.replaceAll('Z', '');
                                                      attendanceEmp.getDateBloges(formattedTimestampString, currentEmpData!.empId);
                                                      attendanceEmp.onMonthChanged(attendanceEmp.currentMonth, currentEmpData, context);
                                                      attendanceEmp.getDuration(context, currentEmpData);
                                                      Navigator.pop(context);
                                                    });
                                                  },
                                                  child: Container(
                                                      decoration: BoxDecoration(
                                                        color: ColorConst.grey.withOpacity(.4),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      padding: EdgeInsets.all(size.width * 0.015),
                                                      child: Icon(Icons.edit)
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () async {
                                                    showDeleteDialog(context, size, noOnTap: () => Navigator.pop(context), yesOntap: () {
                                                      adminAttenDanceServices.deletePunchlog(attendanceId: setDataLog.attendence?.attendenceID ?? currentEmpData!.attendenceID, setEmpid: setDataLog.attendenceLog![index].empId, setLogId: setDataLog.attendenceLog![index].logId, setStatus: setDataLog.attendenceLog![index].status).then((value) {
                                                        String timestampString = DateTime.parse(showdate.toString()).toString();
                                                        String formattedTimestampString = timestampString.replaceAll('Z', '');
                                                        attendanceEmp.getDateBloges(formattedTimestampString, currentEmpData!.empId);
                                                        attendanceEmp.onMonthChanged(attendanceEmp.currentMonth, currentEmpData, context);
                                                        attendanceEmp.getDuration(context, currentEmpData);
                                                        
                                                        Navigator.pop(context); // Pops Delete Dialog
                                                        Navigator.pop(context); // Pops Bottom Sheet
                                                      },);
                                                    });
                                                  },
                                                  child: Container(
                                                      decoration: BoxDecoration(
                                                        color: ColorConst.grey.withOpacity(.4),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      margin: EdgeInsets.only(left: size.width * 0.015),
                                                      padding: EdgeInsets.all(size.width * 0.015),
                                                      child: Icon(Icons.delete, color: ColorConst.red)
                                                  ),
                                                ),
                                              }
                                            ],
                                          ),

                                          heightSpacer(size.height * 0.01),

                                          setDataLog.attendenceLog![index].location == '' || setDataLog.attendenceLog![index].location == null ? Container() : Row(
                                            children: [
                                              Icon(Icons.location_on, size: 14, color: Colors.grey),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  setDataLog.attendenceLog![index].location ?? "",
                                                  style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: fontInterRegularString, fontWeight: FontWeight.w400),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                                );
                              },
                            ),
                          ),

                      curentUser['Role'] == 'Admin' ?
                        Padding(
                          padding: EdgeInsets.all(size.width * 0.03),
                          child: GestureDetector(
                            onTap: () async {
                              showDialog(context: context, builder: (context) => AddPunchFromAdmin(currentEmpData!, showdate.toString())).then((value) async {
                                String timestampString = DateTime.parse(showdate.toString()).toString();
                                String formattedTimestampString = timestampString.replaceAll('Z', '');
                                attendanceEmp.getDateBloges(formattedTimestampString, currentEmpData!.empId);
                                attendanceEmp.onMonthChanged(attendanceEmp.currentMonth, currentEmpData, context);
                                attendanceEmp.getDuration(context, currentEmpData);
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: ColorConst.darkBlueColor, size: 18),
                                    SizedBox(width: 4),
                                    Text(addPunchString, style: TextStyle(color: ColorConst.darkBlueColor, fontSize: size.width * 0.035, fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString)),
                                  ],
                                ),
                                widthSpacer(size.width * 0.015),
                                Container(
                                  height: 1.5,
                                  width: size.width * 0.25,
                                  color: ColorConst.darkBlueColor,
                                ),
                              ],
                            ),
                          ),
                        ) : Container(),
                        heightSpacer(size.height * 0.015),
                      ],
                    );
            },
          ),
        );
      },
    );
  }