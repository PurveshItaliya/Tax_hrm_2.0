// ignore_for_file: curly_braces_in_flow_control_structures, strict_top_level_inference, avoid_function_literals_in_foreach_calls, prefer_typing_uninitialized_variables, non_constant_identifier_names, empty_catches

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/api/holidayapi.dart';
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/attendance/allemployeattendance.dart';
import 'package:tax_hrm/models/attendance/attendanceBlog.dart';
import 'package:tax_hrm/models/attendance/attendanceCountings.dart';
import 'package:tax_hrm/models/attendance/monathattendace.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/holidayprovider.dart';
import 'package:tax_hrm/provider/leaveProviders.dart';
import 'package:tax_hrm/provider/payrollprovider.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/api/shiftapi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/attendance_perf_logger.dart';

class AttendanceEmp extends ChangeNotifier {
  bool islodering = false;

  /// True while prev/next/picker navigation is animating the calendar.
  /// Prevents [onMonthChanged] (fired by the calendar's onPageChange) from
  /// making a duplicate API call when the navigation arrow already called one.
  bool isNavigatingMonth = false;

  bool get isloderings => islodering;
  DateTime loadedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  String? shiftBeginTime;

  Future<void> fetchAndStoreBeginTime(BuildContext context, String? positionName) async {
    if (positionName == null || positionName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    bool isCurrentUser = (selectedEmploye == null);
    String localKey = 'user_begin_time_${curentUser['Id']}_$positionName';
    String localEndKey = 'user_end_time_${curentUser['Id']}_$positionName';
    String localPosKey = 'user_position_name_${curentUser['Id']}';

    if (isCurrentUser) {
      await prefs.setString(localPosKey, positionName);
      String? storedTime = prefs.getString(localKey);
      if (storedTime != null && storedTime.isNotEmpty) {
        shiftBeginTime = storedTime;
        notifyListeners();
        // We do NOT return here; we continue to fetch the latest from the API in the background.
      }
    }

    try {
      final shiftList = await AttendancePerformanceLogger.instance.track(
        'ShiftApiClass.getShiftTimingMaster',
        () => ShiftApiClass().getShiftTimingMaster(),
      );
      if (shiftList != null) {
        for (var shift in shiftList) {
          if (shift.positionName != null &&
              shift.positionName.toString().trim().toLowerCase() == positionName.trim().toLowerCase()) {
            shiftBeginTime = shift.beginTime;
            if (isCurrentUser) {
              await prefs.setString(localKey, shiftBeginTime ?? '');
              await prefs.setString(localEndKey, shift.endTime ?? '');
              await prefs.setString(localPosKey, positionName);
            }
            break;
          }
        }
      }
    } catch (e) { /* ignored */ }
    notifyListeners();
  }

  loadingData(AllEmployeAttendance? empData, context, {bool forceRefresh = false}) async {
    try {
      // Only show loader if we have NO data for the current month (SWR pattern)
      bool hasCacheForCurrentMonth = getMonthAttenDance.isNotEmpty &&
          loadedMonth.month == DateTime.now().month &&
          loadedMonth.year == DateTime.now().year;
          
      if (!hasCacheForCurrentMonth || forceRefresh) {
        setloading(true);
      }
      // Always reset to current month when the screen opens so that
      // navigating away and back never leaves a stale month selected.
      currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
      shiftBeginTime = null;
      selectedEmploye = null;
      if(empData == null){
        final futureLeaves = AttendancePerformanceLogger.instance.track(
          'LeaveMastServices.getUserLeaveLists',
          () => Provider.of<LeaveMastServices>(context, listen: false).getUserLeaveLists(),
          executionMode: 'parallel',
        );

        final futureShiftData = setShiftData(empData, '', context);

        final futureBeginTime = () async {
          String? userPositionName;
          final settingProv = Provider.of<SettingProvider>(context, listen: false);
          if (settingProv.setEmpProfile != null) {
            userPositionName = settingProv.setEmpProfile!.positionName;
          } else {
            await AttendancePerformanceLogger.instance.track(
              'SettingProvider.getUserEmployeeData',
              () => settingProv.getUserEmployeeData(context),
            );
            if (settingProv.setEmpProfile != null) {
              userPositionName = settingProv.setEmpProfile!.positionName;
            }
          }
          await fetchAndStoreBeginTime(context, userPositionName);
        }();

        final futureAttendance = getEmpAttendanceData(curentUser['Id'], currentMonth.month, currentMonth.year, context, handleLoading: false, forceRefresh: forceRefresh);

        await Future.wait([futureLeaves, futureShiftData, futureBeginTime, futureAttendance]);
      } else{
        final futureLeaves = AttendancePerformanceLogger.instance.track(
          'LeaveMastServices.getUserLeaveLists',
          () => Provider.of<LeaveMastServices>(context, listen: false).getUserLeaveLists(),
          executionMode: 'parallel',
        );

        final futureEmployeeData = () async {
          var empMast = Provider.of<EmployeMastServices>(context,listen: false);
          if (empMast.allemployes.isEmpty) {
            await AttendancePerformanceLogger.instance.track(
              'EmployeMastServices.getAllEmployesData',
              () => empMast.getAllEmployesData(),
            );
          }
          for (var element in empMast.allemployes) {
            if(empData.empId == element.id) {
              selectedEmploye = element;
              final futureShift = setShiftData(element.shiftCguid, element.positionId, context);
              final futureBeginTime = fetchAndStoreBeginTime(context, element.positionName);
              final futureAttendance = getEmpAttendanceData(empData.empId, currentMonth.month, currentMonth.year, context, handleLoading: false, forceRefresh: forceRefresh);
              await Future.wait([futureShift, futureBeginTime, futureAttendance]);
              break;
            }
          }
        }();

        await Future.wait([futureLeaves, futureEmployeeData]);
      }
    } catch (e) { /* ignored */ } finally {
      setloading(false);
    }
    notifyListeners();
  }

  Employeelists? selectedEmploye;

  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  EventController eventController = EventController();

  Future<void> previousMonth(context, empData) async {
    isNavigatingMonth = true;
    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    try {
      if (empData == null) {
        await getEmpAttendanceData(curentUser['Id'], currentMonth.month, currentMonth.year, context);
      } else {
        await getEmpAttendanceData(empData.empId, currentMonth.month, currentMonth.year, context);
      }
    } finally {
      isNavigatingMonth = false;
    }
    notifyListeners();
  }

  Future<void> nextMonth(context, empData) async {
    final nowMonth = DateTime(DateTime.now().year, DateTime.now().month);
    if (currentMonth.isBefore(nowMonth)) {
      isNavigatingMonth = true;
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      try {
        if (empData == null) {
          await getEmpAttendanceData(curentUser['Id'], currentMonth.month, currentMonth.year, context);
        } else {
          await getEmpAttendanceData(empData.empId, currentMonth.month, currentMonth.year, context);
        }
      } finally {
        isNavigatingMonth = false;
      }
    }
    notifyListeners();
  }

  /// Called by the calendar widget's onPageChange. Skipped if we are already
  /// handling navigation via [previousMonth], [nextMonth], or [updateMonth].
  Future<void> onMonthChanged(DateTime focusedDay, empData, context) async {
    if (isNavigatingMonth) return; // already handled by nav buttons
    currentMonth = DateTime(focusedDay.year, focusedDay.month);
    if (empData == null) {
      await getEmpAttendanceData(curentUser['Id'], focusedDay.month, focusedDay.year, context);
    } else {
      await getEmpAttendanceData(empData.empId, currentMonth.month, currentMonth.year, context);
    }
    notifyListeners();
  }

  Future<void> updateMonth(DateTime month, empData, BuildContext context) async {
    isNavigatingMonth = true;
    currentMonth = month;
    try {
      await getEmpAttendanceData(
        empData == null ? curentUser['Id'] : empData.empId,
        currentMonth.month,
        currentMonth.year,
        context,
      );
    } finally {
      isNavigatingMonth = false;
    }
    notifyListeners();
  }

  List<AttendanceCountingClass>? setEmpAttendanc;

  num totalPresent = 0;
  num totalAbset = 0;
  num totalHalfday = 0;
  num totakWeekOff = 0;
  num totalHoliday = 0;
  num totalPaidLeave = 0;

  List<EmployeAttendance> getMonthAttenDance = [];

  void setMonthAttendance(List<EmployeAttendance> value) {
    getMonthAttenDance = value;
    notifyListeners();
  }

  List<GetHolidayViews> checkHolidayList = [];
  List<GetHolidayViews> curentMonthHoliday = [];

  int showDateType = 0;

  void setShowDateType(int value) {
    showDateType = value;
    notifyListeners();
  }

  void setShowTimeValues(DateTime value) {
    showTimeValues = value;
    notifyListeners();
  }

  Future<void> getEmpAttendanceData(setEmpid, setMonth, setYear, context, {bool handleLoading = true, bool forceRefresh = false}) async {
    final cacheKey = 'emp_attendance_${setEmpid}_${setYear}_$setMonth';
    final bool isNewMonth = !(loadedMonth.month == setMonth && loadedMonth.year == setYear);

    if (handleLoading) {
      // Only show loader if we have no data for this month yet
      if ((isNewMonth && getMonthAttenDance.isEmpty) || forceRefresh) setloading(true);
    }

    // ── Step 1: Show cached data immediately (no flicker) ──────────────────────
    if (isNewMonth && !forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final localJson = prefs.getString(cacheKey);
        if (localJson != null) {
          final cachedAttendance = employeAttendanceFromJson(localJson);
          if (cachedAttendance.isNotEmpty) {
            getMonthAttenDance = cachedAttendance;
            
            final holidayJson = prefs.getString('holidays_${setYear}_$setMonth');
            if (holidayJson != null) {
              try {
                curentMonthHoliday = getHolidayViewsFromJson(holidayJson);
              } catch (_) {}
            }
            
            setloading(false);
            notifyListeners();
          }
        }
      } catch (_) {}
    }

    // ── Step 2: Background API refresh (parallel) ───────────────────────────
    try {
      if (isNewMonth) {
        curentMonthHoliday.clear();
        totalPresent = 0;
        totalAbset = 0;
        totalHalfday = 0;
        totakWeekOff = 0;
        totalPaidLeave = 0;
        totalHoliday = 0;
      }

      final futureCounting = AttendancePerformanceLogger.instance.track(
        'AttendanceApis.getEmpMonathCounting',
        () => AttendanceApis().getEmpMonathCounting(setEmpid, setMonth, setYear),
        executionMode: 'parallel',
      );

      final futureHolidays = AttendancePerformanceLogger.instance.track(
        'HolidayAPIS.getHolidays',
        () => HolidayAPIS().getHolidays(),
        executionMode: 'parallel',
      );

      // Single attendance fetch (removed duplicate call)
      final futureMonthAttendance = AttendancePerformanceLogger.instance.track(
        'AttendanceApis.getEmpMonathAttendace',
        () => AttendanceApis().getEmpMonathAttendace(setEmpid, setMonth, setYear),
        executionMode: 'parallel',
      );

      final results = await Future.wait([futureCounting, futureHolidays, futureMonthAttendance]);
      if (currentMonth.month != setMonth || currentMonth.year != setYear) return;

      setEmpAttendanc = results[0] as List<AttendanceCountingClass>?;
      if (setEmpAttendanc != null && setEmpAttendanc!.isNotEmpty) {
        totalPresent = setEmpAttendanc!.first.totalPresent ?? 0;
        totalHalfday = 0;
      }

      checkHolidayList = results[1] as List<GetHolidayViews>;
      curentMonthHoliday = checkHolidayList.where((element) {
        final useDates = DateTime.parse(element.holidayDate.toString());
        return useDates.month == setMonth && useDates.year == setYear;
      }).toList();
      totalHoliday = 0;
      for (final holiday in curentMonthHoliday) {
        if (hasDateArrived(holiday.holidayDate)) {
          totalHoliday += calculateHolidayLeave(holiday);
        }
      }
      if (setEmpAttendanc != null && setEmpAttendanc!.isNotEmpty) {
        setEmpAttendanc!.first.totalHolidays = totalHoliday.toInt();
      }

      final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
      final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
      totakWeekOff = 0;
      for (int i = 0; i < lastDay.day; i++) {
        final day = firstDay.add(Duration(days: i));
        if (day.weekday == DateTime.sunday) {
          totakWeekOff++;
        }
      }

      // Use the result already fetched via Future.wait (no duplicate call)
      final freshAttendance = results[2] as List<EmployeAttendance>;
      if (currentMonth.month != setMonth || currentMonth.year != setYear) return;

      // Only update UI if data changed
      final isSame = getMonthAttenDance.length == freshAttendance.length;
      getMonthAttenDance = freshAttendance;

      // Persist to local cache for next app open
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, employeAttendanceToJson(freshAttendance));
        if (curentMonthHoliday.isNotEmpty) {
          await prefs.setString('holidays_${setYear}_$setMonth', getHolidayViewsToJson(curentMonthHoliday));
        }
      } catch (_) {}

      int totalop = 0;
      for (final element in getMonthAttenDance) {
        if (element.absent == true && element.weekOff == null && element.leaveTypeCguid == null) {
          totalop++;
        }
      }

      if (setEmpAttendanc != null && setEmpAttendanc!.isNotEmpty) {
        setEmpAttendanc!.first.totalAbsent = totalop;
        totalAbset = totalop;
      }

      calcualetPaidLeave();
      calcualetUnPaidLeave();
      loadedMonth = DateTime(setYear, setMonth);
      if (!isSame) notifyListeners();
      notifyListeners();
    } catch (e) { /* ignored */ } finally {
      if (handleLoading) setloading(false);
    }
  }

  void calcualetPaidLeave() {
    totalPaidLeave = 0;
    for (final element in getMonthAttenDance) {
      if (element.leaveGroup == 'Paid' && hasDateArrived(element.attendenceDate)) {
        totalPaidLeave += calculatePaidLeaveHours(element);
      }
    }
  }

  void calcualetUnPaidLeave() {
    var totalUnPaidLeave = 0.0;
    for (final element in getMonthAttenDance) {
      if (element.leaveGroup == 'Unpaid' && hasDateArrived(element.attendenceDate)) {
        totalUnPaidLeave += calculatePaidLeaveHours(element);
      }
    }

    if (setEmpAttendanc != null && setEmpAttendanc!.isNotEmpty) {
      setEmpAttendanc!.first.totalUnPaidLeave = totalUnPaidLeave.toInt();
    }
  }

  bool hasDateArrived(dynamic dateValue) {
    if (dateValue == null) {
      return true;
    }

    final parsedDate = DateTime.tryParse(dateValue.toString());
    if (parsedDate == null) {
      return true;
    }

    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final checkDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    return !checkDate.isAfter(currentDate);
  }

  double calculatePaidLeaveHours(EmployeAttendance attendance) {
    if (attendance.leaveDuration != null) {
      final leaveDuration = attendance.leaveDuration.toString().toLowerCase();
      final duration = double.tryParse(leaveDuration);
      if (duration != null) {
        return duration;
      }
      if (leaveDuration.contains('half') ||
          leaveDuration.contains('first half') ||
          leaveDuration.contains('second half')) {
        return 0.5;
      }
    }

    if (attendance.dayType != null) {
      final dayType = attendance.dayType.toString().toLowerCase();
      if (dayType.contains('half') ||
          dayType.contains('first half') ||
          dayType.contains('second half')) {
        return 0.5;
      }
    }

    return 1;
  }

  double calculateHolidayLeave(GetHolidayViews holiday) {
    if (holiday.holidayType != null) {
      final holidayType = holiday.holidayType.toString().toLowerCase();
      if (holidayType.contains('half') ||
          holidayType.contains('first half') ||
          holidayType.contains('second half')) {
        return 0.5;
      }
    }
    return 1;
  }

  GetShiftMasterData? getUserShift;

  Future setShiftData(empData, posiId, context) async {
    getUserShift = null; // Clear previous shift to prevent Admin shift leakage
    List<GetShiftMasterData> getShiftSData = [];
    PositionDataL? getpostionData;
    // Note: we do NOT call setloading(true) here — the parent caller already
    // manages the loading state. Extra toggles here cause shimmer flicker.
    try {
      final futurePositions = AttendancePerformanceLogger.instance.track(
        'PositionMasterService.getpositionfiles',
        () => Provider.of<PositionMasterService>(context, listen: false).getpositionfiles(),
        executionMode: 'parallel',
      );

      final futureShifts = AttendancePerformanceLogger.instance.track(
        'ShiftMasterProvider.getShiftTimintgMasterData',
        () => Provider.of<ShiftMasterProvider>(context, listen: false).getShiftTimintgMasterData(),
        executionMode: 'parallel',
      );

      final results = await Future.wait([futurePositions, futureShifts]);

      Provider.of<PositionMasterService>(context, listen: false).showPositions.forEach((element) {
        if(empData == null || empData == ''){
          if(element.id.toString() == curentUser['PositionId'].toString()){
            getpostionData = element;
          }
        } else {
          if(element.id.toString() == posiId.toString()){
            getpostionData = element;
          }
        }
      });

      getShiftSData = results[1] as List<GetShiftMasterData>;
      for (var element in getShiftSData) { 
          // Check if it matches the direct employee shift assignment
          if (empData != null && empData != '' && element.cguid.toString() == empData.toString()) {
            getUserShift = element;
            break;
          }
          // Check if it matches the position's default shift
          if (getpostionData != null && getpostionData!.shiftCguid != null && element.cguid.toString() == getpostionData!.shiftCguid.toString()) {
            getUserShift = element; // We don't break here so direct shift can override it
          }
        }
        
        // Fallback to avoid Null Pointer Exceptions if employee's shift is completely missing
        if (getUserShift == null && getShiftSData.isNotEmpty) {
          try {
            // Smart Fallback: Default to an 8.5-hour shift if available, as it is the standard
            getUserShift = getShiftSData.firstWhere((s) => s.shiftDuration != null && s.shiftDuration!.contains('08:30:00'));
          } catch (e) {
            getUserShift = getShiftSData.first;
          }
      }
    } catch (e) { /* ignored */ } finally {
      notifyListeners();
    }
  }

  AttendanceDayBlog? selectedDateLog;

  Future getDateBloges(setDate, employeid, {bool showLoading = true}) async {
    if (showLoading) setloading(true);
    selectedDateLog = null;
    try {
      await AttendanceApis().getDateBlogEmp(setDate, employeid, selectedcurentcompany!.companyId).then((value){
        selectedDateLog = value;
      });
    } catch (e) { /* ignored */ } finally {
      if (showLoading) setloading(false);
      notifyListeners();
    }
  }

  AttendanceDayBlog? checkStatus;

  Future checkLastPunch(employeid) async {
    DateTime dateTime = DateTime.now();
    DateTime newDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
    try {
      await AttendanceApis().getDateBlogEmp(newDateTime, employeid, selectedcurentcompany!.companyId).then((value){
        checkStatus = value;
      });
    } catch (e) { /* ignored */ }
    notifyListeners();
  }

  String totalWorkHour = '';
  String totalHour = '';
  String showShiftDuartion = '';
  var totalbreaks;
  DateTime showTimeValues = DateTime.now();

  attendanceCalculate(context) {
    try {
      int differenceInMinutes = 0;
      double shiftBreak1 = 0;
      double shiftBreak2 = 0;
      int usedlength = selectedDateLog!.attendenceLog!.length;
      int totalMinutsofData = 0;
      totalbreaks = '0 Min';
      
      // Total Hour Calculate
      if (selectedDateLog!.attendenceLog!.length >= 2) {
        var totalMinuts = selectedDateLog!.attendence!.totalMinute;

        final double minutes = double.tryParse(totalMinuts?.toString() ?? '0') ?? 0;

        int totalHours = minutes ~/ 60;
        int totalMin = minutes.toInt() % 60;
        totalHour = '$totalHours: $totalMin';

        for (var i = 0; i <= selectedDateLog!.attendenceLog!.length; i += 2) {
          if (i < usedlength - 1) {
            DateTime firstTime = DateTime.parse(selectedDateLog!.attendenceLog![i].time.toString());

            DateTime lasttTime = DateTime.parse(selectedDateLog!.attendenceLog![i + 1].time.toString());
            Duration getDuration = lasttTime.difference(firstTime);

            if(getUserShift!.break1 == true) {
              DateTime parsedDateTime = DateTime.parse(getUserShift!.break1Duration ?? '');
              int totalMinutes = parsedDateTime.hour * 60 + parsedDateTime.minute;
              shiftBreak1 = shiftBreak1 + totalMinutes;
            }

            if(getUserShift!.break2 == true) {
              DateTime parsedDateTime = DateTime.parse(getUserShift!.break1Duration ?? '');
              int totalMinutes = parsedDateTime.hour * 60 + parsedDateTime.minute;
              shiftBreak2 = shiftBreak2 + totalMinutes;
            }

            differenceInMinutes = getDuration.inMinutes;
            totalMinutsofData = totalMinutsofData + differenceInMinutes;
          }
        }
      }

      totalMinutsofData = totalMinutsofData - shiftBreak1.toInt();
      totalMinutsofData = totalMinutsofData - shiftBreak2.toInt();

      int hours = totalMinutsofData ~/ 60;
      int minutes = totalMinutsofData % 60;

      if(totalMinutsofData > 60){
        totalWorkHour = '$hours: $minutes Hr';
      } else {
        totalWorkHour = ' $totalMinutsofData Min';
      }

      // Total Break Time
      Provider.of<PayRollProviders>(context, listen: false).getAllMonthsBreak.forEach((element) {
        var attendenceDate = dateFormatddMMMyyyy(DateTime.parse(element.attendenceDate.toString()));
        var selectDate = dateFormatddMMMyyyy(DateTime.parse(showTimeValues.toString()));
        if (attendenceDate == selectDate) {
          int totalMinutes = int.parse(element.totalOutMinutes.toString());

          if (totalMinutes < 60) {
            totalbreaks = "$totalMinutes Min";
          } else {
            double hoursBreak = totalMinutes / 60;
            totalbreaks = "${hoursBreak.toStringAsFixed(1)} Hr";
          }
        }
      });

      DateTime parsedDateTime = DateFormat("dd/MM/yyyy HH:mm:ss").parse(getUserShift!.shiftDuration ?? '');
      showShiftDuartion = DateFormat("HH:mm").format(parsedDateTime);
    } catch (e) { /* ignored */ }
    notifyListeners();
  }

  /// Month Calculate Function
  double useTotalMinuts = 0;
  String showUserTotalHours = '';
  double paidLeave = 0;
  String holidayHoursCount = '';
  String paidLeaveHours = '';
  String totalBreakHours = '';
  String expectedTotalHours = '';

  Future calculateTime(context, empData, int fetchMonth, int fetchYear) async {
    try {
      double localUseTotalMinuts = 0;
      double localPaidLeave = 0;

      double setShitBreak = 0;
      double premOutMinuts = 0;

      final payrollProvider = Provider.of<PayRollProviders>(context, listen: false);
      final holidayProvider = Provider.of<HolidayeMastServices>(context, listen: false);

      if (payrollProvider.getPayRollAttendanceData.isEmpty) {
        for (final element in payrollProvider.getAllMonthsBreak) {
          premOutMinuts += double.parse(element.totalOutMinutes.toString());
        }
      } else {
        for (final element in payrollProvider.getPayRollAttendanceData) {
          if (element.totalBreak != null) {
            premOutMinuts += double.parse(element.totalBreak.toString());
          }
        }
      }

      final breakTotalMinutes = premOutMinuts.toInt();
      final breakHours = breakTotalMinutes ~/ 60;
      final breakMinutes = breakTotalMinutes % 60;
      totalBreakHours = "$breakHours : $breakMinutes";

      for (final element in getMonthAttenDance) {
        if (element.totalMinute != null) {
          localUseTotalMinuts += int.parse(element.totalMinute.toString());
        }

        if (element.present == true) {
          if (getUserShift!.break1 == true) {
            final parsedDateTime = DateTime.parse(getUserShift!.break1Duration ?? '');
            final totalMinutes = parsedDateTime.hour * 60 + parsedDateTime.minute;
            setShitBreak += totalMinutes;
          }

          if (getUserShift!.break2 == true) {
            final parsedDateTime = DateTime.parse(getUserShift!.break2Duration ?? '');
            final totalMinutes = parsedDateTime.hour * 60 + parsedDateTime.minute;
            setShitBreak += totalMinutes;
          }
        }

        if (element.leaveGroup == 'Paid') {
          localPaidLeave += 1;
        }
      }

      final dateFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
      final parsedDateTime = dateFormat.parse(getUserShift!.shiftDuration ?? '');
      final dayTotalMinuts = parsedDateTime.hour * 60 + parsedDateTime.minute;

      final paidLeaveDuration = dayTotalMinuts * totalPaidLeave;
      localUseTotalMinuts += paidLeaveDuration;

      final currentDate = DateTime.now();
      final firstDate = DateTime(currentMonth.year, currentMonth.month, 1);

      final filteredDates = holidayProvider.mainHolidayList.where((date) {
        final holidayDate = DateTime.parse(date.holidayDate ?? '');
        return holidayDate.isAfter(firstDate) && holidayDate.isBefore(currentDate);
      }).where((element) => DateTime.parse(element.holidayDate ?? '').month == currentMonth.month).toList();

      var holidayDuration = 0.0;
      if (filteredDates.isNotEmpty) {
        holidayDuration = dayTotalMinuts.toDouble() * filteredDates.length;
      }

      localUseTotalMinuts += holidayDuration;
      localUseTotalMinuts -= premOutMinuts.toInt();
      localUseTotalMinuts -= setShitBreak.toInt();

      useTotalMinuts = localUseTotalMinuts;
      paidLeave = localPaidLeave;

      final ss = useTotalMinuts ~/ 60;
      final ww = useTotalMinuts.toInt() % 60;
      showUserTotalHours = '$ss:$ww';

      final totalMinutes = holidayDuration.toInt();
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      holidayHoursCount = "$hours : $minutes";

      final plTotalMinutes = paidLeaveDuration.toInt();
      final plHours = plTotalMinutes ~/ 60;
      final plMinutes = plTotalMinutes % 60;
      paidLeaveHours = "$plHours : $plMinutes";

      if (getUserShift != null) {
        int totalDaysInMonth = DateTime(fetchYear, fetchMonth + 1, 0).day;
        int weekOffs = 0;
        for (int i = 1; i <= totalDaysInMonth; i++) {
          DateTime day = DateTime(fetchYear, fetchMonth, i);
          if (getUserShift!.mon == false && day.weekday == 1) weekOffs++;
          else if (getUserShift!.tue == false && day.weekday == 2) weekOffs++;
          else if (getUserShift!.wed == false && day.weekday == 3) weekOffs++;
          else if (getUserShift!.thu == false && day.weekday == 4) weekOffs++;
          else if (getUserShift!.fri == false && day.weekday == 5) weekOffs++;
          else if (getUserShift!.sat == false && day.weekday == 6) weekOffs++;
          else if (getUserShift!.sun == false && day.weekday == 7) weekOffs++;
        }
        
        int expectedWorkingDays = totalDaysInMonth - weekOffs;
        
        int dailyBreakMins = 0;
        if (getUserShift!.break1 == true) {
          try {
            final b1 = DateTime.parse(getUserShift!.break1Duration ?? '');
            dailyBreakMins += b1.hour * 60 + b1.minute;
          } catch (e) { /* ignored */ }
        }
        if (getUserShift!.break2 == true) {
          try {
            final b2 = DateTime.parse(getUserShift!.break2Duration ?? '');
            dailyBreakMins += b2.hour * 60 + b2.minute;
          } catch (e) { /* ignored */ }
        }
        
        int expectedNetDailyMins = dayTotalMinuts - dailyBreakMins;
        int expectedMonthlyMinuts = expectedWorkingDays * expectedNetDailyMins;
        
        final expectedHH = expectedMonthlyMinuts ~/ 60;
        final expectedMM = expectedMonthlyMinuts % 60;
        expectedTotalHours = '$expectedHH:${expectedMM.toString().padLeft(2, '0')}';
      } else {
        expectedTotalHours = '0';
      }


    } catch (e) { /* ignored */ }
  }

  TextEditingController punchInTimeC = TextEditingController();
  TextEditingController punchOutTimeC = TextEditingController();

  // durATION Get
  getDuration(context, empData) async {
    final fetchMonth = currentMonth.month;
    final fetchYear = currentMonth.year;
    
    try {
      final payrollProvider = Provider.of<PayRollProviders>(context, listen: false);
      final holidayProvider = Provider.of<HolidayeMastServices>(context, listen: false);

      final futureMonthsBreaks = AttendancePerformanceLogger.instance.track(
        'PayRollProviders.getMonthsBreaks',
        () => payrollProvider.getMonthsBreaks(
          setEmployeId: empData != null ? empData.empId : curentUser['Id'],
          setMonth: fetchMonth,
          setYear: fetchYear,
        ),
        executionMode: 'parallel',
      );

      final futurePayRollData = AttendancePerformanceLogger.instance.track(
        'PayRollProviders.getPayRollData',
        () => payrollProvider.getPayRollData(
          setEmployeId: empData != null ? empData.empId : curentUser['Id'],
          setMonth: fetchMonth,
          setYear: fetchYear,
        ),
        executionMode: 'parallel',
      );

      final futureAllHoliday = AttendancePerformanceLogger.instance.track(
        'HolidayeMastServices.getAllHoliday',
        () => holidayProvider.getAllHoliday(),
        executionMode: 'parallel',
      );

      await Future.wait([futureMonthsBreaks, futurePayRollData, futureAllHoliday]);
      
      if (currentMonth.month != fetchMonth || currentMonth.year != fetchYear) return;
      
      await calculateTime(context, empData, fetchMonth, fetchYear);
    } catch (e) {
      // ignore
    }
    notifyListeners();
  }
}
