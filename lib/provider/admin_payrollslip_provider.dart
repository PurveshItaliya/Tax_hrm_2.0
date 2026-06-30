// ignore_for_file: empty_catches, use_build_context_synchronously, strict_top_level_inference, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/api/holidayapi.dart';
import 'package:tax_hrm/models/Holidays/month_wizeholiday_set.dart';
import 'package:tax_hrm/models/attendance/monathattendace.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/payrool/getpayrollattendancedata.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/payrollprovider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

import 'package:tax_hrm/utils/attendance_perf_logger.dart';

import '../api/payrollapi.dart';

class AdminPayrollslipProvider extends ChangeNotifier {
  bool islodering = false;
  bool get isloderings => islodering;

  DateTime addPaySummarycurrentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Employeelists? selectedAddEmployeeList;

  double showTotalHoursView = 0;
  int useTotalMinuts = 0;
  String showUserTotalHours = '';
  int totalPresnts = 0;
  double paidLeave = 0;
  double shiftBreakTime = 0;
  int shiftWorkingMinutes = 0;
  double usedlwp = 0;
  double totalBreakMinutes = 0;
  double paidHolidayBreakMinutes = 0;
  int weekOffCount = 0;

  GetShiftMasterData? selectedUserShift;
  List<List<dynamic>> csvData = [];
  List<GetPayRollAttendance> payrollstoreDatalist = [];
  double usetBreaks = 0;

  List<Map<String, dynamic>> attendanceDataList = [];

  void setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  Future<void> loadAddData(BuildContext context) async {
    try {
      setloading(true);
      selectedAddEmployeeList = null;
      resetData();
      final futureEmps = AttendancePerformanceLogger.instance.track(
        'EmployeMastServices.getAllEmployesData',
        () => Provider.of<EmployeMastServices>(context, listen: false).getAllEmployesData(),
        executionMode: 'parallel',
      );
      final futureShifts = AttendancePerformanceLogger.instance.track(
        'ShiftMasterProvider.getShiftTimintgMasterData',
        () => Provider.of<ShiftMasterProvider>(context, listen: false).getShiftTimintgMasterData(),
        executionMode: 'parallel',
      );
      await Future.wait([futureEmps, futureShifts]);
      Provider.of<PayRollProviders>(context, listen: false).getAllMonthsBreak.clear();
      Provider.of<AttendanceEmp>(context, listen: false).getMonthAttenDance.clear();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
  }

  void iconAddOntap(BuildContext context) {
    selectedAddEmployeeList = null;
    resetData();
    notifyListeners();
  }

  void employessAddontap(BuildContext context, Employeelists? value) {
    selectedAddEmployeeList = value;
    if (value == null) {
      resetData();
      notifyListeners();
      return;
    }
    setAndGetData(context);
    notifyListeners();
  }

  Future<void> updateAddMonth(DateTime month, BuildContext context) async {
    addPaySummarycurrentMonth = DateTime(month.year, month.month);
    if (selectedAddEmployeeList != null) {
      await setAndGetData(context);
    }
    notifyListeners();
  }

  void resetData() {
    showTotalHoursView = 0;
    useTotalMinuts = 0;
    showUserTotalHours = '';
    totalPresnts = 0;
    paidLeave = 0;
    shiftBreakTime = 0;
    shiftWorkingMinutes = 0;
    usedlwp = 0;
    totalBreakMinutes = 0;
    paidHolidayBreakMinutes = 0;
    weekOffCount = 0;
    selectedUserShift = null;
    csvData.clear();
    payrollstoreDatalist.clear();
    usetBreaks = 0;
    attendanceDataList.clear();
    notifyListeners();
  }

  Future<void> setAndGetData(BuildContext context) async {
    if (selectedAddEmployeeList == null) return;
    if (!context.mounted) return;

    resetData();
    final month = addPaySummarycurrentMonth.month;
    final year = addPaySummarycurrentMonth.year;
    final lastDateOfMonth = DateTime(year, month + 1, 0);

    _setSelectedUserShift(context);

    final payrollProvider = Provider.of<PayRollProviders>(context, listen: false);
    
    final futureBreaks = AttendancePerformanceLogger.instance.track(
      'PayRollProviders.getMonthsBreaks',
      () => payrollProvider.getMonthsBreaks(
        setEmployeId: selectedAddEmployeeList!.id,
        setMonth: month,
        setYear: year,
      ),
      executionMode: 'parallel',
    );
    
    final futurePayrollData = AttendancePerformanceLogger.instance.track(
      'PayRollProviders.getPayRollData',
      () => payrollProvider.getPayRollData(
        setEmployeId: selectedAddEmployeeList!.id,
        setMonth: month,
        setYear: year,
      ),
      executionMode: 'parallel',
    );

    final futureAttendance = AttendancePerformanceLogger.instance.track(
      'AttendanceApis.getEmpMonathAttendace',
      () => AttendanceApis().getEmpMonathAttendace(
        selectedAddEmployeeList!.id,
        month,
        year,
      ),
      executionMode: 'parallel',
    );
    
    final futureHolidays = _getCurrentMonthHolidays(executionMode: 'parallel');

    final results = await Future.wait([futureBreaks, futurePayrollData, futureAttendance, futureHolidays]);
    
    if (!context.mounted) return;

    final attendanceData = results[2] as List<EmployeAttendance>;
    final holidays = results[3] as List<GetHolidayById>;
    
    Provider.of<AttendanceEmp>(context, listen: false).getMonthAttenDance = attendanceData;

    // Track attendance dates to avoid double counting
    final attendancePresentDates = <String>{};
    final attendanceLeaveDates = <String, String>{};
    
    int attendanceWeekOffCount = 0;
    
    for (final element in attendanceData) {
      final attendanceDate = _parsePayrollDate(element.attendenceDate);
      if (attendanceDate == null) continue;
      final dateKey = _dateKey(attendanceDate);
      
      final leaveGroup = element.leaveGroup?.toString().toLowerCase() ?? '';
      final leaveDuration = _getLeaveDurationInDays(element);
      
      if (element.present == true && element.inTime != null) {
        attendancePresentDates.add(dateKey);
        totalPresnts++;
      }
      
      if (element.absent == true && leaveGroup.isNotEmpty) {
        if (_isPaidLeaveGroup(leaveGroup)) {
          attendanceLeaveDates[dateKey] = 'paid';
          paidLeave += leaveDuration;
          useTotalMinuts += (shiftWorkingMinutes * leaveDuration).toInt();
        } else if (_isUnpaidLeaveGroup(leaveGroup)) {
          attendanceLeaveDates[dateKey] = 'unpaid';
          usedlwp += leaveDuration;
        } else if (leaveGroup == 'weekoff') {
          attendanceWeekOffCount++;
          attendanceLeaveDates[dateKey] = 'weekoff';
        }
      }
      
      if (element.leaveGroup == 'WeekOff') {
        attendanceWeekOffCount++;
      }
      
      final totalMin = int.tryParse(element.totalMinute?.toString() ?? '');
      if (totalMin != null) {
        useTotalMinuts += totalMin;
      }
    }

    // Calculate holiday counts using the already fetched holidays
    _calculateHolidayLeaveCounts(holidays, attendancePresentDates, attendanceLeaveDates);
    _calculateWeekOffCount(attendanceWeekOffCount);
    showUserTotalHours = _formatMinutes(useTotalMinuts);

    await buildAttendanceListForMonth(context, lastDateOfMonth, holidayList: holidays);
    notifyListeners();
  }

  Future<void> buildAttendanceListForMonth(
    BuildContext context,
    DateTime lastDateOfMonth, {
    List<GetHolidayById>? holidayList,
  }) async {
    attendanceDataList.clear();
    csvData.clear();
    totalBreakMinutes = 0;

    final attendanceProvider = Provider.of<AttendanceEmp>(context, listen: false);
    final payrollProvider = Provider.of<PayRollProviders>(context, listen: false);
    final holidays = holidayList ?? await _getCurrentMonthHolidays();

    for (int index = 0; index < lastDateOfMonth.day; index++) {
      final currentDate = DateTime(lastDateOfMonth.year, lastDateOfMonth.month, index + 1);
      String inTime = '';
      String outTime = '';
      String showTotalHours = '';
      String displayInTime = '';
      String displayOutTime = '';
      String displayBreakTime = '';
      String displayTotalHours = '';
      String displayWorkingHours = '';
      String holidayName = '';
      String attendanceHolidayName = '';
      double totalbreaks = 0;
      bool hasAttendance = false;
      final dayCode = DateFormat('EEE').format(currentDate).toLowerCase();
      final isWeekOff = selectedUserShift != null && _isWeekOffDay(dayCode);
      bool isHoliday = false;
      bool isPaidHoliday = false;
      bool isUnpaidHoliday = false;

      // Get break data
      for (final element in payrollProvider.getAllMonthsBreak) {
        final useDate = _parsePayrollDate(element.attendenceDate);
        if (_isSameDate(useDate, currentDate)) {
          totalbreaks = double.tryParse(element.totalOutMinutes?.toString() ?? '') ?? 0;
        }
      }

      // Get attendance data
      for (final element in attendanceProvider.getMonthAttenDance) {
        final useDate = _parsePayrollDate(element.attendenceDate);
        if (!_isSameDate(useDate, currentDate)) continue;

        if (element.inTime != null) {
          try {
            inTime = DateFormat('h:mm a').format(DateTime.parse(element.inTime.toString()));
          } catch (e) {
            inTime = element.inTime.toString();
          }
        }
        if (element.outTime != null) {
          try {
            outTime = DateFormat('h:mm a').format(DateTime.parse(element.outTime.toString()));
          } catch (e) {
            outTime = element.outTime.toString();
          }
        }
        final totalMinute = int.tryParse(element.totalMinute?.toString() ?? '');
        if (totalMinute != null) {
          showTotalHours = _formatMinutes(totalMinute);
        }
        if (element.present == true || element.inTime != null || element.outTime != null) {
          hasAttendance = true;
        }

        final attendanceHoliday = element.holiday?.toString().trim() ?? '';
        if (attendanceHoliday.isNotEmpty && 
            attendanceHoliday.toLowerCase() != 'null' && 
            attendanceHoliday.toLowerCase() != 'false') {
          attendanceHolidayName = attendanceHoliday;
        }

        final leaveGroup = element.leaveGroup?.toString().toLowerCase() ?? '';
        if (element.absent == true && _isPaidLeaveGroup(leaveGroup)) {
          displayInTime = '-';
          displayOutTime = 'PAID LEAVE';
          displayBreakTime = '-';
          displayTotalHours = '-';
          displayWorkingHours = '-';
        } else if (element.absent == true && _isUnpaidLeaveGroup(leaveGroup)) {
          displayInTime = '-';
          displayOutTime = 'UNPAID LEAVE';
          displayBreakTime = '-';
          displayTotalHours = '-';
          displayWorkingHours = '-';
        }
      }

      // Check holiday with proper type detection
      final holiday = _getHolidayForDate(holidays, currentDate);
      if (holiday != null || attendanceHolidayName.isNotEmpty) {
        isHoliday = true;
        holidayName = holiday != null ? _getHolidayDisplayName(holiday) : attendanceHolidayName;
        
        if (holiday != null) {
          final holidayTypeText = _getHolidayTypeText(holiday);
          isPaidHoliday = _isPaidLeaveGroup(holidayTypeText);
          isUnpaidHoliday = _isUnpaidLeaveGroup(holidayTypeText);
          
          if (isPaidHoliday) {
            displayOutTime = holiday.holidayName?.toString() ?? 'PAID HOLIDAY';
            holidayName = displayOutTime;
            displayBreakTime = shiftBreakTime > 0 ? _formatMinutes(shiftBreakTime.toInt()) : '0';
            displayTotalHours = shiftWorkingMinutes > 0 ? _formatMinutes(shiftWorkingMinutes) : '0';
            final paidWorkingMinutes = shiftWorkingMinutes - shiftBreakTime.toInt();
            displayWorkingHours = paidWorkingMinutes > 0 ? _formatMinutes(paidWorkingMinutes) : '0';
            displayInTime = '-';
          } else if (isUnpaidHoliday) {
            displayOutTime = holiday.holidayName?.toString() ?? 'UNPAID HOLIDAY';
            holidayName = displayOutTime;
            displayBreakTime = '-';
            displayTotalHours = '-';
            displayWorkingHours = '-';
            displayInTime = '-';
          } else {
            displayOutTime = holiday.holidayName?.toString() ?? 'HOLIDAY';
            holidayName = displayOutTime;
            displayBreakTime = '-';
            displayTotalHours = '-';
            displayWorkingHours = '-';
            displayInTime = '-';
          }
        } else {
          final attendanceHolidayLower = attendanceHolidayName.toLowerCase();
          if (attendanceHolidayLower.contains('paid')) {
            isPaidHoliday = true;
            displayOutTime = attendanceHolidayName;
            displayBreakTime = shiftBreakTime > 0 ? _formatMinutes(shiftBreakTime.toInt()) : '0';
            displayTotalHours = shiftWorkingMinutes > 0 ? _formatMinutes(shiftWorkingMinutes) : '0';
            final paidWorkingMinutes = shiftWorkingMinutes - shiftBreakTime.toInt();
            displayWorkingHours = paidWorkingMinutes > 0 ? _formatMinutes(paidWorkingMinutes) : '0';
          } else {
            isUnpaidHoliday = true;
            displayOutTime = attendanceHolidayName;
            displayBreakTime = '-';
            displayTotalHours = '-';
            displayWorkingHours = '-';
          }
          displayInTime = '-';
        }
      }

      // Handle week off (only if not already a holiday)
      if (isWeekOff && !isHoliday && displayOutTime.isEmpty) {
        displayInTime = '-';
        displayOutTime = 'Week Off';
        displayBreakTime = '-';
        displayTotalHours = '-';
        displayWorkingHours = '-';
      }

      // Calculate working minutes for regular attendance
      int workingMinutes = 0;
      if (hasAttendance && !isHoliday && !isWeekOff) {
        totalbreaks += shiftBreakTime;
        totalBreakMinutes += totalbreaks;
        
        final totalParts = showTotalHours.split(':');
        if (totalParts.length == 2 && showTotalHours.isNotEmpty && showTotalHours != '-') {
          final hours = int.tryParse(totalParts[0]) ?? 0;
          final minutes = int.tryParse(totalParts[1]) ?? 0;
          workingMinutes = ((hours * 60) + minutes) - totalbreaks.toInt();
          if (workingMinutes < 0) workingMinutes = 0;
        }
      }

      // Set display values
      displayInTime = displayInTime.isEmpty ? (inTime.isEmpty ? '--:--' : inTime) : displayInTime;
      displayOutTime = displayOutTime.isEmpty ? (outTime.isEmpty ? '--:--' : outTime) : displayOutTime;
      displayBreakTime = displayBreakTime.isEmpty ? (totalbreaks > 0 ? _formatMinutes(totalbreaks.toInt()) : '0') : displayBreakTime;
      displayTotalHours = displayTotalHours.isEmpty ? (showTotalHours.isEmpty ? '0' : showTotalHours) : displayTotalHours;
      displayWorkingHours = displayWorkingHours.isEmpty ? (workingMinutes > 0 ? _formatMinutes(workingMinutes) : '0') : displayWorkingHours;

      // Add to CSV
      if (hasAttendance || isHoliday || isWeekOff) {
        String dayType = '';
        if (isHoliday) {
          dayType = isPaidHoliday ? 'PAID HOLIDAY' : (isUnpaidHoliday ? 'UNPAID HOLIDAY' : 'HOLIDAY');
        } else if (isWeekOff) {
          dayType = 'WEEK OFF';
        } else if (displayOutTime.contains('PAID LEAVE')) {
          dayType = 'PAID LEAVE';
        } else if (displayOutTime.contains('UNPAID LEAVE')) {
          dayType = 'UNPAID LEAVE';
        } else {
          dayType = 'PRESENT';
        }
        
        csvData.add([
          index + 1,
          '${selectedAddEmployeeList!.firstName} ${selectedAddEmployeeList!.lastName}',
          '${currentDate.day}-${currentDate.month}-${currentDate.year}',
          displayInTime == '--:--' ? '' : displayInTime,
          displayOutTime,
          displayBreakTime == '0' ? '0' : displayBreakTime,
          displayTotalHours,
          dayType,
        ]);
      }

      attendanceDataList.add({
        'date': currentDate,
        'inTime': displayInTime,
        'outTime': displayOutTime,
        'breakTime': displayBreakTime,
        'totalHours': displayTotalHours,
        'workingHours': displayWorkingHours,
        'holidayName': holidayName,
        'isHoliday': isHoliday,
        'isPaidHoliday': isPaidHoliday,
        'isUnpaidHoliday': isUnpaidHoliday,
      });
    }

    notifyListeners();
  }

  Future<void> updatePayrollData(BuildContext context) async {
    if (selectedAddEmployeeList == null) {
      showtoastmessage('No employee selected');
      return;
    }
    if (!context.mounted) return;

    try {
      setloading(true);
      
      final attendanceProvider = Provider.of<AttendanceEmp>(context, listen: false);
      final payrollProvider = Provider.of<PayRollProviders>(context, listen: false);
      final lastDateOfMonth = DateTime(addPaySummarycurrentMonth.year, addPaySummarycurrentMonth.month + 1, 0);
      payrollstoreDatalist.clear();

      for (var i = 1; i <= lastDateOfMonth.day; i++) {
        final date = DateTime(lastDateOfMonth.year, lastDateOfMonth.month, i);
        final indexs = attendanceProvider.getMonthAttenDance.indexWhere((element) => _isSameDate(_parsePayrollDate(element.attendenceDate), date));
        final setsBreaks = payrollProvider.getAllMonthsBreak.indexWhere((element) => _isSameDate(_parsePayrollDate(element.attendenceDate), date));

        usetBreaks = indexs != -1 ? shiftBreakTime : 0;
        if (indexs != -1 && setsBreaks != -1) {
          final listbreaks = double.tryParse(payrollProvider.getAllMonthsBreak[setsBreaks].totalOutMinutes?.toString() ?? '') ?? 0;
          usetBreaks = listbreaks + shiftBreakTime;
        }

        payrollstoreDatalist.add(GetPayRollAttendance(
          dayType: 'NotLeave',
          entryTime: '',
          flag: '',
          attendenceDate: date.toString(),
          companyId: int.parse('${selectedcurentcompany!.companyId}'),
          cguid: generateCustomUuid(),
          empId: selectedAddEmployeeList!.id,
          inTime: indexs != -1 ? attendanceProvider.getMonthAttenDance[indexs].inTime : null,
          outTime: indexs != -1 ? attendanceProvider.getMonthAttenDance[indexs].outTime : null,
          totalBreak: usetBreaks.toString(),
          totalHours: '0',
        ));
      }

      var response = await PayRollApiSerices().uploadPayrollAttendanceData(payrollData: payrollstoreDatalist);

      if (!context.mounted) return;

      if (response != null && response.success == true) {
        await setAndGetData(context);
        showtoastmessage('Payroll data updated successfully');
      } else {
        showtoastmessage('Failed to update payroll data');
      }
      
    } catch (e) {
      showtoastmessage('Error updating payroll data: ${e.toString()}');
    } finally {
      setloading(false);
    }
  }

  Future<void> deletePayrollData(BuildContext context) async {
    if (selectedAddEmployeeList == null) {
      showtoastmessage('No employee selected');
      return;
    }

    try {
      setloading(true);
      var response = await PayRollApiSerices().deletePayrollAttendance(
        setEmployeId: selectedAddEmployeeList!.id,
        setMonth: addPaySummarycurrentMonth.month,
        setYear: addPaySummarycurrentMonth.year,
      );

      if (response != null) {
        showtoastmessage('Payroll data deleted successfully');
        // Refresh the list after deleting
        await setAndGetData(context);
        // Clear the generated data list so UI updates
        Provider.of<PayRollProviders>(context, listen: false).getPayRollAttendanceData.clear();
        notifyListeners();
      } else {
        showtoastmessage('Failed to delete payroll data');
      }
    } catch (e) {
      showtoastmessage('Error deleting payroll data: ${e.toString()}');
    } finally {
      setloading(false);
    }
  }

  Future<void> downloadAndShareCsv(String title) async {
    if (csvData.isEmpty) {
      showtoastmessage('No data to export');
      return;
    }

    try {
      setloading(true);
      
      // Create CSV content with proper headers
      final exportData = [
        ['Sl No', 'Employee Name', 'Date', 'In Time', 'Out Time', 'Break Time', 'Total Hours', 'Day Type'],
        ...csvData,
      ];
      
      String csvContent = '';
      for (var row in exportData) {
        for (var i = 0; i < row.length; i++) {
          String cellStr = row[i].toString();
          if (cellStr.contains(',') || cellStr.contains('"') || cellStr.contains('\n')) {
            cellStr = cellStr.replaceAll('"', '""');
            cellStr = '"$cellStr"';
          }
          csvContent += cellStr;
          if (i < row.length - 1) csvContent += ',';
        }
        csvContent += '\n';
      }
      
      Directory downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download/TAX HRM 2.0');
      } else if (Platform.isIOS) {
        downloadsDirectory = Directory('${Directory.current.path}/Downloads');
      } else {
        downloadsDirectory = Directory('${Directory.current.path}/Downloads/TAX HRM 2.0');
      }
      
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      int fileIndex = 1;
      String filePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      do {
        filePath = '${downloadsDirectory.path}/$title($fileIndex)_$timestamp.csv';
        fileIndex++;
      } while (await File(filePath).exists());

      final file = File(filePath);
      await file.writeAsString(csvContent, encoding: utf8);
      
      showtoastmessage('CSV Downloaded Successfully');
      
    } catch (e) {
      showtoastmessage('Error downloading CSV: ${e.toString()}');
    } finally {
      setloading(false);
    }
  }

  String listToCsv(List<List<dynamic>> data) {
    return data.map((row) => row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(',')).join('\n');
  }

  String getFormattedTotalHours() => showUserTotalHours.isEmpty ? '00:00' : showUserTotalHours;

  String getTotalBreakTime() => _formatMinutes((totalBreakMinutes + paidHolidayBreakMinutes).toInt());

  String getTotalWorkingHours() {
    final workingMinutes = useTotalMinuts - (totalBreakMinutes + paidHolidayBreakMinutes).toInt();
    return _formatMinutes(workingMinutes < 0 ? 0 : workingMinutes);
  }

  String get formattedPaidLeave => _formatDayCount(paidLeave);

  String get formattedUnpaidLeave => _formatDayCount(usedlwp);

  // ==================== PUNCH ENTRY METHODS ====================

  // Future<List<Map<String, dynamic>>> getPunchEntries(DateTime date, int employeeId) async {
  //   try {
  //     final formattedDate = DateFormat('yyyy-MM-dd').format(date);
  //     final response = await AttendanceApis().getPunchEntries(
  //       employeeId: employeeId,
  //       date: formattedDate,
  //     );
      
  //     if (response != null && response is List) {
  //       return response.map<Map<String, dynamic>>((item) {
  //         return {
  //           'id': item['id']?.toString() ?? '',
  //           'time': _formatTimeString(item['inTime'] ?? item['time'] ?? ''),
  //           'inTime': item['inTime'],
  //           'outTime': item['outTime'],
  //         };
  //       }).toList();
  //     }
  //     return [];
  //   } catch (e) {
  //     return [];
  //   }
  // }

  // Future<bool> addPunchEntry({
  //   required int employeeId,
  //   required DateTime date,
  //   required TimeOfDay inTime,
  //   required TimeOfDay outTime,
  //   required String cguid,
  //   required String attendanceId,
  //   required BuildContext context,
  // }) async {
  //   try {
  //     setloading(true);
      
  //     final inDateTime = DateTime(date.year, date.month, date.day, inTime.hour, inTime.minute);
  //     final outDateTime = DateTime(date.year, date.month, date.day, outTime.hour, outTime.minute);
      
  //     final response = await AttendanceApis().addPunch(
  //       employeeId: employeeId,
  //       date: DateFormat('yyyy-MM-dd').format(date),
  //       inTime: DateFormat('HH:mm:ss').format(inDateTime),
  //       outTime: DateFormat('HH:mm:ss').format(outDateTime),
  //       cguid: cguid,
  //       attendanceId: attendanceId,
  //     );
      
  //     if (response['success'] == true || response['status'] == true) {
  //       await setAndGetData(context);
  //       showtoastmessage('Punch added successfully');
  //       return true;
  //     } else {
  //       showtoastmessage(response['message'] ?? 'Failed to add punch');
  //       return false;
  //     }
  //   } catch (e) {
  //     showtoastmessage('Error: ${e.toString()}');
  //     return false;
  //   } finally {
  //     setloading(false);
  //   }
  // }

  // Future<bool> deletePunchEntry(String punchId, BuildContext context) async {
  //   try {
  //     setloading(true);
  //     final response = await AttendanceApis().deletePunch(punchId);
      
  //     if (response['success'] == true || response['status'] == true) {
  //       await setAndGetData(context);
  //       showtoastmessage('Punch deleted successfully');
  //       return true;
  //     } else {
  //       showtoastmessage(response['message'] ?? 'Failed to delete punch');
  //       return false;
  //     }
  //   } catch (e) {
  //     showtoastmessage('Error: ${e.toString()}');
  //     return false;
  //   } finally {
  //     setloading(false);
  //   }
  // }

  // String _formatTimeString(String? timeString) {
  //   if (timeString == null || timeString.isEmpty) return '';
  //   try {
  //     final time = DateTime.parse(timeString);
  //     return DateFormat('h:mm a').format(time);
  //   } catch (e) {
  //     return timeString;
  //   }
  // }

  // ==================== END OF PUNCH ENTRY METHODS ====================

  void _setSelectedUserShift(BuildContext context) {
    selectedUserShift = null;
    shiftBreakTime = 0;
    shiftWorkingMinutes = 0;

    final shiftList = Provider.of<ShiftMasterProvider>(context, listen: false).mainShiftMasterList;
    for (final element in shiftList) {
      if (element.positionId == selectedAddEmployeeList!.positionId) {
        selectedUserShift = element;
        shiftWorkingMinutes = _getShiftWorkingMinutes(element.shiftDuration);
        if (element.break1 == true && element.break1Duration != null) {
          try {
            final time = DateFormat.Hms().format(DateTime.parse(element.break1Duration.toString()));
            shiftBreakTime += convertTimeToMinutes(time).toDouble();
          } catch (e) { /* ignored */ }
        }
        if (element.break2 == true && element.break2Duration != null) {
          try {
            final time = DateFormat.Hms().format(DateTime.parse(element.break2Duration.toString()));
            shiftBreakTime += convertTimeToMinutes(time).toDouble();
          } catch (e) { /* ignored */ }
        }
        break;
      }
    }
  }

  Future<List<GetHolidayById>> _getCurrentMonthHolidays({String executionMode = 'sequential'}) async {
    try {
      final allHolidays = await AttendancePerformanceLogger.instance.track(
        'HolidayAPIS.getHolidaysByMonthYear',
        () => HolidayAPIS().getHolidaysByMonthYear(
          month: addPaySummarycurrentMonth.month, 
          year: addPaySummarycurrentMonth.year,
        ),
        executionMode: executionMode,
      );
      return allHolidays.where((holiday) {
        return _getHolidayDatesForMonth(holiday).isNotEmpty;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void _calculateHolidayLeaveCounts(
    List<GetHolidayById> holidays,
    Set<String> attendancePresentDates,
    Map<String, String> attendanceLeaveDates,
  ) {
    for (final holiday in holidays) {
      final holidayDates = _getHolidayDatesForMonth(holiday);
      if (holidayDates.isEmpty) continue;

      final holidayTypeText = _getHolidayTypeText(holiday);
      final isPaidHoliday = _isPaidLeaveGroup(holidayTypeText);
      final isUnpaidHoliday = _isUnpaidLeaveGroup(holidayTypeText);
      
      // Skip if holiday type is not recognized as paid or unpaid
      if (!isPaidHoliday && !isUnpaidHoliday) {
        continue;
      }

      final holidayDuration = _getHolidayDurationInDays(holiday);
      int applicableHolidayCount = 0;
      
      for (final holidayDate in holidayDates) {
        final dateKey = _dateKey(holidayDate);
        
        // Skip if employee was present on this day
        if (attendancePresentDates.contains(dateKey)) continue;
        
        // Skip if employee already has a leave on this day
        if (attendanceLeaveDates.containsKey(dateKey)) continue;
        
        // Check if it's a week off
        final dayCode = DateFormat('EEE').format(holidayDate).toLowerCase();
        if (selectedUserShift != null && _isWeekOffDay(dayCode)) continue;
        
        // Check if it's a working day
        if (selectedUserShift != null && !_isWorkingDay(dayCode)) continue;
        
        applicableHolidayCount++;
      }

      final totalHolidayDays = applicableHolidayCount * holidayDuration;
      if (totalHolidayDays <= 0) continue;

      if (isPaidHoliday) {
        paidLeave += totalHolidayDays;
        useTotalMinuts += (shiftWorkingMinutes * totalHolidayDays).toInt();
        paidHolidayBreakMinutes += (shiftBreakTime * totalHolidayDays);
      } else if (isUnpaidHoliday) {
        usedlwp += totalHolidayDays;
      }
    }
  }

  double _getLeaveDurationInDays(dynamic attendance) {
    final leaveDuration = attendance.leaveDuration?.toString().toLowerCase() ?? '';
    final duration = double.tryParse(leaveDuration);
    if (duration != null) return duration;
    if (_isHalfDayText(leaveDuration)) return 0.5;

    final dayType = attendance.dayType?.toString().toLowerCase() ?? '';
    if (_isHalfDayText(dayType)) return 0.5;

    final leaveTypeName = attendance.leaveTypeFName?.toString().toLowerCase() ?? '';
    if (_isHalfDayText(leaveTypeName)) return 0.5;

    return 1.0;
  }

  bool _isHalfDayText(String value) {
    return value.contains('half') || value.contains('first half') || value.contains('second half');
  }

  bool _isPaidLeaveGroup(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (_isUnpaidLeaveGroup(normalized)) return false;
    
    const paidKeywords = [
      'paid', 'pl', 'payable', 'salary', 'wage',
      'national holiday', 'festival holiday', 'government holiday',
      'earned leave', 'casual leave', 'sick leave', 'annual leave',
      'public holiday', 'bank holiday', 'compensatory off'
    ];
    
    return paidKeywords.any((keyword) => normalized.contains(keyword));
  }

  bool _isUnpaidLeaveGroup(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    
    const unpaidKeywords = [
      'unpaid', 'un paid', 'lwp', 'loss of pay', 
      'leave without pay', 'without pay', 'no pay',
      'unpaid holiday', 'un paid holiday', 'unpaid leave'
    ];
    
    return unpaidKeywords.any((keyword) => normalized.contains(keyword));
  }

  String _getHolidayTypeText(dynamic holiday) {
    // Check holidayType first
    String holidayType = holiday.holidayType?.toString().trim().toLowerCase() ?? '';
    if (holidayType.isNotEmpty && holidayType != 'null') {
      if (_isPaidLeaveGroup(holidayType)) return 'paid';
      if (_isUnpaidLeaveGroup(holidayType)) return 'unpaid';
    }
    
    // Check holidayGroup
    String holidayGroup = holiday.holidayGroup?.toString().trim().toLowerCase() ?? '';
    if (holidayGroup.isNotEmpty && holidayGroup != 'null') {
      if (_isPaidLeaveGroup(holidayGroup)) return 'paid';
      if (_isUnpaidLeaveGroup(holidayGroup)) return 'unpaid';
    }
    
    // Check description
    String description = holiday.description?.toString().trim().toLowerCase() ?? '';
    if (description.isNotEmpty && description != 'null') {
      if (_isPaidLeaveGroup(description)) return 'paid';
      if (_isUnpaidLeaveGroup(description)) return 'unpaid';
    }
    
    // Check holidayName
    String holidayName = holiday.holidayName?.toString().trim().toLowerCase() ?? '';
    if (holidayName.isNotEmpty && holidayName != 'null') {
      if (_isPaidLeaveGroup(holidayName)) return 'paid';
      if (_isUnpaidLeaveGroup(holidayName)) return 'unpaid';
    }
    
    return '';
  }

  int _getShiftWorkingMinutes(dynamic shiftDuration) {
    final value = shiftDuration?.toString().trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') return 0;

    try {
      final dateTime = DateFormat("dd/MM/yyyy HH:mm:ss").parse(value);
      return (dateTime.hour * 60) + dateTime.minute;
    } catch (_) { /* ignored */ }

    final dateTime = DateTime.tryParse(value);
    if (dateTime != null) return (dateTime.hour * 60) + dateTime.minute;

    final parts = value.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return (hours * 60) + minutes;
    }

    return 0;
  }

  // FIXED: This method now correctly uses holiday.enddate
  List<DateTime> _getHolidayDatesForMonth(dynamic holiday) {
    final startDate = _parsePayrollDate(holiday.holidayDate);
    if (startDate == null) {
      return [];
    }

    // FIXED: Use holiday.enddate instead of holiday.holidayDate
    final endDate = _parsePayrollDate(holiday.enddate) ?? startDate;
    final currentMonthStart = DateTime(addPaySummarycurrentMonth.year, addPaySummarycurrentMonth.month, 1);
    final currentMonthEnd = DateTime(addPaySummarycurrentMonth.year, addPaySummarycurrentMonth.month + 1, 0);

    final dates = <DateTime>[];
    for (var date = startDate; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
      if (!date.isBefore(currentMonthStart) && !date.isAfter(currentMonthEnd)) {
        dates.add(date);
      }
    }
    
    return dates;
  }

  bool _isHolidayOnDate(dynamic holiday, DateTime currentDate) {
    return _getHolidayDatesForMonth(holiday).any((date) => _isSameDate(date, currentDate));
  }

  GetHolidayById? _getHolidayForDate(List<GetHolidayById> holidays, DateTime currentDate) {
    for (final holiday in holidays) {
      if (_isHolidayOnDate(holiday, currentDate)) return holiday;
    }
    return null;
  }

  DateTime? _parsePayrollDate(dynamic value) {
    final rawDate = value?.toString().trim() ?? '';
    if (rawDate.isEmpty || rawDate.toLowerCase() == 'null') return null;

    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate != null) return parsedDate;

    const formats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'dd-MM-yyyy', 'MM-dd-yyyy', 'yyyy-MM-dd'];
    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(rawDate);
      } catch (_) { /* ignored */ }
    }
    return null;
  }

  double _getHolidayDurationInDays(dynamic holiday) {
    final holidayTexts = [
      holiday.holidayType,
      holiday.holidayName,
      holiday.holidayGroup,
      holiday.description,
    ].map((value) => value?.toString().toLowerCase() ?? '');

    if (holidayTexts.any(_isHalfDayText)) return 0.5;
    return 1.0;
  }

  String _getHolidayDisplayName(dynamic holiday) {
    final holidayName = holiday.holidayName?.toString().trim() ?? '';
    if (holidayName.isNotEmpty && holidayName.toLowerCase() != 'null') return holidayName;

    final holidayType = holiday.holidayType?.toString().trim() ?? '';
    if (holidayType.isNotEmpty && holidayType.toLowerCase() != 'null') return holidayType;

    return 'Holiday';
  }

  void _calculateWeekOffCount(int attendanceWeekOffCount) {
    weekOffCount = 0;
    if (selectedUserShift == null) {
      weekOffCount = attendanceWeekOffCount;
      return;
    }

    final lastDateOfMonth = DateTime(addPaySummarycurrentMonth.year, addPaySummarycurrentMonth.month + 1, 0);
    for (var day = 1; day <= lastDateOfMonth.day; day++) {
      final dayCode = DateFormat('EEE').format(DateTime(addPaySummarycurrentMonth.year, addPaySummarycurrentMonth.month, day)).toLowerCase();
      if (_isWeekOffDay(dayCode)) weekOffCount++;
    }
  }

  bool _isWeekOffDay(String dayCode) {
    if (selectedUserShift == null) return false;
    switch (dayCode) {
      case 'sun':
        return selectedUserShift!.sun == false;
      case 'mon':
        return selectedUserShift!.mon == false;
      case 'tue':
        return selectedUserShift!.tue == false;
      case 'wed':
        return selectedUserShift!.wed == false;
      case 'thu':
        return selectedUserShift!.thu == false;
      case 'fri':
        return selectedUserShift!.fri == false;
      case 'sat':
        return selectedUserShift!.sat == false;
      default:
        return false;
    }
  }

  bool _isWorkingDay(String dayCode) {
    if (selectedUserShift == null) return true;
    switch (dayCode) {
      case 'sun':
        return selectedUserShift!.sun == true;
      case 'mon':
        return selectedUserShift!.mon == true;
      case 'tue':
        return selectedUserShift!.tue == true;
      case 'wed':
        return selectedUserShift!.wed == true;
      case 'thu':
        return selectedUserShift!.thu == true;
      case 'fri':
        return selectedUserShift!.fri == true;
      case 'sat':
        return selectedUserShift!.sat == true;
      default:
        return true;
    }
  }

  bool _isSameDate(DateTime? first, DateTime second) {
    return first != null && first.day == second.day && first.month == second.month && first.year == second.year;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDayCount(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}