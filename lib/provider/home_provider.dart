// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, strict_top_level_inference, empty_catches
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/api/companiapi.dart';
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/attendance/monathattendace.dart';
import 'package:tax_hrm/models/company/getallcompany.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/models/top_hrm_model.dart';
import 'package:tax_hrm/page/home/leaderborder.dart';
import 'package:tax_hrm/page/addition_deduction/addition_deduction_screen.dart';
import 'package:tax_hrm/page/admin_leave_master/admin_leave_master_screen.dart';
import 'package:tax_hrm/page/department/department_menu_screen.dart';
import 'package:tax_hrm/page/document/showdocument_screen.dart';
import 'package:tax_hrm/page/employee_master/employee_master_screen.dart';
import 'package:tax_hrm/page/event/event_page_screen.dart';
import 'package:tax_hrm/page/holidays/show_holidays.dart';
import 'package:tax_hrm/page/notes/notespage.dart';
import 'package:tax_hrm/page/payroll_mater/payroll_mater_screen.dart';
import 'package:tax_hrm/page/payroll_summary/payroll_summary_screen.dart';
import 'package:tax_hrm/page/payslip_mater/payslip_mater_screen.dart';
import 'package:tax_hrm/page/recruitment/recruitment_page_screen.dart';
import 'package:tax_hrm/page/salaryslip/salary_payslip_screen.dart';
import 'package:tax_hrm/page/shift/shift_master_screen.dart';
import 'package:tax_hrm/page/shift/shift_timing/shift_timing_master_screen.dart';
import 'package:tax_hrm/page/usertimelineview/timelinepop.dart';
import 'package:tax_hrm/page/usertimelineview/usertimeline.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/holidayprovider.dart';
import 'package:tax_hrm/provider/payrollprovider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';

class HomeProvider extends ChangeNotifier {
  bool _notifyScheduled = false;

  @override
  void notifyListeners() {
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    final canNotifyNow = schedulerPhase == SchedulerPhase.idle || schedulerPhase == SchedulerPhase.postFrameCallbacks;

    if (canNotifyNow) {
      super.notifyListeners();
      return;
    }

    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      super.notifyListeners();
    });
  }

  bool islodering = false;

  setloading(bool value) {
    islodering = value;
  }

  List<HomeGridClass> homeGridOptionList = [];


  homeLoadDatas(context) async {
    await companySelect();
    await homepageMenuGet(context);
    await getTopLeaderboard();
  }

  // home menu design
  homepageMenuGet(context) {
    homeGridOptionList = curentUser['Role'] == 'Admin' ? [
      HomeGridClass(image: attendanceUserString, title: attendanceString, onTap: () {
        lastBottomIndex = 1;
        selectedIndex = 1;
        fabSelected = false;
      },),
      HomeGridClass(image: leaveImgString, title: leaveString, onTap: (){
        lastBottomIndex = 2;
        selectedIndex = 2;
        fabSelected = false;
      }),
      HomeGridClass(image: employeeMasterImageString, title: employeeMasterTitleString, onTap: () {
        nextScreen(context, EmployeeMasterScreen(), onthenValue: (value) {});
      },),
      HomeGridClass(image: paySlipImageString, title: paySlipString, onTap: () {
        nextScreen(context, PaySlipMaterScreen(), onthenValue: (value) {});
      },),
      HomeGridClass(image: holidayImageString, title: holidayString, onTap: () {
        nextScreen(context, ShowHolidayViews(), onthenValue: (value) {});
      },), 
      HomeGridClass(image: payrollMasterImageString, title: payrollMasterString, onTap: () {
        nextScreen(context, PayrollMaterScreen(), onthenValue: (value) {});
      },), 
      HomeGridClass(image: payrollSummeryImageString, title: payrollSummeryString, onTap: (){
        nextScreen(context, PayrollSummaryScreen(), onthenValue: (value) {});
      }),
      HomeGridClass(image: leaveMstImageString, title: leaveMasterString, onTap: () {
        nextScreen(context, AdminLeaveMasterScreen(), onthenValue: (value) {});
      },),
      HomeGridClass(image: shiftMstImageString, title: shiftMasterString, onTap: (){
         nextScreen(context, ShiftMasterScreen(), onthenValue: (value) {});
      }),
      HomeGridClass(image: shiftTimingImageString, title: shiftTimingString, onTap: () {
        nextScreen(context, ShiftTimingMasterScreen(), onthenValue: (value) {});
      }),
      HomeGridClass(image: departmentImageString, title: departmentString, onTap: (){
        nextScreen(context, DepartmentMenuScreen(), onthenValue: (value) {});
      }),
      HomeGridClass(image: eventImageString, title: eventString, onTap: () {
        nextScreen(context, EventPageScreen(), onthenValue: (value) {});
      }),
      HomeGridClass(image: candidateImageString, title: recuritmentString, onTap: () {
        nextScreen(context, RecruitmentPageScreen(), onthenValue: (value) {});
      }),
      HomeGridClass(image: aediDecImageString, title: addDeduString, onTap: () {
        nextScreen(context, AdditionDeductionScreen(), onthenValue: (value) {});
      }),
    ] : [
      HomeGridClass(image: attendanceUserString, title: attendanceString,onTap: (){
        lastBottomIndex = 1;
        selectedIndex = 1;
        fabSelected = false;
      }),
      HomeGridClass(image: leaveImgString, title: leaveString,onTap: (){
        lastBottomIndex = 2;
        selectedIndex = 2;
        fabSelected = false;
      }),
      HomeGridClass(image: salarySlipsImageString, title: salarySlipString,onTap: () {
        nextScreen(context, SalaryPayslipScreen(), onthenValue: (value) {});
      }),
      HomeGridClass(image: holidayImageString, title: holidayString,onTap: () {
        nextScreen(context, ShowHolidayViews(), onthenValue: (value) {});
      },),
      HomeGridClass(image: notesImageString, title: noteString,onTap: () {
        nextScreen(context, NotesViewPage(), onthenValue: (value) {});
      },),
      HomeGridClass(image: documentImageString, title: documentString,onTap: () {
        nextScreen(context, ShowDocumentScreen(), onthenValue: (value) {});
      },),
      HomeGridClass(image: timelineImageString, title: timeLineString,onTap: (){
         showDialog(context: context,builder: (context) => LocationTimeLines(),);
      }),
      HomeGridClass(image: timelineviewString, title: timeLineViewString,onTap: () {
        nextScreen(context, EmployeTimelines(userId: curentUser['Id'].toString()),onthenValue: (value){});
      },),
    ];
  }

  void changeSelectBottomBar(int value) {
    lastBottomIndex = value;
    selectedIndex = value;
    fabSelected = false;
    notifyListeners();
  }

  selectFloadButton() {
    fabSelected = true;
    selectedIndex = lastBottomIndex;
    notifyListeners();
  }

  homeMenuiHandleSubmit(context, HomeGridClass selectedHomeMenu) async {
    try {
      setloading(true);
      notifyListeners();
      await selectedHomeMenu.onTap?.call();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  companySelect() async {
    await CompanyDataApis().getCompanyDataList().then((value) async {
      getAllCompany = value;
      await setcompanyselected();
    }).onError((error, stackTrace) {});
  }

  Future setcompanyselected() async {
    await SaveUser().getselectedcompany().then((value) async {
      if (value != '') {
        Map<String, dynamic> jsonMap = jsonDecode(value);
        GetCompanyData holadcompany = GetCompanyData.fromJson(jsonMap);
        for (var element in getAllCompany) {
          if (element.companyId.toString() == holadcompany.companyId.toString()) {
            selectedcurentcompany = element;
            notifyListeners();
          }
        }
      } else {
        selectedcurentcompany = getAllCompany[0];
        String setdata = jsonEncode(selectedcurentcompany);
        SaveUser().saveselectedcopany(setdata);
        setcompanyselected();
      }
      if (selectedcurentcompany != null) {
        FcmTokenService.instance.subscribeToCompanyTopic();
      }
    });
  }

  companyHandleSubmit(context,{size}) {
    showCompanySelectDialog(context,size: size);
  }

  selectCompanyOntap(item,context) async {
    selectedcurentcompany = item;
    notifyListeners();
    Navigator.pop(context);
    String setdata =  jsonEncode(selectedcurentcompany);
    SaveUser().saveselectedcopany(setdata);
    await setcompanyselected();
    ReminderNotificationService.scheduleAllNotifications(forceRefresh: true);
    await FcmTokenService.instance.updateTopicSubscriptions();
  }

  // Working Hours Related
  Timer? _workingHoursTimer;
  String _currentWorkingHours = "00:00";
  bool _isCurrentlyWorking = false;
  
  String get currentWorkingHours => _currentWorkingHours;
  bool get isCurrentlyWorking => _isCurrentlyWorking;
  
  // Check times
  String _checkInTime = "00:00";
  String _checkOutTime = "00:00";
  
  String get checkInTime => _checkInTime;
  String get checkOutTime => _checkOutTime;

  // Start the auto-update timer
  void startWorkingHoursTimer(BuildContext context) {
    final selfiePunchProvider = Provider.of<SelfiePunchProvider>(context, listen: false);
    stopWorkingHoursTimer();

    // Instantly update UI with cached status if any
    _updateWorkingHours(selfiePunchProvider);

    // Start the 1-second UI update timer immediately (no guard — timer is set here first)
    _workingHoursTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timer.isActive) {
        _updateWorkingHours(selfiePunchProvider);
      }
    });

    // Fetch fresh attendance data on first frame after the timer is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await selfiePunchProvider.checkLastPunch(curentUser['Id'], context);
      } catch (e) {
        // ignore errors
      }
      _updateWorkingHours(selfiePunchProvider);
    });
  }

  // Stop the timer
  void stopWorkingHoursTimer() {
    _workingHoursTimer?.cancel();
    _workingHoursTimer = null;
  }

  // MAIN WORKING HOURS CALCULATION LOGIC (from your commanCheck)
  String _calculateTotalWorkingHours(SelfiePunchProvider selfiePunchProvider) {
    if (selfiePunchProvider.checkStatus == null ||
        selfiePunchProvider.checkStatus!.attendenceLog == null ||
        selfiePunchProvider.checkStatus!.attendenceLog!.isEmpty) {
      return "00:00";
    }

    final logs = selfiePunchProvider.checkStatus!.attendenceLog!;
    final int usedLength = logs.length;
    
    int totalMinutes = 0;
    
    try {
      // If last status is OUT (complete day)
      if (logs.last.status == 'OUT') {
        // Calculate all IN-OUT pairs
        for (int i = 0; i < usedLength; i += 2) {
          if (i < usedLength - 1) {
            DateTime inTime = DateTime.parse(logs[i].time.toString());
            DateTime outTime = DateTime.parse(logs[i + 1].time.toString());
            Duration duration = outTime.difference(inTime);
            totalMinutes += duration.inMinutes;
          }
        }
      } 
      // If last status is IN (currently working)
      else {
        // First, calculate all completed pairs
        int completedPairs = (usedLength - 1) ~/ 2;
        
        for (int i = 0; i < completedPairs * 2; i += 2) {
          if (i + 1 < usedLength) {
            DateTime inTime = DateTime.parse(logs[i].time.toString());
            DateTime outTime = DateTime.parse(logs[i + 1].time.toString());
            Duration duration = outTime.difference(inTime);
            totalMinutes += duration.inMinutes;
          }
        }
        
        // Add current ongoing session
        DateTime lastInTime = DateTime.parse(logs.last.time.toString());
        Duration currentDuration = DateTime.now().difference(lastInTime);
        totalMinutes += currentDuration.inMinutes;
      }
      
      // Convert to hours and minutes
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;
      
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      
    } catch (e) {
      return "00:00";
    }
  }

  // Get check-in time (first IN of the day)
  String _getCheckInTime(SelfiePunchProvider selfiePunchProvider) {
    if (selfiePunchProvider.checkStatus == null ||
        selfiePunchProvider.checkStatus!.attendenceLog == null ||
        selfiePunchProvider.checkStatus!.attendenceLog!.isEmpty) {
      return "00:00";
    }

    final logs = selfiePunchProvider.checkStatus!.attendenceLog!;
    
    // Find first IN log
    for (var log in logs) {
      if (log.status == 'IN') {
        if (log.time != null) {
          return DateFormat('hh:mm a').format(DateTime.parse(log.time.toString()));
        }
      }
    }
    
    return "00:00";
  }

  // Get check-out time (last OUT of the day)
  String _getCheckOutTime(SelfiePunchProvider selfiePunchProvider) {
    if (selfiePunchProvider.checkStatus == null ||
        selfiePunchProvider.checkStatus!.attendenceLog == null ||
        selfiePunchProvider.checkStatus!.attendenceLog!.isEmpty) {
      return "00:00";
    }

    final logs = selfiePunchProvider.checkStatus!.attendenceLog!;
    
    // Find last OUT log
    for (int i = logs.length - 1; i >= 0; i--) {
      if (logs[i].status == 'OUT') {
        if (logs[i].time != null) {
          return DateFormat('hh:mm a').format(DateTime.parse(logs[i].time.toString()));
        }
      }
    }
    
    return "00:00";
  }

  // Get working status (checked in but not checked out)
  bool _getWorkingStatus(SelfiePunchProvider selfiePunchProvider) {
    if (selfiePunchProvider.checkStatus == null ||
        selfiePunchProvider.checkStatus!.attendenceLog == null ||
        selfiePunchProvider.checkStatus!.attendenceLog!.isEmpty) {
      return false;
    }

    final logs = selfiePunchProvider.checkStatus!.attendenceLog!;
    
    // If last log is IN, user is currently working
    if (logs.last.status == 'IN') {
      return true;
    }
    
    return false;
  }

  // Update working hours calculation
  void _updateWorkingHours(SelfiePunchProvider selfiePunchProvider) {
    try {
      // Only proceed if data is available
      if (selfiePunchProvider.checkStatus == null ||
          selfiePunchProvider.checkStatus!.attendenceLog == null ||
          selfiePunchProvider.checkStatus!.attendenceLog!.isEmpty) {
        return;
      }
      
      final newWorkingHours = _calculateTotalWorkingHours(selfiePunchProvider);
      final newCheckInTime = _getCheckInTime(selfiePunchProvider);
      final newCheckOutTime = _getCheckOutTime(selfiePunchProvider);
      final newWorkingStatus = _getWorkingStatus(selfiePunchProvider);
      
      bool hasChanges = false;
      
      if (_currentWorkingHours != newWorkingHours) {
        _currentWorkingHours = newWorkingHours;
        hasChanges = true;
      }
      
      if (_checkInTime != newCheckInTime) {
        _checkInTime = newCheckInTime;
        hasChanges = true;
      }
      
      if (_checkOutTime != newCheckOutTime) {
        _checkOutTime = newCheckOutTime;
        hasChanges = true;
      }
      
      if (_isCurrentlyWorking != newWorkingStatus) {
        _isCurrentlyWorking = newWorkingStatus;
        hasChanges = true;
      }
      
      if (hasChanges) {
        notifyListeners();
      }
    } catch (e) { /* ignored */ }
  }

  // Manual refresh method
  void refreshWorkingHours(BuildContext context) {
    final selfiePunchProvider = Provider.of<SelfiePunchProvider>(context, listen: false);
    _updateWorkingHours(selfiePunchProvider);
  }

  // Force refresh from outside
  void forceRefresh() {
    notifyListeners();
  }

// Statistics Variables
  int _totalHour = 0;
  int _totalMinute = 0;
  String _paidLeaveHours = "00:00";
  String _holidayHoursCount = "00:00";
  String _totalBreakHours = "00:00";
  String _expectedTotalHours = "0";
  bool _isCalculating = false;
  
  int get totalHour => _totalHour;
  int get totalMinute => _totalMinute;
  String get paidLeaveHours => _paidLeaveHours;
  String get holidayHoursCount => _holidayHoursCount;
  String get totalBreakHours => _totalBreakHours;
  String get expectedTotalHours => _expectedTotalHours;
  bool get isCalculating => _isCalculating;

  // Calculate Paid Leave Hours
  double _calculatePaidLeaveHours(EmployeAttendance attendance) {
    if (attendance.leaveDuration != null) {
      final leaveDuration = attendance.leaveDuration.toString().toLowerCase();
      final duration = double.tryParse(leaveDuration);
      if (duration != null) return duration;
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

  // Calculate Holiday Leave
  double _calculateHolidayLeave(GetHolidayViews holiday) {
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

  // Main Calculate Time Function
  Future<void> calculateTime(BuildContext context) async {
    if (_isCalculating) return;
    
    _isCalculating = true;
    _totalHour = 0;
    _totalMinute = 0;
    _paidLeaveHours = "00:00";
    _holidayHoursCount = "00:00";
    _totalBreakHours = "00:00";
    notifyListeners();

    try {
      double useTotalMinuts = 0;
      double paidLeave = 0;
      double holidayLeave = 0;
      double setShitBreak = 0;
      double premOutMinuts = 0;

      // Get attendance provider
      final attendanceProvider = Provider.of<AttendanceEmp>(context, listen: false);
      final holidayProvider = Provider.of<HolidayeMastServices>(context, listen: false);
      final payrollProvider = Provider.of<PayRollProviders>(context, listen: false);
      final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

      attendanceProvider.currentMonth = currentMonth;
      await attendanceProvider.getEmpAttendanceData(
        curentUser['Id'],
        currentMonth.month,
        currentMonth.year,
        context,
      );
      if (!context.mounted) return;

      await payrollProvider.getMonthsBreaks(
        setEmployeId: curentUser['Id'],
        setMonth: currentMonth.month,
        setYear: currentMonth.year,
      );
      if (!context.mounted) return;
      
      // Get user shift data
      GetShiftMasterData? getUserShift = await _getUserShift(context);
      if (!context.mounted) return;
      
      if (getUserShift == null) {
        _isCalculating = false;
        notifyListeners();
        return;
      }

      // Calculate total minutes from attendance
      attendanceProvider.getMonthAttenDance.forEach((element) {
        if (element.totalMinute != null) {
          useTotalMinuts += int.parse(element.totalMinute.toString());
        }

        // Calculate shift breaks
        if (element.present == true) {
          if (getUserShift.break1 == true && getUserShift.break1Duration != null) {
            DateTime parsedDateTime = DateTime.parse(getUserShift.break1Duration!);
            setShitBreak += parsedDateTime.hour * 60 + parsedDateTime.minute;
          }
          if (getUserShift.break2 == true && getUserShift.break2Duration != null) {
            DateTime parsedDateTime = DateTime.parse(getUserShift.break2Duration!);
            setShitBreak += parsedDateTime.hour * 60 + parsedDateTime.minute;
          }
        }

        // Calculate paid leave
        if (element.leaveGroup == 'Paid') {
          paidLeave += _calculatePaidLeaveHours(element);
        }
      });

      // Get payroll data
      await payrollProvider.getPayRollData(
        setEmployeId: curentUser['Id'],
        setMonth: currentMonth.month,
        setYear: currentMonth.year,
      );
      if (!context.mounted) return;

      // Calculate break minutes
      if (payrollProvider.getPayRollAttendanceData.isEmpty) {
        payrollProvider.getAllMonthsBreak.forEach((element) {
          premOutMinuts += double.parse(element.totalOutMinutes.toString());
        });
      } else {
        payrollProvider.getPayRollAttendanceData.forEach((element) {
          if (element.totalBreak != null) {
            premOutMinuts += double.parse(element.totalBreak.toString());
          }
        });
      }

      // Calculate day total minutes from shift duration
      DateFormat dateFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
      DateTime parsedDateTime = dateFormat.parse(getUserShift.shiftDuration ?? '');
      int dayTotalMinuts = parsedDateTime.hour * 60 + parsedDateTime.minute;

      // Calculate paid leave duration
      double paidLeaveDuration = dayTotalMinuts * paidLeave;
      useTotalMinuts += paidLeaveDuration;

      // Get current date range
      DateTime firstDate = DateTime(currentMonth.year, currentMonth.month, 1);
      DateTime lastDate = DateTime(currentMonth.year, currentMonth.month + 1, 0);

      // Filter holidays
      List<GetHolidayViews> filteredDates = holidayProvider.mainHolidayList.where((date) {
        DateTime holidayDate = DateTime.parse(date.holidayDate ?? '');
        return !holidayDate.isBefore(firstDate) && !holidayDate.isAfter(lastDate);
      }).toList();

      // Calculate holiday duration
      final attendanceCounting = attendanceProvider.setEmpAttendanc;
      if (attendanceCounting != null && 
          attendanceCounting.isNotEmpty && 
          attendanceCounting.first.totalHolidays != null) {
        holidayLeave = double.parse(attendanceCounting.first.totalHolidays.toString());
      } else {
        filteredDates.forEach((element) {
          holidayLeave += _calculateHolidayLeave(element);
        });
      }
      
      double holidayDuration = dayTotalMinuts * holidayLeave;
      useTotalMinuts += holidayDuration;

      // Calculate break time
      int breakTotalMinutes = premOutMinuts.toInt();
      int breakHours = breakTotalMinutes ~/ 60;
      int breakMinutes = breakTotalMinutes % 60;
      _totalBreakHours = "$breakHours : $breakMinutes";

      // Final calculations
      useTotalMinuts -= premOutMinuts.toInt();
      useTotalMinuts -= setShitBreak.toInt();

      int ss = useTotalMinuts ~/ 60;
      int ww = useTotalMinuts.toInt() % 60;
      
      _totalHour = ss;
      _totalMinute = ww;

      // Format paid leave hours
      int paidLeaveTotalMinutes = paidLeaveDuration.toInt();
      int paidLeaveHour = paidLeaveTotalMinutes ~/ 60;
      int paidLeaveMinute = paidLeaveTotalMinutes % 60;
      _paidLeaveHours = "$paidLeaveHour : $paidLeaveMinute";

      // Format holiday hours
      int holidayTotalMinutes = holidayDuration.toInt();
      int holidayHours = holidayTotalMinutes ~/ 60;
      int holidayMinutes = holidayTotalMinutes % 60;
      _holidayHoursCount = "$holidayHours : $holidayMinutes";

      // Calculate expected total hours from shift
      int totalDaysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
      int weekOffs = 0;
      for (int i = 1; i <= totalDaysInMonth; i++) {
        DateTime day = DateTime(currentMonth.year, currentMonth.month, i);
        if (getUserShift.mon == false && day.weekday == 1) weekOffs++;
        else if (getUserShift.tue == false && day.weekday == 2) weekOffs++;
        else if (getUserShift.wed == false && day.weekday == 3) weekOffs++;
        else if (getUserShift.thu == false && day.weekday == 4) weekOffs++;
        else if (getUserShift.fri == false && day.weekday == 5) weekOffs++;
        else if (getUserShift.sat == false && day.weekday == 6) weekOffs++;
        else if (getUserShift.sun == false && day.weekday == 7) weekOffs++;
      }
      
      int expectedWorkingDays = totalDaysInMonth - weekOffs;
      
      int dailyBreakMins = 0;
      if (getUserShift.break1 == true) {
        try {
          final b1 = DateTime.parse(getUserShift.break1Duration ?? '');
          dailyBreakMins += b1.hour * 60 + b1.minute;
        } catch (e) { /* ignored */ }
      }
      if (getUserShift.break2 == true) {
        try {
          final b2 = DateTime.parse(getUserShift.break2Duration ?? '');
          dailyBreakMins += b2.hour * 60 + b2.minute;
        } catch (e) { /* ignored */ }
      }
      
      int expectedNetDailyMins = dayTotalMinuts - dailyBreakMins;
      int expectedMonthlyMinuts = expectedWorkingDays * expectedNetDailyMins;
      
      final expectedHH = expectedMonthlyMinuts ~/ 60;
      final expectedMM = expectedMonthlyMinuts % 60;
      _expectedTotalHours = '$expectedHH:${expectedMM.toString().padLeft(2, '0')}';

    } catch (e) { /* ignored */ } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  // Get user shift data
  Future<GetShiftMasterData?> _getUserShift(BuildContext context) async {
    try {
      final shiftProvider = Provider.of<ShiftMasterProvider>(context, listen: false);
      List<GetShiftMasterData> getShiftSData = await shiftProvider.getShiftTimintgMasterData();
      
      for (var element in getShiftSData) {
        if (element.positionId == curentUser['PositionId']) {
          return element;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get today's break time
  String getTodayBreakTime(context) {
    try {
      final payrollProvider = Provider.of<PayRollProviders>(context, listen: false);
      DateTime now = DateTime.now();
      
      if (payrollProvider.getAllMonthsBreak.isNotEmpty) {
        String todayDate = DateFormat('dd-MM-yyyy').format(now);
        String lastBreakDate = DateFormat('dd-MM-yyyy').format(
          DateTime.parse(payrollProvider.getAllMonthsBreak.last.attendenceDate.toString())
        );
        
        if (todayDate == lastBreakDate) {
          return '${payrollProvider.getAllMonthsBreak.last.totalOutMinutes.toString()} Min';
        }
      }
      return "00:00";
    } catch (e) {
      return "00:00";
    }
  }

  // Get statistics text
  String getStatisticsText() {
    String userTotal = curentUser['Totalhours']?.toString() ?? '0';
    if (userTotal == '0' || userTotal == '0.0' || userTotal == '0:0' || userTotal == '') {
      userTotal = _expectedTotalHours.isEmpty ? '0' : _expectedTotalHours;
    }
    return '$_totalHour : $_totalMinute / $userTotal';
  }

  @override
  void dispose() {
    stopWorkingHoursTimer();
    super.dispose();
  }

// Add these variables in the HomeProvider class
List<HrmTopListReport>? _setHrmTopRecord;
List<HrmTopListReport>? get setHrmTopRecord => _setHrmTopRecord;

DateTime _leaderboardSelectedMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);
DateTime get leaderboardSelectedMonth => _leaderboardSelectedMonth;

bool _isLeaderboardLoading = false;
bool get isLeaderboardLoading => _isLeaderboardLoading;

String _leaderboardErrorMessage = '';
String get leaderboardErrorMessage => _leaderboardErrorMessage;

// Update your existing getTopLeaderboard method
Future<void> getTopLeaderboard({int? month, int? year}) async {
  _isLeaderboardLoading = true;
  _leaderboardErrorMessage = '';
  notifyListeners();
  
  try {
    final selectedMonth = month ?? _leaderboardSelectedMonth.month;
    final selectedYear = year ?? _leaderboardSelectedMonth.year;
    
    final monthStr = selectedMonth.toString().padLeft(2, '0');
    final yearStr = selectedYear.toString();
    
    await AttendanceApis().getCompanyDataList(monthStr, yearStr).then((value) {
      _setHrmTopRecord = value;
      notifyListeners();
    }).catchError((error) {
      _leaderboardErrorMessage = error.toString();
      _setHrmTopRecord = [];
      notifyListeners();
    });
  } catch (e) {
    _leaderboardErrorMessage = e.toString();
    _setHrmTopRecord = [];
    notifyListeners();
  } finally {
    _isLeaderboardLoading = false;
    notifyListeners();
  }
}

// Change month for leaderboard
Future<void> changeLeaderboardMonth(DateTime newMonth) async {
  if (newMonth.isAfter(DateTime.now())) {
    return; // Cannot go to future months
  }
  
  _leaderboardSelectedMonth = DateTime(newMonth.year, newMonth.month);
  notifyListeners();
  await getTopLeaderboard(
    month: _leaderboardSelectedMonth.month,
    year: _leaderboardSelectedMonth.year,
  );
}

// Previous month
Future<void> previousLeaderboardMonth() async {
  final newMonth = DateTime(
    _leaderboardSelectedMonth.year,
    _leaderboardSelectedMonth.month - 1,
  );
  await changeLeaderboardMonth(newMonth);
}

// Next month
Future<void> nextLeaderboardMonth() async {
  final newMonth = DateTime(
    _leaderboardSelectedMonth.year,
    _leaderboardSelectedMonth.month + 1,
  );
  if (newMonth.isAfter(DateTime.now())) {
    return;
  }
  await changeLeaderboardMonth(newMonth);
}

// Get month name for display
String getLeaderboardMonthName() {
  return DateFormat('MMMM yyyy', LanguageProvider.currentLanguageCode).format(_leaderboardSelectedMonth);
}

// Convert HrmTopListReport to WinnerModel format
List<WinnerModel> convertToWinnerModels(List<HrmTopListReport>? records, int rank) {
  if (records == null || records.isEmpty) return [];
  
  // Filter records by rank
  List<HrmTopListReport> rankedRecords = [];
  
  // Sort by NetWorkingMinutes for proper ranking
  final sortedRecords = List<HrmTopListReport>.from(records);
  sortedRecords.sort((a, b) {
    final minutesA = a.netWorkingMinutes ?? 0;
    final minutesB = b.netWorkingMinutes ?? 0;
    return minutesB.compareTo(minutesA);
  });
  
  // Group by net working hours to handle ties
  Map<String, List<HrmTopListReport>> groupedByHours = {};
  for (var record in sortedRecords) {
    final hoursKey = record.netWorkingHours ?? '0h 0m';
    groupedByHours.putIfAbsent(hoursKey, () => []).add(record);
  }
  
  // Get unique hours in sorted order
  List<String> uniqueHours = groupedByHours.keys.toList();
  uniqueHours.sort((a, b) {
    final minutesA = _convertHoursToMinutes(a);
    final minutesB = _convertHoursToMinutes(b);
    return minutesB.compareTo(minutesA);
  });
  
  // Get records for specific rank
  if (rank <= uniqueHours.length) {
    final targetHours = uniqueHours[rank - 1];
    if (targetHours != null && groupedByHours.containsKey(targetHours)) {
      rankedRecords = groupedByHours[targetHours]!;
    }
  }
  
  // Convert to WinnerModel
  return rankedRecords.map((record) {
    return WinnerModel(
      name: _formatEmployeeName(record.empName ?? ''),
      hours: record.netWorkingHours ?? '0h 0m',
      totaldays: record.totalDays ?? 0,
      avatarUrl: null, // Add avatar URL if available
      rank: rank,
    );
  }).toList();
}

// Helper method to convert hours string to minutes
int _convertHoursToMinutes(String hoursString) {
  if (hoursString.isEmpty) return 0;
  
  int totalMinutes = 0;
  final RegExp regExp = RegExp(r'(\d+)h\s*(\d*)m?');
  final matches = regExp.allMatches(hoursString);
  
  for (final match in matches) {
    final hours = int.parse(match.group(1)!);
    totalMinutes += hours * 60;
    
    if (match.group(2) != null && match.group(2)!.isNotEmpty) {
      final minutes = int.parse(match.group(2)!);
      totalMinutes += minutes;
    }
  }
  
  return totalMinutes;
}

// Format employee name to Title Case
String _formatEmployeeName(String name) {
  return name.toLowerCase().split(' ').map((word) {
    if (word.isNotEmpty) {
      return word[0].toUpperCase() + word.substring(1);
    }
    return word;
  }).join(' ');
}

// Get leaderboard statistics
Map<String, dynamic> getLeaderboardStatistics() {
  if (_setHrmTopRecord == null || _setHrmTopRecord!.isEmpty) {
    return {
      'totalParticipants': 0,
      'averageHours': '0h 0m',
      'topHours': '0h 0m',
    };
  }
  
  final totalParticipants = _setHrmTopRecord!.length;
  
  // Calculate average hours
  int totalMinutes = 0;
  int maxMinutes = 0;
  
  for (var record in _setHrmTopRecord!) {
    final minutes = _convertHoursToMinutes(record.netWorkingHours ?? '0h 0m');
    totalMinutes += minutes;
    if (minutes > maxMinutes) {
      maxMinutes = minutes;
    }
  }
  
  final avgMinutes = totalMinutes ~/ totalParticipants;
  final avgHours = '${avgMinutes ~/ 60}h ${avgMinutes % 60}m';
  final topHours = '${maxMinutes ~/ 60}h ${maxMinutes % 60}m';
  
  return {
    'totalParticipants': totalParticipants,
    'averageHours': avgHours,
    'topHours': topHours,
  };
}

String formatEmployeeName(String name) {
  return name.toLowerCase().split(' ').map((word) {
    if (word.isNotEmpty) {
      return word[0].toUpperCase() + word.substring(1);
    }
    return word;
  }).join(' ');
}


}




