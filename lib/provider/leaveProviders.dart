// ignore_for_file: curly_braces_in_flow_control_structures, strict_top_level_inference, file_names, avoid_function_literals_in_foreach_calls

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/api/leavesapi.dart';
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/customeclass/simpleclass.dart';
import 'package:tax_hrm/api/leaveapi.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/leavetype/applyleave.dart';
import 'package:tax_hrm/models/leavetype/getuserList.dart';
import 'package:tax_hrm/models/leavetype/leavetypes.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/page/leave/applyleavepage.dart';
import 'package:tax_hrm/page/leave/leave_page_design.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class LeaveMastServices extends ChangeNotifier {
  bool islodering = false;
  bool _hasFetchedLeaves = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  leaveHandleSubmit(context,isEdit,{leaveData}) {
    try {
      setloading(true);
      nextScreen(context, ApplyLeavePage(isEdit: isEdit, leaveData: leaveData),onthenValue: (val){},);
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  List<LeaveListData> allLeavesData = [];
  List<LeaveListData> mainallLeavesData = [];
  List<LeaveListData> filterLeaveList = [];
  List<LeaveListData> pandingLeaveRequest = [];
  
  // New lists for upcoming and past leaves
  List<LeaveListData> upcomingLeaves = [];
  List<LeaveListData> pastLeaves = [];

  TextEditingController leaveReasons = TextEditingController();
  TextEditingController creaditDayscontrller = TextEditingController(text: '1');

  LeaveTypes? selectedLeaveType;
  LeaveListData? selectedLeavetoUpdate;
  DateTime? selectedFromDate = DateTime.now();
  DateTime? selectedToDate = DateTime.now();
  TypedClass? selecteHalfDayType = halfdayTypes.first;

  String selectedOption = 'Full Day';
  bool editoptions = false;

  String showGainCounting = '0';
  String showUsedCounting = '0';
  String showEligibleCounting = '0';

  List<LeaveListData> get _currentUserLeaves {
    if (curentUser['Role'] == 'Admin') return mainallLeavesData;
    return mainallLeavesData.where((element) => element.empId == curentUser['Id']).toList();
  }

  double parseLeaveCount(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String formatLeaveCount(double value) {
    return _formatLeaveNumber(value);
  }

  String _formatLeaveNumber(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  // Filter leaves into upcoming and past (based on toDate)
  void filterLeaves() {
    final now = DateTime.now();
    
    // Clear existing lists
    upcomingLeaves.clear();
    pastLeaves.clear();
    
    // Get current user leaves
    List<LeaveListData> userLeaves = curentUser['Role'] == 'Admin' 
        ? mainallLeavesData 
        : mainallLeavesData.where((element) => element.empId == curentUser['Id']).toList();
    
    for (var leave in userLeaves) {
      final toDate = DateTime.tryParse(leave.toDate.toString()) ?? DateTime.now();
      
      // Upcoming leaves: toDate is after today AND (Approved or Pending)
      if (toDate.isAfter(now) && (leave.approveStatus == 'A' || leave.approveStatus == 'P')) {
        upcomingLeaves.add(leave);
      } 
      // Past leaves: toDate is before today OR toDate is today OR (Rejected leaves)
      else {
        pastLeaves.add(leave);
      }
    }
    
    // Sort upcoming leaves by fromDate (nearest first)
    upcomingLeaves.sort((a, b) {
      final dateA = DateTime.tryParse(a.fromDate.toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.fromDate.toString()) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    
    // Sort past leaves by fromDate (newest first)
    pastLeaves.sort((a, b) {
      final dateA = DateTime.tryParse(a.fromDate.toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.fromDate.toString()) ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    notifyListeners();
  }

  // Alternative: Filter based on fromDate
  void filterLeavesByFromDate() {
    final now = DateTime.now();
    
    upcomingLeaves.clear();
    pastLeaves.clear();
    
    List<LeaveListData> userLeaves = curentUser['Role'] == 'Admin' 
        ? mainallLeavesData 
        : mainallLeavesData.where((element) => element.empId == curentUser['Id']).toList();
    
    for (var leave in userLeaves) {
      final fromDate = DateTime.tryParse(leave.fromDate.toString()) ?? DateTime.now();
      
      // Upcoming leaves: fromDate is after today AND (Approved or Pending)
      if (fromDate.isAfter(now) && (leave.approveStatus == 'A' || leave.approveStatus == 'P')) {
        upcomingLeaves.add(leave);
      } 
      else {
        pastLeaves.add(leave);
      }
    }
    
    upcomingLeaves.sort((a, b) {
      final dateA = DateTime.tryParse(a.fromDate.toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.fromDate.toString()) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    
    pastLeaves.sort((a, b) {
      final dateA = DateTime.tryParse(a.fromDate.toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.fromDate.toString()) ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    notifyListeners();
  }

  // Check if a leave is currently active
  bool isLeaveActive(LeaveListData leave) {
    final today = DateTime.now();
    final fromDate = DateTime.tryParse(leave.fromDate.toString()) ?? today;
    final toDate = DateTime.tryParse(leave.toDate.toString()) ?? today;
    
    return fromDate.isBefore(today) && toDate.isAfter(today) && leave.approveStatus == 'A';
  }

  // Get leaves by status
  List<LeaveListData> getLeavesByStatus(String status) {
    return _currentUserLeaves.where((leave) => leave.approveStatus == status).toList();
  }

  // Get upcoming leaves count with different status
  int getUpcomingCountByStatus(String status) {
    final now = DateTime.now();
    return _currentUserLeaves.where((leave) {
      final toDate = DateTime.tryParse(leave.toDate.toString()) ?? now;
      return toDate.isAfter(now) && leave.approveStatus == status;
    }).length;
  }

  // Get past leaves count with different status
  int getPastCountByStatus(String status) {
    final now = DateTime.now();
    return _currentUserLeaves.where((leave) {
      final toDate = DateTime.tryParse(leave.toDate.toString()) ?? now;
      return toDate.isBefore(now) && leave.approveStatus == status;
    }).length;
  }

  int countWeekdays(DateTime startDate, DateTime endDate) {
    int totalDays = 0;
    for (DateTime date = startDate; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
      if (date.weekday != DateTime.sunday) {
        totalDays++;
      }
    }
    return totalDays;
  }

  void resetLeaveForm({bool setLoader = false}) {
    if (editoptions == false) {
      leaveReasons.clear();
      selectedFromDate = DateTime.now();
      selectedToDate = DateTime.now();
      creaditDayscontrller.text = '1';
      selectedLeaveType = null;
      selectedLeavetoUpdate = null;
      selectedOption = 'Half Day';
      selecteHalfDayType = halfdayTypes.first;
      showGainCounting = '0';
      showUsedCounting = '0';
      showEligibleCounting = '0';
      islodering = setLoader;
      notifyListeners();
    }
  }

  void selectLeaveType(LeaveTypes? value, {List<GetHolidayViews> holidays = const []}) {
    selectedLeaveType = value;
    setCountings(
      double.tryParse(creaditDayscontrller.text.trim()) ?? 0,
      selectedFromDate ?? DateTime.now(),
      selectedToDate ?? DateTime.now(),
      holidays: holidays,
    );
    countLeaves();
  }

  void selectFullDay({List<GetHolidayViews> holidays = const []}) {
    selectedOption = 'Full Day';
    setCountings(
      double.tryParse(creaditDayscontrller.text.trim()) ?? 0,
      selectedFromDate ?? DateTime.now(),
      selectedToDate ?? DateTime.now(),
      holidays: holidays,
    );
    notifyListeners();
  }

  void selectHalfDay({List<GetHolidayViews> holidays = const []}) {
    selectedOption = 'Half Day';
    setCountings(
      double.tryParse(creaditDayscontrller.text.trim()) ?? 0,
      selectedFromDate ?? DateTime.now(),
      selectedToDate ?? DateTime.now(),
      holidays: holidays,
    );
    notifyListeners();
  }

  void selectHalfDayType(TypedClass value) {
    selecteHalfDayType = value;
    notifyListeners();
  }

  void updateLeaveDate(DateTime picked, {required bool isFromDate, List<GetHolidayViews> holidays = const []}) {
    if (isFromDate) {
      if (picked.isBefore(selectedToDate!) || _sameDate(picked, selectedToDate!)) {
        selectedFromDate = picked;
      } else {
        selectedFromDate = picked;
        selectedToDate = picked;
      }
    } else {
      if (picked.isAfter(selectedFromDate!) || _sameDate(picked, selectedFromDate!)) {
        selectedToDate = picked;
      } else {
        showtoastmessage('End date cannot be before end StartDate');
      }
    }

    setCountings(
      double.tryParse(creaditDayscontrller.text.trim()) ?? 0,
      selectedFromDate!,
      selectedToDate!,
      holidays: holidays,
    );
    countLeaves();
  }

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month && first.day == second.day;
  }

  void setCountings(double total, DateTime startDate, DateTime endDate, {List<GetHolidayViews> holidays = const []}) {
    if (_sameDate(startDate, endDate)) {
      creaditDayscontrller.text = selectedOption == 'Half Day' ? '0.5' : '1';
      total = double.parse(creaditDayscontrller.text);
    } else {
      final holdDays = countWeekdays(startDate, endDate);
      total = selectedOption == 'Half Day' ? holdDays / 2 : holdDays.toDouble();
      creaditDayscontrller.text = _formatLeaveNumber(total);
    }

    if (selectedLeaveType != null && selectedLeaveType!.considerHoliday == true) {
      final holidayDates = <String>{};
      for (var holiday in holidays) {
        final holidayDate = DateTime.tryParse(holiday.holidayDate ?? '');
        if (holidayDate == null) continue;
        if (!holidayDate.isBefore(startDate) && !holidayDate.isAfter(endDate)) {
          holidayDates.add('${holidayDate.year}-${holidayDate.month}-${holidayDate.day}');
        }
      }
      total -= holidayDates.length;
      creaditDayscontrller.text = _formatLeaveNumber(total);
    }

    if (selectedLeaveType != null && selectedLeaveType!.considerWeeklyOff == true) {
      int sundaysCount = 0;
      for (DateTime date = startDate; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
        if (date.weekday == DateTime.sunday) {
          sundaysCount++;
        }
      }
      total -= sundaysCount;
      creaditDayscontrller.text = _formatLeaveNumber(total);
    }

    notifyListeners();
  }

  double selectedLeaveGainLimit() {
    switch (selectedLeaveType?.leaveLimit) {
      case 'Monthly':
        return parseLeaveCount(selectedLeaveType?.monthly);
      case 'Quarterly':
        return parseLeaveCount(selectedLeaveType?.quarterly);
      case 'HalfYearly':
        return parseLeaveCount(selectedLeaveType?.halfYear);
      case 'Yearly':
        return parseLeaveCount(selectedLeaveType?.yearlyLimit);
      default:
        return 0;
    }
  }

  bool isLeaveInSelectedLimit(DateTime leaveDate) {
    if (selectedFromDate == null || leaveDate.year != selectedFromDate!.year) {
      return false;
    }

    switch (selectedLeaveType?.leaveLimit) {
      case 'Monthly':
        return leaveDate.month == selectedFromDate!.month;
      case 'Quarterly':
        final selectedQuarter = ((selectedFromDate!.month - 1) ~/ 3) + 1;
        final leaveQuarter = ((leaveDate.month - 1) ~/ 3) + 1;
        return selectedQuarter == leaveQuarter;
      case 'HalfYearly':
        final selectedHalf = selectedFromDate!.month <= 6 ? 1 : 2;
        final leaveHalf = leaveDate.month <= 6 ? 1 : 2;
        return selectedHalf == leaveHalf;
      case 'Yearly':
        return true;
      default:
        return false;
    }
  }

  void countLeaves() {
    showGainCounting = '0';
    showUsedCounting = '0';
    showEligibleCounting = '0';

    if (selectedLeaveType != null) {
      final gainLeave = selectedLeaveGainLimit();
      double usedLeave = 0;

      for (var element in mainallLeavesData) {
        if (selectedLeavetoUpdate?.empLeaveId == element.empLeaveId) {
          continue;
        }

        if (element.empId == curentUser['Id'] &&
            element.approveStatus == 'A' &&
            element.leaveTypeId == selectedLeaveType!.leaveTypeId) {
          final leaveDate = DateTime.tryParse(element.fromDate.toString());
          if (leaveDate != null && isLeaveInSelectedLimit(leaveDate)) {
            usedLeave += parseLeaveCount(element.leaveDuration);
          }
        }
      }

      showGainCounting = formatLeaveCount(gainLeave);
      showUsedCounting = formatLeaveCount(usedLeave);
      showEligibleCounting = formatLeaveCount(gainLeave - usedLeave);
    }

    notifyListeners();
  }

  Future<void> submitSelectedLeave() async {
    if (selectedLeaveType == null) {
      showtoastmessage('Select Leave Type');
      return;
    }

    final durationCounts = double.tryParse(creaditDayscontrller.text) ?? 0;
    final allowLeave = double.tryParse(showEligibleCounting) ?? 0;

    if (allowLeave < durationCounts) {
      showtoastmessage('You can not apply leave more than eligible leave');
      return;
    }

    if (editoptions) {
      showtoastmessage('Update leave API not available');
      return;
    }

    final setGuid = generateCustomUuid();
    await applyLeave(
      showToastmessages: true,
      setleaveTypeCguids: selectedLeaveType!.cguid,
      setEmpid: curentUser['Id'],
      setDayTypes: selectedOption == 'Full Day' ? 'Full Day' : selecteHalfDayType!.keys,
      setCguid: setGuid,
      setFromDate: selectedFromDate.toString(),
      setLeaveTypeId: selectedLeaveType!.leaveTypeId,
      setLeaveYears: DateTime.now().year,
      todate: selectedToDate.toString(),
      setLeavedes: durationCounts % 1 == 0 ? durationCounts.toInt() : durationCounts,
      setRemarks: leaveReasons.text,
      setLeavestatuss: 'P',
    );

    editoptions = false;
    resetLeaveForm(setLoader: true);
  }

  Future getUserLeaveLists() async {
    const cacheKey = 'leave_list_cache';
    const ttlMs = 15 * 60 * 1000; // 15 minutes TTL

    // ── Step 1: Show local cache immediately (no clearing, no flicker) ────────
    bool loadedFromCache = false;
    if (mainallLeavesData.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(cacheKey);
        final cachedTs = prefs.getInt('${cacheKey}_ts') ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - cachedTs;
        if (cachedJson != null && age < ttlMs) {
          final List decoded = jsonDecode(cachedJson);
          mainallLeavesData = decoded.map((e) => LeaveListData.fromJson(e)).toList();
          loadedFromCache = true;
          _rebuildLeaveLists();
          notifyListeners();
        }
      } catch (_) {}
      // Only show loader on truly first load (no cached data)
      if (!loadedFromCache && !_hasFetchedLeaves) setloading(true);
    }

    // ── Step 2: Background API refresh ────────────────────────────────────────
    try {
      final freshData = await LeaveApiService().userLeaveList();
      mainallLeavesData = freshData;

      // Persist to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(freshData.map((e) => e.toJson()).toList()));
        await prefs.setInt('${cacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}

      _rebuildLeaveLists();
    } catch (_) {
      // Keep showing cached data on failure
    } finally {
      _hasFetchedLeaves = true;
      setloading(false);
      notifyListeners();
    }
  }

  /// Rebuilds all filtered leave lists from mainallLeavesData.
  void _rebuildLeaveLists() {
    allLeavesData.clear();
    upcomingLeaves.clear();
    pastLeaves.clear();

    if (curentUser['Role'] != 'Admin') {
      for (var element in mainallLeavesData) {
        if (element.empId == curentUser['Id']) {
          allLeavesData.add(element);
        }
      }
    } else {
      pandingLeaveRequest.clear();
      for (var element in mainallLeavesData) {
        if (element.approveStatus == 'P') {
          pandingLeaveRequest.add(element);
        } else {
          allLeavesData.add(element);
        }
      }
    }

    filterLeaves();
    _filterLeavesed();
  }

  Future applyLeave({setEmpid, setFromDate, setLeaveTypeId, setLeaveYears, setLeavedes, setRemarks, setCguid, todate, setLeavestatuss, setDayTypes, setleaveTypeCguids, showToastmessages}) async {
    setloading(true);
    await LeaveApiService().applyLeave(
      setEmployeId: setEmpid,
      leaveTypeCguids: setleaveTypeCguids,
      fromdate: setFromDate,
      leaveTypeid: setLeaveTypeId,
      leaveYears: setLeaveYears,
      leavedec: setLeavedes,
      remarks: setRemarks,
      sendCguid: setCguid,
      todate: todate,
      leaveStatusSet: setLeavestatuss,
      dayTypes: setDayTypes,
    ).then((value) {
      LeaveApply responseData = value as LeaveApply;
      if (responseData.success == true) {
        if (showToastmessages == true) {
          showtoastmessage('Leave Apply successfully');
        }
        getUserLeaveLists();
        notifyListeners();
      }
    });
    setloading(false);
  }

  StatusStyle _getStatusStyle(String? status) {
    switch (status) {
      case 'A': return StatusStyle(text: 'Approved', textColor: Colors.green.shade800, bgColor: Colors.green.shade50, borderColor: Colors.green.shade200, icon: Icons.check_circle, iconColor: Colors.green);
      case 'R': return StatusStyle(text: 'Rejected', textColor: Colors.red.shade800, bgColor: Colors.red.shade50, borderColor: Colors.red.shade200, icon: Icons.cancel, iconColor: Colors.red);
      case 'P': return StatusStyle(text: 'Pending', textColor: Colors.orange.shade800, bgColor: Colors.orange.shade50, borderColor: Colors.orange.shade200, icon: Icons.pending, iconColor: Colors.orange);
      default: return StatusStyle(text: 'Pending', textColor: Colors.grey.shade800, bgColor: Colors.grey.shade50, borderColor: Colors.grey.shade200, icon: Icons.help_outline, iconColor: Colors.grey);
    }
  }

  

  int? _getDaysRemaining(LeaveListData leave) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fromDate = DateTime.tryParse(leave.fromDate.toString()) ?? DateTime.now();
    return (fromDate.isAfter(today) && leave.approveStatus == 'A') ? fromDate.difference(today).inDays : null;
  }

  bool _isTodayLeave(LeaveListData leave) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fromDate = DateTime.tryParse(leave.fromDate.toString()) ?? DateTime.now();
    return leave.approveStatus == 'A' && fromDate.isAtSameMomentAs(today);
  }

  bool _isOngoingLeave(LeaveListData leave) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fromDate = DateTime.tryParse(leave.fromDate.toString()) ?? DateTime.now();
    final toDate = DateTime.tryParse(leave.toDate.toString()) ?? DateTime.now();
    return leave.approveStatus == 'A' && fromDate.isBefore(today) && toDate.isAfter(today);
  }

  Widget buildLeaveList(Size size, List<LeaveListData> leaves, {required bool isUpcoming}) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUpcoming ? Icons.event_available : Icons.history, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(isUpcoming ? "No upcoming leaves" : "No past leaves", style: TextStyle(fontSize: 16, fontFamily: fontInterMediumString, color: ColorConst.leaveTypeColor)),
            SizedBox(height: 8),
            Text(isUpcoming ? "Your upcoming leave requests will appear here" : "Your past leave history will appear here", style: TextStyle(fontSize: 12, fontFamily: fontInterRegularString, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    
    return ListView.separated(
      itemCount: leaves.length,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 80, top: 8),
      separatorBuilder: (context, index) => heightSpacer(size.height * 0.01),
      itemBuilder: (context, index) {
        final leaveData = leaves[index];
        final fromDate = DateTime.tryParse(leaveData.fromDate.toString()) ?? DateTime.now();
        final toDate = DateTime.tryParse(leaveData.toDate.toString()) ?? fromDate;
        final days = _getLeaveDays(leaveData, context);
        final statusStyle = _getStatusStyle(leaveData.approveStatus);
        final daysRemaining = _getDaysRemaining(leaveData);
        final leaveStatus = getLeaveStatusText(leaveData);
        final isOngoing = _isOngoingLeave(leaveData);
        final isToday = _isTodayLeave(leaveData);
        final canEdit = _canEditLeave(leaveData);
        final canDelete = _canDeleteLeave(leaveData);
        final isRejected = _isRejectedLeave(leaveData);
        
        final String fromDateStr = DateFormat('d MMM, EEE').format(fromDate);
        final String toDateStr = DateFormat('d MMM, EEE').format(toDate);
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: size.width * 0.03),
          padding: EdgeInsets.all(size.width * 0.03),
          decoration: BoxDecoration(color: ColorConst.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: ColorConst.grey.withOpacity(0.1), spreadRadius: 0.1, blurRadius: 0.1)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$fromDateStr - $toDateStr', style: TextStyle(fontFamily: fontInterSemiBoldString, color: ColorConst.black, fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: ColorConst.leaveTypeColor),
                            SizedBox(width: 4),
                            Text('${days % 1 == 0 ? days.toInt() : days} Day | ${leaveData.leaveTypeFName ?? leaveString}', style: TextStyle(fontFamily: fontInterMediumString, color: ColorConst.leaveTypeColor, fontSize: 11)),
                          ],
                        ),
                        if (leaveData.remarks != null && leaveData.remarks!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: size.height * 0.008),
                            child: Row(
                              children: [
                                Icon(Icons.message_outlined, size: 12, color: Colors.grey.shade500),
                                SizedBox(width: 4),
                                Expanded(child: Text('Reason: ${leaveData.remarks}', style: TextStyle(fontFamily: fontInterRegularString, color: Colors.grey.shade600, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: size.width * 0.02),
                  Column(
                    children: [
                      Container(
                        width: size.width * 0.28,
                        padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.008),
                        decoration: BoxDecoration(color: statusStyle.bgColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: statusStyle.borderColor, width: 1)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(statusStyle.icon, size: 14, color: statusStyle.iconColor),
                            SizedBox(width: 4),
                            Text(isUpcoming ? leaveStatus : statusStyle.text, style: TextStyle(fontSize: 11, fontFamily: fontInterBoldString, fontWeight: FontWeight.w700, color: statusStyle.textColor)),
                          ],
                        ),
                      ),
                      heightSpacer(size.height * 0.01),
                      Row(
                        children: [
                          if (canEdit) iconBtn(Icons.edit, ColorConst.themeColor, () {
                            nextScreen(context, ApplyLeavePage(isEdit: true, leaveData: leaveData),onthenValue: (val){},);
                          }, height: 25, width: 25, iconSize: 20),
                          SizedBox(width: 4),
                          if (canDelete) iconBtn(Icons.delete, ColorConst.redDarkColors, () {
                            showDeleteDialog(context,size,yesOntap: () {
                              Navigator.pop(context);
                              deleteleave(leaveData.cguid.toString(),context,).then((value) async {
                                await getUserLeaveLists();
                              });
                            },noOnTap: (){Navigator.pop(context);});
                          }, height: 25, width: 25, iconSize: 20),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (isRejected && !canEdit && !canDelete)
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.004),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Cannot modify rejected leave', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: fontInterMediumString)),
                      ],
                    ),
                  ),
                ),
              if (isUpcoming && daysRemaining != null && daysRemaining > 0 && leaveData.approveStatus == 'A')
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.01),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Starting in $daysRemaining day${daysRemaining > 1 ? 's' : ''}', style: TextStyle(fontSize: 11, color: Colors.blue, fontFamily: fontInterMediumString)),
                      ],
                    ),
                  ),
                ),
              if (isUpcoming && isToday)
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.01),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.today, size: 14, color: Colors.purple),
                        SizedBox(width: 4),
                        Text('Starting Today', style: TextStyle(fontSize: 11, color: Colors.purple, fontFamily: fontInterMediumString)),
                      ],
                    ),
                  ),
                ),
              if (isUpcoming && isOngoing)
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.01),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Currently Ongoing', style: TextStyle(fontSize: 11, color: Colors.green, fontFamily: fontInterMediumString)),
                      ],
                    ),
                  ),
                ),
              if (leaveData.approveStatus == 'P')
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.01),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Awaiting approval', style: TextStyle(fontSize: 11, color: Colors.orange, fontFamily: fontInterMediumString)),
                      ],
                    ),
                  ),
                ),
              if (leaveData.approveStatus == 'R' && leaveData.remarks != null && leaveData.remarks!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.01),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Expanded(child: Text('Rejection reason: ${leaveData.remarks}', style: TextStyle(fontSize: 11, color: Colors.red, fontFamily: fontInterMediumString), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  double _getLeaveDays(LeaveListData leaveData, BuildContext context) {
    final leaveMastServices = Provider.of<LeaveMastServices>(context, listen: false);
    return leaveMastServices.parseLeaveCount(leaveData.leaveDuration);
  }

  bool _canEditLeave(LeaveListData leave) => leave.approveStatus == 'P';
  bool _canDeleteLeave(LeaveListData leave) => leave.approveStatus == 'P';
  bool _isRejectedLeave(LeaveListData leave) => leave.approveStatus == 'R';

  bool _isUpcomingLeave(LeaveListData leave) {
    final now = DateTime.now();
    final fromDate = DateTime.tryParse(leave.fromDate.toString()) ?? DateTime.now();
    final toDate = DateTime.tryParse(leave.toDate.toString()) ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (fromDate.isAfter(today)) return true;
    else if (toDate.isAfter(today) && fromDate.isBefore(today)) return true;
    else if (fromDate.isAtSameMomentAs(today)) return true;
    return false;
  }

    
  List<LeaveListData> filteredUpcomingLeaves = [];
  List<LeaveListData> filteredPastLeaves = [];

  void _filterLeavesed() {
    final allLeaves = mainallLeavesData;
    final currentUserLeaves = allLeaves.where((leave) => leave.empId == curentUser['Id']).toList();
    
    filteredUpcomingLeaves = [];
    filteredPastLeaves = [];
    
    for (var leave in currentUserLeaves) {
      if (_isUpcomingLeave(leave)) {
        filteredUpcomingLeaves.add(leave);
      } else {
        filteredPastLeaves.add(leave);
      }
    }
    
    filteredUpcomingLeaves.sort((a, b) {
      final dateA = DateTime.tryParse(a.fromDate.toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.fromDate.toString()) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    
    filteredPastLeaves.sort((a, b) {
      final dateA = DateTime.tryParse(a.fromDate.toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.fromDate.toString()) ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    notifyListeners();
  }

  // Delete Leave
  Future<void> deleteleave(String cguid, BuildContext context) async {
    setloading(true);
    await LeaveMasterApiService().deleteLeave(cguid).then((value) {
      if (value == true) {
        showtoastmessage('Leave deleted successfully');
        getUserLeaveLists();
      }
    });
    setloading(false);
  }
}
