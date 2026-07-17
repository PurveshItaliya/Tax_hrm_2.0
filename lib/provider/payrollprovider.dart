// ignore_for_file: use_null_aware_elements, use_build_context_synchronously, curly_braces_in_flow_control_structures, strict_top_level_inference, empty_catches, avoid_function_literals_in_foreach_calls

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:tax_hrm/services/local_cache_service.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/api/payrollapi.dart';
import 'package:tax_hrm/api/payslipapi.dart';
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/SalarryMaster/createStructuresalary.dart';
import 'package:tax_hrm/models/attendance/monathattendace.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/payrool/createpayroll.dart';
import 'package:tax_hrm/models/payrool/deletesalary.dart';
import 'package:tax_hrm/models/payrool/getpayrollattendancedata.dart';
import 'package:tax_hrm/models/payrool/getsalarydata.dart';
import 'package:tax_hrm/models/payrool/monthsbreak.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/provider/additionprovider.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/holidayprovider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:tax_hrm/utils/attendance_perf_logger.dart';

class PayRollProviders extends ChangeNotifier {
  bool islodering = false;
  bool get isloderings => islodering;
  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }


  List<MonthwiseBreak> getAllMonthsBreak = [];
  Future getMonthsBreaks({setEmployeId, setMonth, setYear}) async {
    await PayRollApiSerices().getMonthsBreak(setEmployeId, setMonth, setYear).then((val) {
      getAllMonthsBreak = val;
      notifyListeners();
    });
  }

  //---------------------------PayRoll Salary ---------------------------------\\
  List<Salarys> holdMainSalaryList = [];
  List<Salarys> getSalaryList = [];
  Employeelists? selectedEmployeeList;
  DateTime payRollcurrentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _hasLoadedPayrollThisSession = false;

  loadingData(usetEmpid, refreshValue, {bool forceRefresh = false}) async {
    try {
      if (refreshValue) {
        selectedEmployeeList = null;
        payRollcurrentMonth = DateTime(DateTime.now().year, DateTime.now().month == 1 ? 12 : DateTime.now().month - 1);
      }
      
      final cacheKey = '${LocalCacheService.keyMasterData}_payroll_${usetEmpid}_${payRollcurrentMonth.month}_${payRollcurrentMonth.year}';
      const ttlMs = 24 * 60 * 60 * 1000;

      if (!forceRefresh && _hasLoadedPayrollThisSession) {
        islodering = false;
        notifyListeners();
        return;
      }

      bool loadedFromCache = false;

      if (!forceRefresh) {
        final cachedData = await LocalCacheService.instance.getCache(cacheKey, ttlMilliseconds: ttlMs);
        if (cachedData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(cachedData);
            final cachedList = jsonList.map((e) => Salarys.fromJson(e)).toList();
            holdMainSalaryList = cachedList;
            getSalaryList = cachedList;
            _hasLoadedPayrollThisSession = true;
            loadedFromCache = true;
            islodering = false;
            notifyListeners();
          } catch (e) {}
        }
      }

      if (!loadedFromCache || forceRefresh) {
        setloading(true);
      }

      unawaited(
        AttendancePerformanceLogger.instance.track(
          'PayRollProviders.getSalarysData',
          () => _fetchAndCacheSalarysData(
            usetEmpid: usetEmpid, 
            usetMonths: payRollcurrentMonth.month, 
            usetYears: payRollcurrentMonth.year,
            cacheKey: cacheKey
          )
        )
      );

    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  Future<void> _fetchAndCacheSalarysData({usetEmpid, usetMonths, usetYears, required String cacheKey}) async {
    try {
      final value = await PayRollApiSerices().getSalaryData(setEmpid: usetEmpid, setMonths: usetMonths, setYears: usetYears);
      holdMainSalaryList = value;
      getSalaryList = value;
      _hasLoadedPayrollThisSession = true;
      setloading(false);

      final jsonList = value.map((e) => e.toJson()).toList();
      await LocalCacheService.instance.saveCache(cacheKey, jsonEncode(jsonList));

      notifyListeners();
    } catch (e) {
      setloading(false);
    }
  }

  getSalarysData({usetEmpid, usetMonths, usetYears}) async {
    await PayRollApiSerices().getSalaryData(setEmpid: usetEmpid, setMonths: usetMonths, setYears: usetYears).then((value) {
      holdMainSalaryList = value;
      getSalaryList = value;
    }).onError((error, stackTrace) {});
  }

  employessontap(value) {
    selectedEmployeeList = value;
    notifyListeners();
    loadingData(selectedEmployeeList!.id, false);
  }

  arrorHandleSubmit(listIndexs) {
    listIndexs.salaryBoolValue = !listIndexs.salaryBoolValue;
    notifyListeners();
  }

  iconOntap() {
    selectedEmployeeList = null;
    notifyListeners();
    loadingData(0, true);
  }

  void updateMonth(DateTime month, BuildContext context) {
    payRollcurrentMonth = month;
    notifyListeners();
    loadingData(selectedEmployeeList == null ? 0 : selectedEmployeeList!.id, false);
  }

  deletePayrollSalaryMaster(context, {setRecuritmentid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await PayRollApiSerices().deleteSalaryData(setSalaryStructureId: setRecuritmentid).then((value) async {
        SalaryDeleteClass setResponse = value as SalaryDeleteClass;
        if (setResponse.success == true) {
          if (setResponse.data == "Success") {
            await loadingData(0, false);
          }
        }
        setloading(false);
      }).onError((error, stackTrace) {
        setloading(false);
      });
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  //---------------------------PayRoll Attendance ---------------------------------\\
  List<GetPayRollAttendance> getPayRollAttendanceData = [];
  Future getPayRollData({setEmployeId, setMonth, setYear}) async {
    setloading(true);
    await PayRollApiSerices().getPayRollData(setEmployeId, setMonth, setYear).then((value) {
      getPayRollAttendanceData = value;
      setloading(false);
      notifyListeners();
    }).onError((error, stackTrace) {
      setloading(false);
    });
  }

  //--------------------------- Add PayRoll Salary ---------------------------------\\
  DateTime addPayRollcurrentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Employeelists? selectedAddEmployeeList;

  // Store month attendance data
  List<EmployeAttendance> currentMonthAttendance = [];

  // Half-day tracking variables
  double totalHalfDayLeave = 0;
  double totalFullDayLeave = 0;

  double totalHolidayCount = 0;

  double totalHalfDayLWP = 0;
  double totalFullDayLWP = 0;

  // Formatted getters for UI
  String get formattedPaidLeave {
    if (paidLeave % 1 == 0) return paidLeave.toInt().toString();
    return paidLeave.toStringAsFixed(1);
  }

  String get formattedUnpaidLeave {
    if (usedlwp % 1 == 0) return usedlwp.toInt().toString();
    return usedlwp.toStringAsFixed(1);
  }

  String get formattedHalfDayPL => totalHalfDayLeave.toInt().toString();
  String get formattedFullDayPL => totalFullDayLeave.toInt().toString();
  String get formattedHalfDayLWP => totalHalfDayLWP.toInt().toString();
  String get formattedFullDayLWP => totalFullDayLWP.toInt().toString();

  // Dynamic attendance list getters
  int get attendanceListCount {
    if (selectedAddEmployeeList == null) return 0;
    final lastDayOfMonth = DateTime(addPayRollcurrentMonth.year, addPayRollcurrentMonth.month + 1, 0);
    return lastDayOfMonth.day;
  }

  List<Map<String, dynamic>> getDynamicAttendanceList() {
    List<Map<String, dynamic>> attendanceList = [];
    if (selectedAddEmployeeList == null) return attendanceList;
    
    final year = addPayRollcurrentMonth.year;
    final month = addPayRollcurrentMonth.month;
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final totalDays = lastDayOfMonth.day;
    
    for (int i = 1; i <= totalDays; i++) {
      final currentDate = DateTime(year, month, i);
      String inTime = '';
      String outTime = '';
      String totalHours = '';
      String holidayName = '';
      bool isOnLeave = false;
      bool isWeekOff = false;
      String leaveTypeName = '';
      double totalBreaks = 0;
      
      String dayName = DateFormat('EEEE').format(currentDate);
      if (selectedUserShift != null) {
        isWeekOff = _isWeekOffDay(dayName.substring(0, 3).toLowerCase());
      }
      
      for (final element in currentMonthAttendance) {
        DateTime attendanceDate = DateTime.parse(element.attendenceDate.toString());
        if (attendanceDate.day == i && attendanceDate.month == month && attendanceDate.year == year) {
          if (element.inTime != null && element.inTime.toString() != 'false' && element.inTime.toString().isNotEmpty) {
            try {
              inTime = DateFormat('h:mm a').format(DateTime.parse(element.inTime.toString()));
            } catch(e) { /* ignored */ }
          }
          if (element.outTime != null && element.outTime.toString() != 'false' && element.outTime.toString().isNotEmpty) {
            try {
              outTime = DateFormat('h:mm a').format(DateTime.parse(element.outTime.toString()));
            } catch(e) { /* ignored */ }
          }
          if (element.absent == true && element.isOnLeave == true) {
            isOnLeave = true;
            leaveTypeName = element.leaveTypeFName.toString();
          }
          if (element.totalMinute != null) {
            int hours = int.parse(element.totalMinute.toString()) ~/ 60;
            int minutes = int.parse(element.totalMinute.toString()) % 60;
            totalHours = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
          }
        }
      }
      
      if (alrdayDataAdd == true) {
        for (final element in getPayRollAttendanceData) {
          DateTime breakDate = DateTime.parse(element.attendenceDate.toString());
          if (breakDate.day == i && breakDate.month == month && breakDate.year == year) {
            totalBreaks = double.tryParse(element.totalBreak ?? '0') ?? 0;
          }
        }
      } else {
        for (final element in getAllMonthsBreak) {
          DateTime breakDate = DateTime.parse(element.attendenceDate.toString());
          if (breakDate.day == i && breakDate.month == month && breakDate.year == year) {
            totalBreaks = double.tryParse(element.totalOutMinutes.toString()) ?? 0;
          }
        }
      }
      
      for (final element in curentMonthHoliday) {
        DateTime holidayDate = DateTime.parse(element.holidayDate.toString());
        if (holidayDate.day == i) {
          holidayName = element.holidayName.toString();
        }
      }
      
      attendanceList.add({
        'date': currentDate,
        'dayName': dayName.substring(0, 3),
        'inTime': inTime.isEmpty ? '--:-- --' : inTime,
        'outTime': outTime.isEmpty ? '--:-- --' : outTime,
        'totalHours': totalHours.isEmpty ? '00:00' : totalHours,
        'totalBreaks': totalBreaks,
        'holidayName': holidayName,
        'isOnLeave': isOnLeave,
        'isWeekOff': isWeekOff,
        'leaveTypeName': leaveTypeName,
      });
    }
    return attendanceList;
  }

  Map<String, dynamic> getAttendanceDataForIndex(int index) {
    final attendanceList = getDynamicAttendanceList();
    if (index < attendanceList.length) {
      return attendanceList[index];
    }
    return {
      'date': DateTime.now(),
      'dayName': '',
      'inTime': '--:-- --',
      'outTime': '--:-- --',
      'totalHours': '00:00',
      'totalBreaks': 0,
      'holidayName': '',
      'isOnLeave': false,
      'isWeekOff': false,
      'leaveTypeName': '',
    };
  }

  loadAddData(BuildContext context, usetEmpid, refreshValue,addEditFlag,getPayrollData) async {
    try {
      setloading(true);
      if (addEditFlag == false) {
        await AttendancePerformanceLogger.instance.track(
          'PayRollProviders.editData',
          () => editData(addEditFlag,getPayrollData,context)
        );
      }
      if (refreshValue) {
        selectedAddEmployeeList = null;
        addPayRollcurrentMonth = DateTime(DateTime.now().year, DateTime.now().month == 1 ? 12 : DateTime.now().month - 1);
      }
      final futureSalary = AttendancePerformanceLogger.instance.track(
        'PayRollProviders.getSalarysData (inside loadAddData)',
        () => getSalarysData(usetEmpid: usetEmpid, usetMonths: addPayRollcurrentMonth.month, usetYears: addPayRollcurrentMonth.year),
        executionMode: 'parallel'
      );
      final futureEmp = AttendancePerformanceLogger.instance.track(
        'EmployeMastServices.getAllEmployesData (inside loadAddData)',
        () => Provider.of<EmployeMastServices>(context, listen: false).getAllEmployesData(),
        executionMode: 'parallel'
      );
      
      Future? futureShift;
      Future? futureHoliday;
      
      if (!refreshValue) {
        futureShift = AttendancePerformanceLogger.instance.track(
          'ShiftMasterProvider.getShiftTimintgMasterData',
          () => Provider.of<ShiftMasterProvider>(context, listen: false).getShiftTimintgMasterData(),
          executionMode: 'parallel'
        );
        futureHoliday = AttendancePerformanceLogger.instance.track(
          'HolidayeMastServices.getAllHoliday',
          () => Provider.of<HolidayeMastServices>(context, listen: false).getAllHoliday(),
          executionMode: 'parallel'
        );
      }
      
      await Future.wait([
        futureSalary,
        futureEmp,
        if (futureShift != null) futureShift,
        if (futureHoliday != null) futureHoliday,
      ]);
      
      if (addEditFlag == true) {
        Provider.of<EmployeMastServices>(context, listen: false).emplists = Provider.of<EmployeMastServices>(context, listen: false).emplists.where((emp) {
          return !getSalaryList.any((sal) => sal.empId == emp.id);
        }).toList();
      }

      if (!refreshValue) {
        await AttendancePerformanceLogger.instance.track(
          'PayRollProviders.setandGetData',
          () => setandGetData(context)
        );
      }
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  editData(addEditFlag,getPayrollData,context) async {
    await getSalarysData(usetEmpid: getPayrollData.empId,usetMonths: getPayrollData.monthYear.toString().split("-").last,usetYears: getPayrollData.monthYear.toString().split("-").first,).then((value) {
      Provider.of<EmployeMastServices>(context,listen: false,).allemployes.forEach((element) {
        if (element.id == getPayrollData.empId) {
          selectedAddEmployeeList = element;
        }
      });

      addPayRollcurrentMonth = DateTime(
        int.parse(getPayrollData.monthYear.toString().split("-").first),
        int.parse(getPayrollData.monthYear.toString().split("-").last),
      );
      notifyListeners();
    });
  }

  Future<void> updateAddMonth(DateTime month, BuildContext context) async {
    addPayRollcurrentMonth = month;
    notifyListeners();
    await loadAddData(context, selectedAddEmployeeList == null ? 0 : selectedAddEmployeeList!.id, false,null,null);
  }

  iconAddOntap(BuildContext context) async {
    selectedAddEmployeeList = null;
    await loadAddData(context, 0, false,null,null);
  }

  employessAddontap(BuildContext context, value) async {
    selectedAddEmployeeList = value;
    notifyListeners();
    if (selectedAddEmployeeList != null) {
      await loadAddData(context, selectedAddEmployeeList!.id, false,null,null);
    }
  }

  double showTotalHoursView = 0;
  int useTotalMinuts = 0;
  int totalPresnts = 0;
  double paidLeave = 0;
  double usedlwp = 0;
  int shiftworkingTime = 0;
  double shiftBreakTime = 0;
  double shiftBreakTime1 = 0;
  double shiftBreakTime2 = 0;
  double holdworkingMinuts = 0;
  double setWeekOffCount = 0;
  double totalMainBreak = 0;
  double showMainBreaksValues = 0;
  String holdworkingHours = '';
  String showMainBreak = '';
  String showUserTotalHours = '';
  bool alrdayDataAdd = false;
  List<GetHolidayViews> curentMonthHoliday = [];
  GetShiftMasterData? selectedUserShift;

  int currentSelection = 0;
  Map<int, Widget> options = {
    0: Text(additionOrDeductionString.toString().split("/").first),
    1: Text(additionOrDeductionString.toString().split("/").last),
  };

  ontabMaterioal(int indexs) {
    currentSelection = indexs;
    notifyListeners();
  }

  double _getLeaveDurationInDays(EmployeAttendance attendance) {
    if (attendance.leaveDuration != null) {
      final leaveDuration = attendance.leaveDuration.toString().toLowerCase();
      final duration = double.tryParse(leaveDuration);
      if (duration != null) return duration;
      if (leaveDuration.contains('half') || leaveDuration.contains('first half') || leaveDuration.contains('second half')) return 0.5;
    }
    if (attendance.dayType != null) {
      final dayType = attendance.dayType.toString().toLowerCase();
      if (dayType.contains('half') || dayType.contains('first half') || dayType.contains('second half')) return 0.5;
    }
    if (attendance.leaveTypeFName != null) {
      final leaveName = attendance.leaveTypeFName!.toLowerCase();
      if (leaveName.contains('half')) return 0.5;
    }
    return 1.0;
  }

  double _getHolidayDurationInDays(GetHolidayViews holiday) {
    if (holiday.holidayType != null) {
      final holidayType = holiday.holidayType.toString().toLowerCase();
      if (holidayType.contains('half') || holidayType.contains('first half') || holidayType.contains('second half')) return 0.5;
    }
    return 1.0;
  }

  Future<void> setandGetData(BuildContext context) async {
    try {
      await clearAddPayrollData();

      if (selectedAddEmployeeList == null) {
        notifyListeners();
        return;
      }

      final empId = selectedAddEmployeeList!.id;
      final month = addPayRollcurrentMonth.month;
      final year = addPayRollcurrentMonth.year;

      final futurePayroll = AttendancePerformanceLogger.instance.track(
        'PayRollProviders.getPayRollData',
        () => getPayRollData(setEmployeId: empId, setMonth: month, setYear: year),
        executionMode: 'parallel'
      );
      final futureBreaks = AttendancePerformanceLogger.instance.track(
        'PayRollProviders.getMonthsBreaks',
        () => getMonthsBreaks(setEmployeId: empId, setMonth: month, setYear: year),
        executionMode: 'parallel'
      );
      final futureAttendance = AttendancePerformanceLogger.instance.track<dynamic>(
        'AttendanceApis.getEmpMonathAttendace',
        () => AttendanceApis().getEmpMonathAttendace(empId, month, year),
        executionMode: 'parallel'
      );

      final results = await Future.wait([futurePayroll, futureBreaks, futureAttendance]);
      
      alrdayDataAdd = getPayRollAttendanceData.isNotEmpty;
      _setSelectedUserShift(context);
      _setCurrentMonthHoliday(context);
      
      currentMonthAttendance = results[2] as List<EmployeAttendance>;


      double localUseTotalMinuts = 0;
      double localPaidLeave = 0;
      double localUsedlwp = 0;
      int localTotalPresnts = 0;
      double localTotalHalfDayLeave = 0;
      double localTotalFullDayLeave = 0;
      double localTotalHalfDayLWP = 0;
      double localTotalFullDayLWP = 0;

      double localTotalHolidayCount = 0;

      final now = DateTime.now();
      for (final element in curentMonthHoliday) {
        if (element.holidayType == 'Paid') {
          final holidayDate = DateTime.tryParse(element.holidayDate ?? '');
          if (holidayDate != null && holidayDate.isAfter(now)) {
            continue;
          }
          final holidayDuration = _getHolidayDurationInDays(element);
          localUseTotalMinuts += (shiftworkingTime * holidayDuration).toInt();
          localTotalHolidayCount += holidayDuration;
        }
      }

      for (final element in currentMonthAttendance) {
        if (element.present == true && element.leaveTypeCguid == null) localTotalPresnts += 1;
        final leaveDuration = _getLeaveDurationInDays(element);
        if (element.absent == true && element.isOnLeave == true && element.leaveGroup == 'Unpaid') {
          localUsedlwp += leaveDuration;
          if (leaveDuration == 0.5) localTotalHalfDayLWP += 1;
          else localTotalFullDayLWP += 1;
        }
        if (element.absent == true && element.isOnLeave == true && element.leaveGroup == 'Paid') {
          localUseTotalMinuts += (shiftworkingTime * leaveDuration).toInt();
          localPaidLeave += leaveDuration;
          if (leaveDuration == 0.5) localTotalHalfDayLeave += 1;
          else localTotalFullDayLeave += 1;
        }
        localUseTotalMinuts += int.tryParse(element.totalMinute?.toString() ?? '') ?? 0;
      }

      useTotalMinuts = localUseTotalMinuts.toInt();
      paidLeave = localPaidLeave;
      usedlwp = localUsedlwp;
      totalPresnts = localTotalPresnts;
      totalHolidayCount = localTotalHolidayCount;
      totalHalfDayLeave = localTotalHalfDayLeave;
      totalFullDayLeave = localTotalFullDayLeave;
      totalHalfDayLWP = localTotalHalfDayLWP;
      totalFullDayLWP = localTotalFullDayLWP;

      _calculateWeekOffCount();
      _calculateBreakAndWorkingHours();
      showUserTotalHours = _formatMinutes(useTotalMinuts);
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  void _setSelectedUserShift(BuildContext context) {
    selectedUserShift = null;
    for (final element in Provider.of<ShiftMasterProvider>(context, listen: false).mainShiftMasterList) {
      if (element.positionId == selectedAddEmployeeList!.positionId) {
        selectedUserShift = element;
        break;
      }
    }
    if (selectedUserShift == null) return;
    final dateTime = DateFormat("dd/MM/yyyy HH:mm:ss").parse(selectedUserShift!.shiftDuration.toString());
    shiftworkingTime = (dateTime.hour * 60) + dateTime.minute;
    if (selectedUserShift!.break1 == true) {
      final time = DateFormat.Hms().format(DateTime.parse(selectedUserShift!.break1Duration.toString()));
      shiftBreakTime1 = convertTimeToMinutes(time).toDouble();
    }
    if (selectedUserShift!.break2 == true) {
      final time = DateFormat.Hms().format(DateTime.parse(selectedUserShift!.break2Duration.toString()));
      shiftBreakTime2 = convertTimeToMinutes(time).toDouble();
    }
  }

  void _setCurrentMonthHoliday(BuildContext context) {
    curentMonthHoliday.clear();
    for (final element in Provider.of<HolidayeMastServices>(context, listen: false).mainHolidayList) {
      final setDateTime = DateTime.tryParse(element.holidayDate.toString());
      if (setDateTime != null && addPayRollcurrentMonth.month == setDateTime.month && addPayRollcurrentMonth.year == setDateTime.year) {
        curentMonthHoliday.add(element);
      }
    }
  }



  void _calculateWeekOffCount() {
    if (selectedUserShift == null) return;
    final lastDayOfMonth = DateTime(addPayRollcurrentMonth.year, addPayRollcurrentMonth.month + 1, 0);
    for (var i = 1; i <= lastDayOfMonth.day; i++) {
      final dayCode = DateFormat('EEE').format(DateTime(addPayRollcurrentMonth.year, addPayRollcurrentMonth.month, i)).toLowerCase();
      if (_isWeekOffDay(dayCode)) setWeekOffCount += 1;
    }
  }

  bool _isWeekOffDay(String dayCode) {
    if (selectedUserShift == null) return false;
    switch (dayCode) {
      case 'sun': return selectedUserShift!.sun == false;
      case 'mon': return selectedUserShift!.mon == false;
      case 'tue': return selectedUserShift!.tue == false;
      case 'wed': return selectedUserShift!.wed == false;
      case 'thu': return selectedUserShift!.thu == false;
      case 'fri': return selectedUserShift!.fri == false;
      case 'sat': return selectedUserShift!.sat == false;
      default: return false;
    }
  }

  void _calculateBreakAndWorkingHours() {
    showMainBreaksValues = 0;
    if (alrdayDataAdd == true) {
      for (final element in getPayRollAttendanceData) {
        showMainBreaksValues += double.tryParse(element.totalBreak ?? '0') ?? 0;
      }
      totalMainBreak += showMainBreaksValues;
    } else {
      for (final element in getAllMonthsBreak) {
        showMainBreaksValues += double.tryParse(element.totalOutMinutes.toString()) ?? 0;
      }
      totalMainBreak += showMainBreaksValues;
    }
    
    if (selectedUserShift?.break1 == true) totalMainBreak += shiftBreakTime1 * totalPresnts;
    if (selectedUserShift?.break2 == true) totalMainBreak += shiftBreakTime2 * totalPresnts;
    showMainBreak = _formatMinutes(totalMainBreak.toInt());
    holdworkingMinuts = useTotalMinuts.toDouble() - totalMainBreak;
    holdworkingHours = _formatMinutes(holdworkingMinuts.toInt());
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String formatBreakTime(double breakMinutes) {
    int hours = breakMinutes.toInt() ~/ 60;
    int minutes = breakMinutes.toInt() % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    }
    return '0';
  }

  clearAddPayrollData() {
    showTotalHoursView = 0;
    useTotalMinuts = 0;
    totalPresnts = 0;
    paidLeave = 0;
    usedlwp = 0;
    shiftworkingTime = 0;
    shiftBreakTime = 0;
    shiftBreakTime1 = 0;
    shiftBreakTime2 = 0;
    holdworkingMinuts = 0;
    setWeekOffCount = 0;
    totalMainBreak = 0;
    showMainBreaksValues = 0;
    holdworkingHours = '';
    showMainBreak = '';
    showUserTotalHours = '';
    alrdayDataAdd = false;
    totalHalfDayLeave = 0;
    totalFullDayLeave = 0;
    totalHalfDayLWP = 0;
    totalFullDayLWP = 0;
    currentMonthAttendance = [];
  }

  // ==================== EMPLOYEE SALARY VIEW VARIABLES ====================
  String showFinalAmountPay = '0.0';
  String amountPay = '0.0';
  
  TextEditingController departmentController = TextEditingController();
  TextEditingController designationController = TextEditingController();
  TextEditingController bankNameController = TextEditingController();
  TextEditingController bankNumberController = TextEditingController();
  TextEditingController salaryAmountController = TextEditingController();
  TextEditingController workingHoursController = TextEditingController();
  TextEditingController totalHoursController = TextEditingController();
  TextEditingController otHoursController = TextEditingController();
  TextEditingController hraController = TextEditingController();
  TextEditingController daController = TextEditingController();
  TextEditingController conveyanceController = TextEditingController();
  TextEditingController medicalController = TextEditingController();
  TextEditingController allowanceController = TextEditingController();
  TextEditingController otherAdditionController = TextEditingController();
  TextEditingController otController = TextEditingController();
  TextEditingController pfController = TextEditingController();
  TextEditingController esicController = TextEditingController();
  TextEditingController professionalTaxController = TextEditingController();
  TextEditingController tdsController = TextEditingController();
  TextEditingController otherDeductionController = TextEditingController();
  TextEditingController txtEffectiveDateController = TextEditingController();
  
  DateTime effectiveDate = DateTime.now();
  double finalCountSalaryAmount = 0;
  
  // Stored data for setData
  Employeelists? _selectedEmployes;
  double _totalWorkingHoursminuts = 0;
  String _setYear = "";
  String _setMonth = "";
  String _paidLeavecount = "";
  String _paidleavhours = "";
  String _settotalBreak = "";
  String _settotalPresent = "";
  String _setweeklyOff = "";
  String _setweeklyOffHour = "";
  String _saveType = "";
  int _salaryEmpId = 0;

  clearEmployeeSalaryData() {
    hraController.clear();
    daController.clear();
    conveyanceController.clear();
    medicalController.clear();
    allowanceController.clear();
    otherAdditionController.clear();
    otController.clear();
    pfController.clear();
    esicController.clear();
    professionalTaxController.clear();
    tdsController.clear();
    otherDeductionController.clear();
    txtEffectiveDateController.clear();
    showFinalAmountPay = '0.0';
    amountPay = '0.0';
    finalCountSalaryAmount = 0;
    _totalWorkingHoursminuts = 0;
    _paidLeavecount = "";
    _paidleavhours = "";
    _settotalBreak = "";
    _settotalPresent = "";
    _setweeklyOff = "";
    _setweeklyOffHour = "";
    _saveType = "";
    _salaryEmpId = 0;
  }

  // ==================== SET DATA FROM EMPLOYEE SALARY VIEW ====================
  void setEmployeeSalaryData({
    required Employeelists selectedEmployes,
    required String workingHoursview,
    required double totalWorkingHoursminuts,
    required String setYear,
    required String setMonth,
    required String paidLeavecount,
    required String paidleavhours,
    required String settotalBreak,
    required String settotalPresent,
    required String setweeklyOff,
    required String setweeklyOffHour,
    required String saveType,
  }) {
    final selectedSalaryAmount = selectedEmployes.salaryAmount?.trim();
    totalHoursController.text = workingHoursview.isEmpty ? '00:00' : workingHoursview;
    departmentController.text = selectedEmployes.departmentName ?? '';
    designationController.text = selectedEmployes.positionName ?? '';
    bankNameController.text = selectedEmployes.bankName ?? '';
    bankNumberController.text = selectedEmployes.accNo ?? '';
    salaryAmountController.text = selectedSalaryAmount == null || selectedSalaryAmount.isEmpty ? '0' : selectedSalaryAmount;
    workingHoursController.text = selectedEmployes.totalhours?.toString() ?? '0';
    effectiveDate = DateTime.now();
    txtEffectiveDateController.text = dateFormatdate(effectiveDate);
    
    // Store data for later use
    _selectedEmployes = selectedEmployes;
    _salaryEmpId = selectedEmployes.id ?? 0;
    _totalWorkingHoursminuts = totalWorkingHoursminuts;
    _setYear = setYear;
    _setMonth = setMonth;
    _paidLeavecount = paidLeavecount;
    _paidleavhours = paidleavhours;
    _settotalBreak = settotalBreak;
    _settotalPresent = settotalPresent;
    _setweeklyOff = setweeklyOff;
    _setweeklyOffHour = setweeklyOffHour;
    _saveType = saveType;
    
    notifyListeners();
  }

  void setExistingEmployeeSalaryData(Salarys salaryData) {
    departmentController.text = salaryData.departmentName?.toString() ?? '';
    designationController.text = salaryData.positionName?.toString() ?? '';
    salaryAmountController.text = salaryData.basicSalary ?? '0';
    workingHoursController.text = salaryData.workingHours?.toString() ?? '0';
    totalHoursController.text = salaryData.totalHours?.toString() ?? '0';
    otHoursController.text = salaryData.oTHour?.toString() ?? '0';
    hraController.text = salaryData.hRA ?? '';
    daController.text = salaryData.dA ?? '';
    conveyanceController.text = salaryData.conveyance ?? '';
    medicalController.text = salaryData.medicalAmt?.toString() ?? '';
    allowanceController.text = salaryData.specialAllowance?.toString() ?? '';
    otherAdditionController.text = salaryData.otherAddition?.toString() ?? '';
    otController.text = salaryData.oTPerhour?.toString() ?? '0';
    pfController.text = salaryData.pF ?? '';
    esicController.text = salaryData.eSIC ?? '';
    professionalTaxController.text = salaryData.professinalTax?.toString() ?? '';
    tdsController.text = salaryData.tDS ?? '';
    otherDeductionController.text = salaryData.otherDeduction?.toString() ?? '';
    showFinalAmountPay = salaryData.finaleAmt?.toString() ?? '0.0';
    _setMonth = salaryData.monthYear?.split('-').last ?? '';
    _setYear = salaryData.monthYear?.split('-').first ?? '';
    _saveType = 'U';
    _salaryEmpId = salaryData.empId ?? 0;

    final parsedEffectiveDate = DateTime.tryParse(salaryData.effectiveDate ?? '');
    effectiveDate = parsedEffectiveDate ?? DateTime.now();
    txtEffectiveDateController.text = salaryData.effectiveDate?.isNotEmpty == true ? salaryData.effectiveDate! : dateFormatdate(effectiveDate);

    notifyListeners();
  }

  // ==================== MAIN SET DATA FUNCTION ====================
  Future<void> initializeEmployeeSalaryData(BuildContext context) async {
    setloading(true);
    try {
      await clearEmployeeSalaryData();
      // 1. Get Employee Wise Addition Deduction
      await _getEmployeewiseAdditionDeduction(context);
      
      // 2. Calculate Initial Salary
      _calculateInitialSalary();
      
      // 3. Calculate Net Salary
      calculateNetSalaryFromControllers();
      
      setloading(false);
      notifyListeners();
    } catch (e) {
      setloading(false);
    }
  }

  // ==================== PRIVATE METHODS FOR SETDATA ====================

  // 2. Get Employee Wise Addition Deduction
  Future<void> _getEmployeewiseAdditionDeduction(BuildContext context) async {
    try {
      final additionProvider = Provider.of<AdditionProvider>(context, listen: false);
      await additionProvider.getEmployeWiseAdditionDeduction(
        setemployeId: _selectedEmployes?.id ?? 0,
        setmonth: _setMonth,
        setyear: _setYear,
      );
      otherDeductionController.text = additionProvider.totalDeduction.toString();
      if(additionProvider.setAdditionValues!.addDedMst != null) {
        final element = additionProvider.setAdditionValues!.addDedMst;
        
        // Get base salary from selected employee
        double baseSalary = double.tryParse(_selectedEmployes?.salaryAmount ?? '0') ?? 0;
        
        // ==================== HRA Calculation ====================
        if (element!.hRAApplicable == true) {
          double hraPercentage = double.tryParse(element.hRA?.toString() ?? '0') ?? 0;
          double hraAmount = (baseSalary * hraPercentage) / 100;
          hraController.text = hraAmount.toStringAsFixed(2);
        } else {
          hraController.text = element.hRA ?? '0';
        }
        
        // ==================== DA Calculation ====================
        if (element.dAApplicable == true) {
          double daPercentage = double.tryParse(element.dA?.toString() ?? '0') ?? 0;
          double daAmount = (baseSalary * daPercentage) / 100;
          daController.text = daAmount.toStringAsFixed(2);
        } else {
          daController.text = element.dA ?? '0';
        }
        
        // ==================== Conveyance Calculation ====================
        if (element.conveyanceApplicable == true) {
          double conveyancePercentage = double.tryParse(element.conveyance?.toString() ?? '0') ?? 0;
          double conveyanceAmount = (baseSalary * conveyancePercentage) / 100;
          conveyanceController.text = conveyanceAmount.toStringAsFixed(2);
        } else {
          conveyanceController.text = element.conveyance ?? '0';
        }
        
        // ==================== Medical Calculation ====================
        if (element.medicalAmtApplicable == true) {
          double medicalPercentage = double.tryParse(element.medicalAmt?.toString() ?? '0') ?? 0;
          double medicalAmount = (baseSalary * medicalPercentage) / 100;
          medicalController.text = medicalAmount.toStringAsFixed(2);
        } else {
          medicalController.text = element.medicalAmt?.toString() ?? '0';
        }
        
        // ==================== Special Allowance Calculation ====================
        if (element.specialApplicable == true) {
          double allowancePercentage = double.tryParse(element.specialAllowance?.toString() ?? '0') ?? 0;
          double allowanceAmount = (baseSalary * allowancePercentage) / 100;
          allowanceController.text = allowanceAmount.toStringAsFixed(2);
        } else {
          allowanceController.text = element.specialAllowance?.toString() ?? '0';
        }
        
        // ==================== PF Calculation ====================
        if (element.pFApplicable == true) {
          double pfPercentage = double.tryParse(element.pF?.toString() ?? '0') ?? 0;
          double pfAmount = (baseSalary * pfPercentage) / 100;
          pfController.text = pfAmount.toStringAsFixed(2);
        } else {
          pfController.text = element.pF ?? '0';
        }
        
        // ==================== ESIC Calculation ====================
        if (element.eSICApplicable == true) {
          double esicPercentage = double.tryParse(element.eSIC?.toString() ?? '0') ?? 0;
          double esicAmount = (baseSalary * esicPercentage) / 100;
          esicController.text = esicAmount.toStringAsFixed(2);
        } else {
          esicController.text = element.eSIC ?? '0';
        }
        
        // ==================== Professional Tax Calculation ====================
        if (element.professinalApplicable == true) {
          double ptPercentage = double.tryParse(element.professinalTax?.toString() ?? '0') ?? 0;
          double ptAmount = (baseSalary * ptPercentage) / 100;
          professionalTaxController.text = ptAmount.toStringAsFixed(2);
        } else {
          professionalTaxController.text = element.professinalTax?.toString() ?? '0';
        }
        
        // ==================== TDS Calculation ====================
        if (element.tDSApplicable == true) {
          double tdsPercentage = double.tryParse(element.tDS?.toString() ?? '0') ?? 0;
          double tdsAmount = (baseSalary * tdsPercentage) / 100;
          tdsController.text = tdsAmount.toStringAsFixed(2);
        } else {
          tdsController.text = element.tDS?.toString() ?? '0';
        }
      }
    } catch (e) {
      otherDeductionController.text = '0';
    }
  }

  // 3. Calculate Initial Salary
  void _calculateInitialSalary() {
    try {
      int getSalaryAmount = int.tryParse(_selectedEmployes?.salaryAmount ?? '0') ?? 0;
      double totalHours = double.tryParse(_selectedEmployes?.totalhours?.toString() ?? '0') ?? 1;
      
      double hoursSalary = getSalaryAmount / totalHours;
      double minutesSalary = hoursSalary / 60;
      
      int hours = _totalWorkingHoursminuts.toInt() ~/ 60;
      int minutes = _totalWorkingHoursminuts.toInt() % 60;
      
      double countHoursSalary = hours * hoursSalary;
      double countMinutesSalary = minutes * minutesSalary;
      
      finalCountSalaryAmount = countHoursSalary + countMinutesSalary;
      showFinalAmountPay = finalCountSalaryAmount.toStringAsFixed(2);
    } catch (e) {
      showFinalAmountPay = '0.0';
    }
  }

  // ==================== CALCULATION METHODS ====================
  double convertTimeToDecimal(String time) {
    if (time.isEmpty) return 0.0;
    if (!time.contains(":")) return double.tryParse(time) ?? 0.0;
    List<String> parts = time.split(":");
    if (parts.length != 2) return 0.0;
    int hours = int.tryParse(parts[0]) ?? 0;
    int minutes = int.tryParse(parts[1]) ?? 0;
    return hours + (minutes / 60.0);
  }

 void calculateNetSalaryFromControllers() {
  try {
    // ==================== PARSE INPUT VALUES ====================
    double salaryAmt = double.tryParse(salaryAmountController.text) ?? 0;
    double workingHrs = double.tryParse(workingHoursController.text) ?? 0;
    double totalHrs = convertTimeToDecimal(totalHoursController.text);
    
    // Prevent division by zero
    if (workingHrs <= 0) workingHrs = 1;
    if (totalHrs <= 0) totalHrs = 0;
    
    // Calculate rate per hour
    double hourlyRate = salaryAmt / workingHrs;
    
    // ==================== ADDITIONS (All Plus) ====================
    double additions = (double.tryParse(hraController.text) ?? 0) +
                       (double.tryParse(daController.text) ?? 0) +
                       (double.tryParse(conveyanceController.text) ?? 0) +
                       (double.tryParse(medicalController.text) ?? 0) +
                       (double.tryParse(allowanceController.text) ?? 0) +
                       (double.tryParse(otherAdditionController.text) ?? 0);
    
    // ==================== DEDUCTIONS (All Minus) ====================
    double deductions = (double.tryParse(pfController.text) ?? 0) +
                        (double.tryParse(esicController.text) ?? 0) +
                        (double.tryParse(professionalTaxController.text) ?? 0) +
                        (double.tryParse(tdsController.text) ?? 0) +
                        (double.tryParse(otherDeductionController.text) ?? 0);
    
    // ==================== OT HOURS CALCULATION ====================
    // Calculate OT Hours (if total hours > expected working hours)
    double otHoursValue = 0;
    if (totalHrs > workingHrs) {
      otHoursValue = totalHrs - workingHrs;
      otHoursController.text = otHoursValue.toStringAsFixed(2);
    } else {
      otHoursController.text = "0";
    }
    
    // ==================== OT AMOUNT CALCULATION ====================
    // OT Amount = OT Hours × Hourly Rate
    double otAmount = otHoursValue * hourlyRate;
    otController.text = otAmount.toStringAsFixed(2);
    
    // ==================== BASE SALARY CALCULATION ====================
    // Base Salary Earned = Total Hours Worked × Hourly Rate
    double baseSalaryEarned = totalHrs * hourlyRate;
    
    // ==================== NET PAYABLE CALCULATION ====================
    // Formula: (Base Salary Earned) + (All Additions) - (All Deductions) + (OT Amount)
    // Note: OT is already included in baseSalaryEarned since totalHrs includes OT hours
    // So we don't add OT separately to avoid double counting
    
    // Option 1: Base Salary includes OT hours already
    double netSalary = baseSalaryEarned + additions - deductions;
    
    // Option 2: If OT should be added separately on top of base salary
    // double netSalary = baseSalaryEarned + additions + otAmount - deductions;
    
    if (netSalary < 0) netSalary = 0;
    
    // ==================== UPDATE UI VALUES ====================
    showFinalAmountPay = netSalary.toStringAsFixed(2);
    finalCountSalaryAmount = netSalary;
    amountPay = additions.toStringAsFixed(2);
    notifyListeners();
  } catch (e) { /* ignored */ }
}

  // ==================== UPDATE EFFECTIVE DATE ====================
  Future<void> updateEffectiveDate(DateTime newDate) async {
    effectiveDate = newDate;
    txtEffectiveDateController.text = dateFormatdate(effectiveDate);
    calculateNetSalaryFromControllers();
    notifyListeners();
  }

  // ==================== SAVE EMPLOYEE SALARY ====================
// Add these helper methods at the beginning of your PayRollProviders class

// ==================== TYPE SAFETY HELPERS ====================
int toSafeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double toSafeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String toSafeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

// ==================== FIXED SAVE EMPLOYEE SALARY ====================
Future<void> saveEmployeeSalary(BuildContext context) async {
  setloading(true);
  try {
    // ==================== PREPARE COMMON DATA ====================
    final salaryMonth = toSafeInt(_setMonth) != 0 ? toSafeInt(_setMonth) : addPayRollcurrentMonth.month;
    final salaryYear = toSafeInt(_setYear) != 0 ? toSafeInt(_setYear) : addPayRollcurrentMonth.year;
    final monthYear = '${salaryYear.toString().padLeft(4, '0')}-${salaryMonth.toString().padLeft(2, '0')}';
    final empId = _selectedEmployes?.id ?? _salaryEmpId;
    final useCguid = generateCustomUuid();
    
    // Convert all values to proper types
    final int totalPresentInt = toSafeInt(_settotalPresent);
    final int plInt = toSafeInt(_paidLeavecount);
    final int lwpInt = toSafeInt(usedlwp);
    
    final double finalAmountDouble = toSafeDouble(showFinalAmountPay);
    final double otherDeductionDouble = toSafeDouble(otherDeductionController.text);
    final double otHourDouble = toSafeDouble(otHoursController.text);
    final double totalPresentDouble = toSafeDouble(_settotalPresent);
    final double plDouble = toSafeDouble(_paidLeavecount);
    
    // String parameters
    final String basicSalary = toSafeString(salaryAmountController.text);
    final String conveyance = toSafeString(conveyanceController.text);
    final String da = toSafeString(daController.text);
    final String finalAmountStr = toSafeString(showFinalAmountPay);
    final String hra = toSafeString(hraController.text);
    final String medicalAmount = toSafeString(medicalController.text);
    final String otHour = toSafeString(otHoursController.text);
    final String otherDeduction = toSafeString(otherDeductionController.text);
    final String otherAddition = toSafeString(otherAdditionController.text);
    final String pf = toSafeString(pfController.text);
    final String workingHours = toSafeString(workingHoursController.text);
    final String tds = toSafeString(tdsController.text);
    final String specialAllowance = toSafeString(allowanceController.text);
    final String esic = toSafeString(esicController.text);
    final String professionalTax = toSafeString(professionalTaxController.text);
    final String totalHours = toSafeString(totalHoursController.text);
    final String totalBreak = toSafeString(_settotalBreak);
    final String totalPresentStr = totalPresentInt.toString();
    final String weeklyOff = toSafeString(_setweeklyOff);
    final String weeklyOffHour = toSafeString(_setweeklyOffHour);
    final String paidLeaveStr = plInt.toString();
    final String paidLeaveHour = toSafeString(_paidleavhours);
    final String lwpStr = lwpInt.toString();
    final String date = toSafeString(txtEffectiveDateController.text);
    final String overtime = toSafeString(otController.text);
    
    final int salaryMonthInt = salaryMonth;
    final int salaryYearInt = salaryYear;
    final int empIdInt = empId;
    
    if (_saveType == 'U') {
      // Update both APIs
      await _updatePaySlips(
        basicSalary: basicSalary,
        conveyance: conveyance,
        da: da,
        finalAmountStr: finalAmountStr,
        hra: hra,
        medicalAmount: medicalAmount,
        otHour: otHour,
        otherDeduction: otherDeduction,
        otherAddition: otherAddition,
        pf: pf,
        workingHours: workingHours,
        tds: tds,
        empIdInt: empIdInt,
        specialAllowance: specialAllowance,
        esic: esic,
        professionalTax: professionalTax,
        totalHours: totalHours,
        totalBreak: totalBreak,
        totalPresentStr: totalPresentStr,
        weeklyOff: weeklyOff,
        weeklyOffHour: weeklyOffHour,
        paidLeaveStr: paidLeaveStr,
        paidLeaveHour: paidLeaveHour,
        lwpStr: lwpStr,
        date: date,
        overtime: overtime,
        salaryMonthInt: salaryMonthInt,
        salaryYearInt: salaryYearInt,
        monthYear: monthYear,
        useCguid: useCguid,
        context: context,
      );
      
      await _updateStructure(
        basicSalary: basicSalary,
        hra: hra,
        da: da,
        conveyance: conveyance,
        tds: tds,
        esic: esic,
        pf: pf,
        overtime: overtime,
        finalAmountDouble: finalAmountDouble,
        medicalAmount: medicalAmount,
        otherAddition: otherAddition,
        specialAllowance: specialAllowance,
        professionalTax: professionalTax,
        totalHours: totalHours,
        workingHours: workingHours,
        otherDeductionDouble: otherDeductionDouble,
        otHourDouble: otHourDouble,
        totalPresentDouble: totalPresentDouble,
        plDouble: plDouble,
        lwpStr: lwpStr,
        weeklyOff: weeklyOff,
        weeklyOffHour: weeklyOffHour,
        paidLeaveHour: paidLeaveHour,
        salaryMonthInt: salaryMonthInt,
        salaryYearInt: salaryYearInt,
        totalBreak: totalBreak,
        monthYear: monthYear,
        useCguid: useCguid,
        empIdInt: empIdInt,
        context: context,
      );
    } else {
      // Create both APIs
      await _createPaySlips(
        basicSalary: basicSalary,
        conveyance: conveyance,
        da: da,
        finalAmountStr: finalAmountStr,
        hra: hra,
        medicalAmount: medicalAmount,
        otHour: otHour,
        otherDeduction: otherDeduction,
        otherAddition: otherAddition,
        pf: pf,
        workingHours: workingHours,
        tds: tds,
        empIdInt: empIdInt,
        specialAllowance: specialAllowance,
        esic: esic,
        professionalTax: professionalTax,
        totalHours: totalHours,
        totalBreak: totalBreak,
        totalPresentStr: totalPresentStr,
        weeklyOff: weeklyOff,
        weeklyOffHour: weeklyOffHour,
        paidLeaveStr: paidLeaveStr,
        paidLeaveHour: paidLeaveHour,
        lwpStr: lwpStr,
        date: date,
        overtime: overtime,
        salaryMonthInt: salaryMonthInt,
        salaryYearInt: salaryYearInt,
        monthYear: monthYear,
        useCguid: useCguid,
        context: context,
      );
      
      await _createStructure(
        basicSalary: basicSalary,
        hra: hra,
        da: da,
        conveyance: conveyance,
        tds: tds,
        esic: esic,
        pf: pf,
        overtime: overtime,
        finalAmountDouble: finalAmountDouble,
        medicalAmount: medicalAmount,
        otherAddition: otherAddition,
        specialAllowance: specialAllowance,
        professionalTax: professionalTax,
        totalHours: totalHours,
        workingHours: workingHours,
        otherDeductionDouble: otherDeductionDouble,
        otHourDouble: otHourDouble,
        totalPresentDouble: totalPresentDouble,
        plDouble: plDouble,
        lwpStr: lwpStr,
        weeklyOff: weeklyOff,
        weeklyOffHour: weeklyOffHour,
        paidLeaveHour: paidLeaveHour,
        salaryMonthInt: salaryMonthInt,
        salaryYearInt: salaryYearInt,
        totalBreak: totalBreak,
        monthYear: monthYear,
        useCguid: useCguid,
        empIdInt: empIdInt,
        context: context,
      );
    }
    
    showtoastmessage('Salary structure saved successfully');
    backScreen(context);
    backScreen(context);
    setloading(false);
    notifyListeners();
  } catch (e) {
    setloading(false);
    showtoastmessage('Error saving salary structure: ${e.toString()}');
  }
}

// ==================== CREATE PAYSLIPS ====================
Future<void> _createPaySlips({
  required String basicSalary,
  required String conveyance,
  required String da,
  required String finalAmountStr,
  required String hra,
  required String medicalAmount,
  required String otHour,
  required String otherDeduction,
  required String otherAddition,
  required String pf,
  required String workingHours,
  required String tds,
  required int empIdInt,
  required String specialAllowance,
  required String esic,
  required String professionalTax,
  required String totalHours,
  required String totalBreak,
  required String totalPresentStr,
  required String weeklyOff,
  required String weeklyOffHour,
  required String paidLeaveStr,
  required String paidLeaveHour,
  required String lwpStr,
  required String date,
  required String overtime,
  required int salaryMonthInt,
  required int salaryYearInt,
  required String monthYear,
  required String useCguid,
  required BuildContext context,
}) async {
  final api = PaySlipApiSerices();
  await api.createPaySlips(
    basicsalarys: basicSalary,
    conveyance: conveyance,
    da: da,
    finaleAmt: finalAmountStr,
    hra: hra,
    medicalamounts: medicalAmount,
    oTHour: otHour,
    otherDeduction: otherDeduction,
    otherAddition: otherAddition,
    pf: pf,
    workingHours: workingHours,
    tds: tds,
    employeid: empIdInt,
    specialAllowance: specialAllowance,
    esic: esic,
    grossEarnings: '',
    salaryMonth: salaryMonthInt,
    monthYear: monthYear,
    lwp: lwpStr,
    lWPHour: '0',
    pl: paidLeaveStr,
    pLHour: paidLeaveHour,
    professinalTax: professionalTax,
    salaryYear: salaryYearInt.toString(),
    totalBreak: totalBreak,
    totalDeductions: '',
    totalHours: totalHours,
    totalPresent: totalPresentStr,
    weeklyOff: weeklyOff,
    weeklyOffHour: weeklyOffHour,
    cguids: useCguid,
    date: date,
    overtime: overtime,
  ).then((value) {
    NewPayRoll newPayRoll = value as NewPayRoll;
    if (newPayRoll.success == true) {
    }
  }).catchError((error) {
  });
}

// ==================== UPDATE PAYSLIPS ====================
Future<void> _updatePaySlips({
  required String basicSalary,
  required String conveyance,
  required String da,
  required String finalAmountStr,
  required String hra,
  required String medicalAmount,
  required String otHour,
  required String otherDeduction,
  required String otherAddition,
  required String pf,
  required String workingHours,
  required String tds,
  required int empIdInt,
  required String specialAllowance,
  required String esic,
  required String professionalTax,
  required String totalHours,
  required String totalBreak,
  required String totalPresentStr,
  required String weeklyOff,
  required String weeklyOffHour,
  required String paidLeaveStr,
  required String paidLeaveHour,
  required String lwpStr,
  required String date,
  required String overtime,
  required int salaryMonthInt,
  required int salaryYearInt,
  required String monthYear,
  required String useCguid,
  required BuildContext context,
}) async {
  final api = PaySlipApiSerices();
  await api.updatePaySlips(
    basicsalarys: basicSalary,
    conveyance: conveyance,
    da: da,
    finaleAmt: finalAmountStr,
    hra: hra,
    medicalamounts: medicalAmount,
    oTHour: otHour,
    otherDeduction: otherDeduction,
    otherAddition: otherAddition,
    pf: pf,
    workingHours: workingHours,
    tds: tds,
    employeid: empIdInt,
    specialAllowance: specialAllowance,
    esic: esic,
    grossEarnings: '',
    salaryMonth: salaryMonthInt,
    monthYear: monthYear,
    lwp: lwpStr,
    lWPHour: '0',
    pl: paidLeaveStr,
    pLHour: paidLeaveHour,
    professinalTax: professionalTax,
    salaryYear: salaryYearInt.toString(),
    totalBreak: totalBreak,
    totalDeductions: '',
    totalHours: totalHours,
    totalPresent: totalPresentStr,
    weeklyOff: weeklyOff,
    weeklyOffHour: weeklyOffHour,
    cguids: useCguid,
    date: date,
    overtime: overtime,
  ).then((value) {
    NewPayRoll newPayRoll = value as NewPayRoll;
    if (newPayRoll.success == true) {
    }
  }).catchError((error) {
  });
}

// ==================== CREATE STRUCTURE ====================
Future<void> _createStructure({
  required String basicSalary,
  required String hra,
  required String da,
  required String conveyance,
  required String tds,
  required String esic,
  required String pf,
  required String overtime,
  required double finalAmountDouble,
  required String medicalAmount,
  required String otherAddition,
  required String specialAllowance,
  required String professionalTax,
  required String totalHours,
  required String workingHours,
  required double otherDeductionDouble,
  required double otHourDouble,
  required double totalPresentDouble,
  required double plDouble,
  required String lwpStr,
  required String weeklyOff,
  required String weeklyOffHour,
  required String paidLeaveHour,
  required int salaryMonthInt,
  required int salaryYearInt,
  required String totalBreak,
  required String monthYear,
  required String useCguid,
  required int empIdInt,
  required BuildContext context,
}) async {
  await PayRollApiSerices().createnewStructure(
    basicSalary: basicSalary,
    hra: hra,
    da: da,
    conveyance: conveyance,
    tds: tds,
    esic: esic,
    cguid: useCguid,
    pf: pf,
    otphours: overtime,
    finalamount: finalAmountDouble,
    medicalamount: medicalAmount,
    otherDeduction: otherDeductionDouble,
    specialAllowance: specialAllowance,
    professinalTax: professionalTax,
    totalHours: totalHours,
    workingHours: workingHours,
    othetaddition: otherAddition,
    oTHour: otHourDouble,
    monthYear: monthYear,
    grossEarnings: '',
    lWP: lwpStr,
    weeklyOff: weeklyOff,
    totalPresent: totalPresentDouble,
    weeklyOffHour: weeklyOffHour,
    lWPHour: '0',
    lOP: '',
    salaryMonth: salaryMonthInt,
    salaryYear: salaryYearInt,
    totalDeductions: '',
    totalBreak: totalBreak,
    pL: plDouble,
    pLHour: paidLeaveHour,
    setEmpid: empIdInt,
  ).then((value) {
    CreateSalaryStructure createResponse = value as CreateSalaryStructure;
    if (createResponse.success == true) {
    }
  }).catchError((error) {
  });
}

// ==================== UPDATE STRUCTURE ====================
Future<void> _updateStructure({
  required String basicSalary,
  required String hra,
  required String da,
  required String conveyance,
  required String tds,
  required String esic,
  required String pf,
  required String overtime,
  required double finalAmountDouble,
  required String medicalAmount,
  required String otherAddition,
  required String specialAllowance,
  required String professionalTax,
  required String totalHours,
  required String workingHours,
  required double otherDeductionDouble,
  required double otHourDouble,
  required double totalPresentDouble,
  required double plDouble,
  required String lwpStr,
  required String weeklyOff,
  required String weeklyOffHour,
  required String paidLeaveHour,
  required int salaryMonthInt,
  required int salaryYearInt,
  required String totalBreak,
  required String monthYear,
  required String useCguid,
  required int empIdInt,
  required BuildContext context,
}) async {
  await PayRollApiSerices().updateNewStructure(
    basicSalary: basicSalary,
    hra: hra,
    da: da,
    conveyance: conveyance,
    tds: tds,
    esic: esic,
    cguid: useCguid,
    pf: pf,
    otphours: overtime,
    finalamount: finalAmountDouble,
    medicalamount: medicalAmount,
    otherDeduction: otherDeductionDouble,
    specialAllowance: specialAllowance,
    professinalTax: professionalTax,
    totalHours: totalHours,
    workingHours: workingHours,
    othetaddition: otherAddition,
    oTHour: otHourDouble,
    monthYear: monthYear,
    grossEarnings: '',
    lWP: lwpStr,
    weeklyOff: weeklyOff,
    totalPresent: totalPresentDouble,
    weeklyOffHour: weeklyOffHour,
    lWPHour: '0',
    lOP: '',
    salaryMonth: salaryMonthInt,
    salaryYear: salaryYearInt,
    totalDeductions: '',
    totalBreak: totalBreak,
    pL: plDouble,
    pLHour: paidLeaveHour,
    setEmpid: empIdInt,
  ).then((value) {
    CreateSalaryStructure createResponse = value as CreateSalaryStructure;
    if (createResponse.success == true) {
    }
  }).catchError((error) {
  });
}
  // ==================== GETTERS FOR UI ====================
  String get department => departmentController.text;
  String get designation => designationController.text;
  String get bankName => bankNameController.text;
  String get bankNumber => bankNumberController.text;
  String get salaryAmount => salaryAmountController.text;
  String get workingHours => workingHoursController.text;
  String get totalHours => totalHoursController.text;
  String get otHours => otHoursController.text;
  String get hra => hraController.text;
  String get da => daController.text;
  String get conveyance => conveyanceController.text;
  String get medical => medicalController.text;
  String get allowance => allowanceController.text;
  String get otherAddition => otherAdditionController.text;
  String get ot => otController.text;
  String get pf => pfController.text;
  String get esic => esicController.text;
  String get professionalTax => professionalTaxController.text;
  String get tds => tdsController.text;
  String get otherDeduction => otherDeductionController.text;
  String get finalAmountPay => showFinalAmountPay;

  // ==================== DATE PICKER ====================
  Future selectDatePicker(BuildContext context, Size size, {required CommandWidigetsProvider dateController, DateTime? selectDatePic, DateTime? pickerStartDate}) async {
    await dateController.pickDate(context, size, selectDatePic ?? effectiveDate, pickerStartDate ?? DateTime(1900), DateTime(3100), (value) {
      updateEffectiveDate(value);
    });
    return effectiveDate;
  }
}
