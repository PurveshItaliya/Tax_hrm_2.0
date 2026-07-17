// ignore_for_file: strict_top_level_inference

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/attendanceadmin.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/models/attendance/allemployeattendance.dart';
import 'package:tax_hrm/models/attendance/attendancelogdelet.dart';
import 'package:tax_hrm/models/attendance/attendancelogupdate.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/provider/leaveProviders.dart';
import 'package:tax_hrm/provider/leavemployeeprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAttenDanceServices extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  DateTime currentMonth = DateTime.now();
  EventController eventController = EventController();

  Future<void> updateMonth(DateTime newDate, BuildContext context) async {
    try {
      setloading(true);
      currentMonth = newDate;
      await toDayDateAttendance(currentMonth);
    } catch (e) { /* ignored */ } finally {
      setloading(false);
      notifyListeners();
    }
  }

  static final Map<String, List<AllEmployeAttendance>> _attendanceCache = {};

  bool _areAttendanceListsEqual(List<AllEmployeAttendance> a, List<AllEmployeAttendance> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].empId != b[i].empId ||
          a[i].present != b[i].present ||
          a[i].isOnLeave != b[i].isOnLeave ||
          a[i].inTime != b[i].inTime ||
          a[i].outTime != b[i].outTime) {
        return false;
      }
    }
    return true;
  }

  List<AllEmployeAttendance> mainHoldEmpList = [];
  List<AllEmployeAttendance> empAttendanceList = [];

  void setEmpAttendanceList(List<AllEmployeAttendance> list) {
    empAttendanceList = list;
    notifyListeners();
  }

  Future<void> toDayDateAttendance(setDate, {bool isBackground = false}) async {
    try {
      DateTime inputDatetime;
      if (setDate is DateTime) {
        inputDatetime = setDate;
      } else {
        if (setDate == null || setDate.toString().isEmpty) {
          inputDatetime = DateTime.now();
        } else {
          try {
            inputDatetime = DateTime.parse(setDate.toString());
          } catch (e) {
            inputDatetime = DateTime.now();
          }
        }
      }
      
      DateTime dateOnly = DateTime(inputDatetime.year, inputDatetime.month, inputDatetime.day);
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateOnly);
      
      bool loadedFromCache = false;
      // 1. Try in-memory cache first
      if (!isBackground && _attendanceCache.containsKey(formattedDate)) {
        final cached = _attendanceCache[formattedDate]!;
        mainHoldEmpList = List.from(cached);
        empAttendanceList = List.from(cached);
        loadedFromCache = true;
        setCounters(notify: false);
        setloading(false);
        notifyListeners();
      } 
      // 2. Try SharedPreferences cache
      else if (!isBackground && mainHoldEmpList.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final localKey = 'admin_attendance_cache_$formattedDate';
          if (prefs.containsKey(localKey)) {
            final cachedStr = prefs.getString(localKey);
            if (cachedStr != null && cachedStr.isNotEmpty) {
              final cachedList = allEmployeAttendanceFromJson(cachedStr);
              mainHoldEmpList = List.from(cachedList);
              empAttendanceList = List.from(cachedList);
              _attendanceCache[formattedDate] = cachedList;
              loadedFromCache = true;
              setCounters(notify: false);
              setloading(false);
              notifyListeners();
            }
          }
        } catch (e) {
          // ignore cache read error
        }
      }
      
      final bool showLoader = !isBackground && !loadedFromCache;
      if (showLoader) {
        setloading(true);
      }
      
      final response = await AdminAttenDanceApis().getDateAttendance(formattedDate);
      
      if (response != null) {
        final bool isChanged = !_areAttendanceListsEqual(mainHoldEmpList, response);
        _attendanceCache[formattedDate] = response;
        
        // Save to SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          final localKey = 'admin_attendance_cache_$formattedDate';
          await prefs.setString(localKey, allEmployeAttendanceToJson(response));
        } catch (e) {
          // ignore cache write error
        }

        if (isChanged) {
          mainHoldEmpList = response;
          empAttendanceList = response;
          setCounters(notify: false);
          notifyListeners();
        }
      } else {
        if (mainHoldEmpList.isNotEmpty) {
          mainHoldEmpList = [];
          empAttendanceList = [];
          _attendanceCache[formattedDate] = [];
          setCounters(notify: false);
          notifyListeners();
        }
      }
    } catch (e) {
      if (!isBackground) {
        mainHoldEmpList = [];
        empAttendanceList = [];
        setCounters(notify: false);
        notifyListeners();
      }
    } finally {
      setloading(false);
    }
  }


  int totalPresents = 0;
  int totalAbsent = 0;
  int totalIsOnLeave = 0;

  setCounters({bool notify = true}) {
    totalPresents = 0;
    totalAbsent = 0;
    totalIsOnLeave = 0;
    
    for (var element in mainHoldEmpList) {
      // Count Present
      if (element.present == true) {
        totalPresents++;
      }
      
      // Count On Leave
      if (element.isOnLeave == true && element.leaveCguid != null) {
        totalIsOnLeave++;
      }
      
      // Count Absent (not present and not on leave)
      if ((element.present == false || element.present == null) && 
          (element.isOnLeave == false || element.isOnLeave == null)) {
        totalAbsent++;
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> changeDate(bool isNext) async {
    try {
      setloading(true);
      
      if (isNext) {
        // Move to next month
        currentMonth = DateTime(currentMonth.year, currentMonth.month, currentMonth.day + 1);
      } else {
        // Move to previous month
        currentMonth = DateTime(currentMonth.year, currentMonth.month, currentMonth.day - 1);
      }
      
      // Fetch data for the new month
      await toDayDateAttendance(currentMonth);
      
    } catch (e) { /* ignored */ } finally {
      setloading(false);
      notifyListeners();
    }
  }

  bool isTodayOrFuture(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final compareDate = DateTime(date.year, date.month, 1);
    return compareDate.isAtSameMomentAs(today) || compareDate.isAfter(today);
  }

  List<AllEmployeAttendance> filtersList = [];

  filterIsONleave() {
    setloading(true);
    try {
      filtersList.clear();
      for (var element in mainHoldEmpList) { 
        if(element.isOnLeave == true){
          filtersList.add(element);
        }
      }
      empAttendanceList = filtersList;
    } catch (e) { /* ignored */ } finally {
      setloading(false);
      notifyListeners();
    }
  }

  filtersOntapData(bool presentmood) {
    setloading(true);
    try {
      filtersList.clear();

      if(presentmood == true) {
        for (var element in mainHoldEmpList) { 
          if(element.present == true){
            filtersList.add(element);
          }
        }
        empAttendanceList = filtersList;
      } else {
        for (var element in mainHoldEmpList) { 
          if(element.absent == null || element.absent == true && element.isOnLeave != true){
            filtersList.add(element);
          }
        }
        empAttendanceList = filtersList;
      }
    } catch (e) { /* ignored */ } finally {
      setloading(false);
      notifyListeners();
    }
  }

  TextEditingController punchInTimeController = TextEditingController();
  TextEditingController punchOutTimeController = TextEditingController();

  TextEditingController remarkController = TextEditingController();
  TimeOfDay? selectedPunchInTime;
  TimeOfDay? selectedPunchOutTime;

  // Dialog state management
  DateTime dialogIntimeDateTime = DateTime.now();
  DateTime dialogOuttimeDateTime = DateTime.now();
  TextEditingController dialogNotesController = TextEditingController();

  void setDialogIntimeDateTime(DateTime value) {
    dialogIntimeDateTime = value;
    notifyListeners();
  }

  void setDialogOuttimeDateTime(DateTime value) {
    dialogOuttimeDateTime = value;
    notifyListeners();
  }

  void setDialogNotes(String value) {
    dialogNotesController.text = value;
    notifyListeners();
  }

  // Helper method to show time picker dialog
  Future<bool> showTimePickerDialog({
    required BuildContext context,
    required String title,
    required bool isPunchIn,
    required dynamic attendanceProviders,
    required int empId,
    int? attendanceId,
    required DateTime currentMonth,
  }) async {
    TimeOfDay? selectedTime = TimeOfDay.now();
    TextEditingController remarkController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorConst.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with Gradient
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ColorConst.themeColor, ColorConst.themeColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.access_time_filled,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Time Picker Card
                          GestureDetector(
                            onTap: () async {
                              final TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime!,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        backgroundColor: ColorConst.white,
                                        hourMinuteTextColor: ColorConst.themeColor,
                                        dialHandColor: ColorConst.themeColor,
                                        dialBackgroundColor: ColorConst.themeColor.withOpacity(0.1),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setDialogState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [ColorConst.themeColor.withOpacity(0.05), Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: ColorConst.themeColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: ColorConst.themeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.schedule,
                                          color: ColorConst.themeColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Select Time',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            selectedTime!.format(context),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConst.themeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorConst.themeColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: ColorConst.themeColor,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Remark Field
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: remarkController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add a remark...',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                prefixIcon: Icon(Icons.comment_outlined, color: Colors.grey.shade500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: ColorConst.themeColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: ColorConst.themeColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final formattedTime = _formatTimeWithAmPm(selectedTime!, context);
                                if (isPunchIn) {
                                  attendanceProviders.punchInTimeController.text = formattedTime;
                                  attendanceProviders.addEmpattendance(
                                    weekoff: currentMonth.weekday == DateTime.sunday,
                                    setEmployeId: empId,
                                    attendanceDateEmp: currentMonth.toString(),
                                    attendanceTime: formattedTime,
                                    usedRemarks: remarkController.text,
                                  );
                                } else {
                                  attendanceProviders.punchOutTimeController.text = formattedTime;
                                  attendanceProviders.updatePunchOut(
                                    attendanceDate: DateTime(currentMonth.year, currentMonth.month, currentMonth.day).toString(),
                                    setEmpid: empId,
                                    setattendanceid: attendanceId,
                                    setOutTime: formattedTime,
                                  );
                                }
                                Navigator.pop(context, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConst.themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
          },
        );
      },
    );
    
    return result ?? false;
  }

  // Helper method to format time
  String _formatTimeWithAmPm(TimeOfDay time, BuildContext context) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  Future<void> refreshCurrentMonthData(BuildContext context) async {
    // This will refresh data for the current selected month without changing the date
    await updateMonth(currentMonth, context);
  }

  Future addEmpattendance({attendanceDateEmp, attendanceTime, setEmployeId, usedRemarks, weekoff}) async {
    String setGuid = generateCustomUuid();
    try {
      await AttendanceApis().attendanceAddAdmin(
        setweekoff: weekoff,
        setRemarks: usedRemarks,
        attendanceDate: attendanceDateEmp,
        setInTime: attendanceTime,
        setEmpid: setEmployeId,
        setCguid: setGuid
      ).then((value) {
        toDayDateAttendance(attendanceDateEmp);
      });
    } catch (e) { /* ignored */ }
  }

  updatePunchOut({setattendanceid, setInTime, setOutTime, setEmpid, attendanceDate, updateInMood}) async {
    String setGuidsss = generateCustomUuid();
    try {
      await AttendanceApis().attenDanceUpdate(
        attendanceid: setattendanceid,
        setOutTime: setOutTime,
        setEmpid: setEmpid,
        attendanceDate: attendanceDate,
        updateInMood: updateInMood,
        setCguid: setGuidsss
      ).then((value) {
        toDayDateAttendance(attendanceDate);
      });
    } catch (e) { /* ignored */ }
  }

  //-----------------------   Update Log --------------------------- \\
  Future updateLogsData({setattendanceGuid, setattendanceid, setattendanceTime, setattendancedate, setempids, setlogCjuid, setlogStatus, setlogid, setremarks, context}) async {
    try {
      await AttendanceApis().updatelogs(
        attendanceGuid: setattendanceGuid,
        attendanceid: setattendanceid,
        attendanceTime: setattendanceTime,
        attendancedate: setattendancedate,
        empids: setempids,
        logCjuid: setlogCjuid,
        logStatus: setlogStatus,
        logid: setlogid,
        remarks: setremarks
      ).then((value) {
        AttendanceLogUpdate setresponse = value as AttendanceLogUpdate;

        if(setresponse.success == true) {
          toDayDateAttendance(setattendancedate);
          Navigator.pop(context);
          Navigator.pop(context);
        }
      });
    } catch (e) { /* ignored */ }
    notifyListeners();
  }

  //========================  Delete Log ===============================\\
  Future deletePunchlog({attendanceId, setEmpid, setLogId, setStatus}) async {
    try {
      await AttendanceApis().deleteAttendanceLog(
        attendanceId: attendanceId,
        setEmpid: setEmpid,
        setLogId: setLogId,
        setStatus: setStatus
      ).then((value) {
        AttendanceLogDelete setResponse = value as AttendanceLogDelete;
        if(setResponse.success == true) {
          // Success, no action needed
        }
      });
    } catch (e) { /* ignored */ }
    notifyListeners();
  }

  GetLeaveMaster? selectedLeaveTypes;
  bool selectedPresent = false;

  void setPresentSelection(bool value) {
    selectedPresent = value;
    if (value) {
      selectedLeaveTypes = null;
    }
    notifyListeners();
  }

  void toggleLeaveType(GetLeaveMaster item) {
    selectedPresent = false;
    if (selectedLeaveTypes?.leaveTypeId == item.leaveTypeId) {
      selectedLeaveTypes = null;
    } else {
      selectedLeaveTypes = item;
    }
    notifyListeners();
  }

  Future leaveEditTypeSet(context, AllEmployeAttendance selectedEmp) async {
    selectedPresent = selectedEmp.present != null ? selectedEmp.present! : false;
    selectedLeaveTypes = null;
    try {
      await Provider.of<LeaveEmployeeeMastServices>(context, listen: false).getAdminLeaveData().then((value) {
        if(selectedEmp.leaveCguid != null) {
          Provider.of<LeaveEmployeeeMastServices>(context, listen: false).getAllleaveTypesList.forEach((element) {
            if(selectedEmp.leaveTypeCguid == element.cguid) {
              selectedLeaveTypes = element;
            }
          });
        }
      });
    } catch (e) { /* ignored */ }
    notifyListeners();
  }

  Future applyLeaveData(context, AllEmployeAttendance selectedEmp) async {
    if(selectedLeaveTypes != null) {
      String setGuid = generateCustomUuid();
      try {
        await Provider.of<LeaveMastServices>(context, listen: false).applyLeave(
          setleaveTypeCguids: selectedLeaveTypes!.cguid,
          setEmpid: selectedEmp.empId,
          setDayTypes: 'Full Day',
          setCguid: setGuid,
          setFromDate: selectedEmp.attendenceDate.toString(),
          setLeaveTypeId: selectedLeaveTypes!.leaveTypeId,
          setLeaveYears: DateTime.now().year,
          todate: selectedEmp.attendenceDate.toString(),
          setLeavedes: 1,
          setRemarks: '',
          showToastmessages: false,
          setLeavestatuss: 'A'
        ).then((value) {
          Navigator.pop(context);
          leaveEditTypeSet(context, selectedEmp);
          toDayDateAttendance(currentMonth);
        });
      } catch (e) { /* ignored */ }
      notifyListeners();
    }
  }

  Future setAbsentEmployes({attendanceDate, attedanceid, setEmpid, context, setattendanceCguid}) async {
    try {
      await AttendanceApis().absentEmploye(
        attendanceDate: attendanceDate,
        setEmpid: setEmpid,
        attendanceCguid: setattendanceCguid
      ).then((value) {
        Navigator.pop(context);
        setCounters();
        toDayDateAttendance(attendanceDate);
      });
    } catch (e) { /* ignored */ }
  }
}