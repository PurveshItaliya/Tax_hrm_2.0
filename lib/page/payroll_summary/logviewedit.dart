// ignore_for_file: use_build_context_synchronously


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

// Main Add Punch Dialog
Future<bool?> showAddPunchDialog(BuildContext context, Size size, DateTime currentDate, String setCguid, String setAttendanceIds, employeeId) async {
  final dateTitle = DateFormat('dd/MM/yyyy').format(currentDate);
  final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
  
  bool isInitialized = false;
  bool hasCommittedChanges = false;
  List<dynamic> localLogs = [];
  int? attendanceId;
  String attendanceCguid = setCguid;
  Set<dynamic> editedLogs = {};
  Set<dynamic> deletedLogs = {};

  // Fetch punch logs when dialog opens
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Provider.of<AttendanceEmp>(context, listen: false).getDateBloges(formattedDate, employeeId);
  });
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: size.width * 0.9,
              constraints: BoxConstraints(
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(size, context, () => Navigator.pop(context, hasCommittedChanges)),
                  Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Column(
                      children: [
                        _buildDateSection(size, dateTitle),
                        SizedBox(height: size.height * 0.01),
                        // Inside your build method where you want to show the punch list
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: ColorConst.textBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: [
                                // Table Header
                                _buildTableHeader(size),
                                
                                // List of punch rows
                                SizedBox(
                                  height: size.height * 0.3,
                                  child: Consumer<AttendanceEmp>(
                                    builder: (context, attendanceEmp, child) {
                                      if (attendanceEmp.isloderings) {
                                        return const Center(child: CircularProgressIndicator());
                                      }

                                      if (!isInitialized) {
                                        localLogs = List.from(attendanceEmp.selectedDateLog?.attendenceLog ?? []);
                                        attendanceId = attendanceEmp.selectedDateLog?.attendence?.attendenceID;
                                        if (attendanceEmp.selectedDateLog?.attendence?.cguid != null) {
                                          attendanceCguid = attendanceEmp.selectedDateLog!.attendence!.cguid.toString();
                                        }
                                        isInitialized = true;
                                      }

                                      if (localLogs.isEmpty) {
                                        return Center(
                                          child: Text(
                                            noPunchesFoundForThisDateString,
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: localLogs.length,
                                        itemBuilder: (context, index) {
                                          final log = localLogs[index];
                                          if (deletedLogs.contains(log)) return const SizedBox.shrink();

                                          String timeStr = '';
                                          if (log.time != null) {
                                            try {
                                              timeStr = DateFormat('hh:mm a').format(DateTime.parse(log.time.toString()));
                                            } catch (e) {
                                              try {
                                                timeStr = DateFormat('hh:mm a').format(DateFormat("HH:mm").parse(log.time.toString().replaceAll("T", "")));
                                              } catch (e2) {
                                                timeStr = log.time.toString();
                                              }
                                            }
                                          }
                                          final isIn = log.status == 'IN';
                                          final isOut = log.status == 'OUT';

                                          return _buildPunchRow(
                                            size: size, 
                                            time: timeStr, 
                                            isInChecked: isIn, 
                                            isOutChecked: isOut, 
                                            isDeleted: false, 
                                            context: context, 
                                            log: log, 
                                            attendanceId: attendanceId,
                                            currentDate: currentDate,
                                            onUpdateLog: (newTime) {
                                              setState(() {
                                                try {
                                                  final parsedTime = DateFormat('h:mm a').parse(newTime);
                                                  final dateObj = DateTime(currentDate.year, currentDate.month, currentDate.day, parsedTime.hour, parsedTime.minute);
                                                  log.time = dateObj.toString();
                                                } catch (e) {
                                                  log.time = newTime;
                                                }
                                                editedLogs.add(log);
                                              });
                                            },
                                            onUpdateStatus: (newStatus) {
                                              setState(() {
                                                log.status = newStatus;
                                                editedLogs.add(log);
                                              });
                                            },
                                            onDelete: () {
                                              setState(() {
                                                deletedLogs.add(log);
                                              });
                                            }
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        _buildAddTimeButton(size, context, currentDate, employeeId, attendanceCguid, () {
                           setState(() {
                             isInitialized = false;
                             hasCommittedChanges = true;
                           });
                        }),
                        SizedBox(height: size.height * 0.02),
                        _buildActionButtons(context, size, employeeId, attendanceCguid, attendanceId, formattedDate, localLogs, editedLogs, deletedLogs, () => Navigator.pop(context, hasCommittedChanges)),
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
}

// Add Time Dialog - Fixed Version
Future<dynamic> showAddTimeDialog(BuildContext context, Size size, {String? existingTime}) async {
  TimeOfDay selectedTime = existingTime != null 
      ? _parseTimeString(existingTime) 
      : TimeOfDay.now();
  
  // Track selected type (Check In or Check Out)
  
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: size.width * 0.9,
              constraints: BoxConstraints(
                maxWidth: 400,
              ),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorConst.themeColor,
                          ColorConst.themeColor.withOpacity(0.7),
                        ],
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
                          padding: EdgeInsets.all(size.width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: size.width * 0.05,
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                existingTime == null ? addTimeString : editTimeString,
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                selectPunchTimeAndTypeString,
                                style: TextStyle(
                                  fontSize: size.width * 0.025,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(size.width * 0.015),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: size.width * 0.04,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Body
                  Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Column(
                      children: [
                        // Date Display
                        Container(
                          padding: EdgeInsets.all(size.width * 0.03),
                          decoration: BoxDecoration(
                            color: ColorConst.themeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ColorConst.themeColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: size.width * 0.04,
                                    color: ColorConst.themeColor,
                                  ),
                                  SizedBox(width: size.width * 0.02),
                                  Text(
                                    dateString,
                                    style: TextStyle(
                                      fontSize: size.width * 0.035,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConst.themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: size.height * 0.02),
                        
                        // Time Selection Card
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Time Display
                              Container(
                                padding: EdgeInsets.all(size.width * 0.03),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(size.width * 0.02),
                                      decoration: BoxDecoration(
                                        color: ColorConst.themeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.schedule,
                                        size: size.width * 0.045,
                                        color: ColorConst.themeColor,
                                      ),
                                    ),
                                    SizedBox(width: size.width * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedTimeString,
                                            style: TextStyle(
                                              fontSize: size.width * 0.025,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            selectedTime.format(context),
                                            style: TextStyle(
                                              fontSize: size.width * 0.04,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConst.themeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final TimeOfDay? time = await showTimePicker(
                                          context: context,
                                          initialTime: selectedTime,
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
                                          setState(() {
                                            selectedTime = time;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.008),
                                        decoration: BoxDecoration(
                                          color: ColorConst.themeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          changeString,
                                          style: TextStyle(
                                            fontSize: size.width * 0.028,
                                            fontWeight: FontWeight.w600,
                                            color: ColorConst.themeColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                            ],
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: ColorConst.themeColor, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: size.width * 0.032,
                                    fontWeight: FontWeight.w600,
                                    color: ColorConst.themeColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: size.width * 0.02),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final now = DateTime.now();
                                  final dateTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                                  final formattedTime = DateFormat('h:mm a').format(dateTime);
                                  Navigator.pop(context, {
                                    'time': formattedTime,
                                    'type': 'Check In',
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConst.themeColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: size.width * 0.032,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}

// Helper function to parse time string
TimeOfDay _parseTimeString(String timeString) {
  try {
    final format = DateFormat('h:mm a');
    final date = format.parse(timeString);
    return TimeOfDay.fromDateTime(date);
  } catch (e) {
    return TimeOfDay.now();
  }
}

// Helper function to get display hour (12-hour format)

// Time Control Widget

// Period Control Widget

// Type Selector Widget

// Rest of the widgets remain the same...

Widget _buildHeader(Size size, BuildContext context, VoidCallback onClose) {
  return Container(
    padding: EdgeInsets.all(size.width * 0.04),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          ColorConst.themeColor,
          ColorConst.themeColor.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(size.width * 0.02),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.add_card_outlined,
            color: Colors.white,
            size: size.width * 0.05,
          ),
        ),
        SizedBox(width: size.width * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                addPunchString,
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                manageEmployeeAttendanceString,
                style: TextStyle(
                  fontSize: size.width * 0.028,
                  color: Colors.white.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: EdgeInsets.all(size.width * 0.015),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: size.width * 0.04,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDateSection(Size size,dateTitle) {
  return Container(
    padding: EdgeInsets.all(size.width * 0.03),
    decoration: BoxDecoration(
      color: ColorConst.themeColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: ColorConst.themeColor.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: size.width * 0.04,
                color: ColorConst.themeColor,
              ),
              SizedBox(width: size.width * 0.02),
              Flexible(
                child: Text(
                  dateString,
                  style: TextStyle(
                    fontSize: size.width * 0.032,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          flex: 1,
          child: Text(
            dateTitle,
            style: TextStyle(
              fontSize: size.width * 0.032,
              fontWeight: FontWeight.bold,
              color: ColorConst.themeColor,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTableHeader(Size size) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: size.width * 0.01, vertical: size.height * 0.008),
    decoration: BoxDecoration(
      color: ColorConst.themeColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            timeString,
            style: TextStyle(
              fontSize: size.width * 0.03,
              fontWeight: FontWeight.bold,
              color: ColorConst.themeColor,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              inString,
              style: TextStyle(
                fontSize: size.width * 0.03,
                fontWeight: FontWeight.bold,
                color: ColorConst.themeColor,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              outString,
              style: TextStyle(
                fontSize: size.width * 0.03,
                fontWeight: FontWeight.bold,
                color: ColorConst.themeColor,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              actionString,
              style: TextStyle(
                fontSize: size.width * 0.03,
                fontWeight: FontWeight.bold,
                color: ColorConst.themeColor,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPunchRow({
  required Size size, 
  required String time, 
  required bool isInChecked, 
  required bool isOutChecked, 
  required bool isDeleted, 
  required BuildContext context, 
  required dynamic log, 
  required int? attendanceId,
  required DateTime currentDate,
  required Function(String) onUpdateLog,
  required Function(String) onUpdateStatus,
  required VoidCallback onDelete
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: size.width * 0.01, vertical: size.height * 0.01),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            time,
            style: TextStyle(
              fontSize: size.width * 0.032,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isInChecked,
                onChanged: (bool? value) {
                  if (value == true) onUpdateStatus('IN');
                },
                activeColor: ColorConst.themeColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isOutChecked,
                onChanged: (bool? value) {
                  if (value == true) onUpdateStatus('OUT');
                },
                activeColor: ColorConst.themeColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await showAddTimeDialog(context, size, existingTime: time);
                  if (result != null) {
                    onUpdateLog(result['time']);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(size.width * 0.012),
                  decoration: BoxDecoration(
                    color: ColorConst.themeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorConst.themeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: size.width * 0.042,
                    color: ColorConst.themeColor,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.015),
              GestureDetector(
                onTap: () {
                  _showDeleteConfirmationDialog(context, size, time, log, attendanceId, currentDate, onDelete);
                },
                child: Container(
                  padding: EdgeInsets.all(size.width * 0.012),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: size.width * 0.042,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmationDialog(BuildContext context, Size size, String time, dynamic log, int? attendanceId, DateTime currentDate, VoidCallback onDelete) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              deleteEntryString,
              style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$areYouSureDeletePunchString $time?',
          style: TextStyle(fontSize: size.width * 0.035),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600, fontSize: size.width * 0.032),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (log != null && attendanceId != null) {
                onDelete();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
            ),
            child: Text(
              deleteString,
              style: TextStyle(fontSize: size.width * 0.032),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildAddTimeButton(Size size, BuildContext context, DateTime currentDate, dynamic employeeId, String setCguid, VoidCallback onRefresh) {
  return GestureDetector(
    onTap: () async {
      final result = await showAddTimeDialog(context, size);
      if (result != null) {
        try {
          final timeStr = result['time'].toString();
          showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
          
          final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
          final parsedTime = DateFormat('h:mm a').parse(timeStr);
          final dateObj = DateTime(currentDate.year, currentDate.month, currentDate.day, parsedTime.hour, parsedTime.minute);
          final fullApiTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dateObj);

          var payload = {
            "IsUser": false,
            "Attendence": {
              "CompanyId": selectedcurentcompany?.companyId ?? 0,
              "EmpId": int.tryParse(employeeId.toString()) ?? 0,
              "Cguid": setCguid,
              "IsOnLeave": false,
              "AttendenceDate": formattedDate,
              "InTime": fullApiTime,
              "LateBy": 1,
              "EarlyBy": 1,
              "LeaveType": "",
              "Holiday": false,
              "LeaveId": 1,
              "ShiftId": 1,
              "OutTime": fullApiTime,
              "Present": true,
              "Absent": false
            },
            "AttendenceLog": [
              {
                "EmpId": int.tryParse(employeeId.toString()) ?? 0,
                "LeaveType": "",
                "LeaveId": 1,
                "AttendenceDate": formattedDate,
                "Time": fullApiTime,
                "ShiftId": 1,
                "Remarks": "",
                "Cguid": setCguid
              }
            ]
          };

          final response = await AttendanceApis().addNewPunchLog(payload);
          Navigator.pop(context); // close loader
          
          if (response != null && (response['success'] == true || response['Success'] == true)) {
            Provider.of<AttendanceEmp>(context, listen: false).getDateBloges(formattedDate, employeeId);
            onRefresh();
            showtoastmessage('$addedNewPunchAtString $timeStr');
          } else {
            String errorMsg = response != null ? (response['Flag'] ?? response['flag'] ?? "Failed to add punch") : "Failed to connect to server";
            throw Exception(errorMsg);
          }
        } catch (e) {
          Navigator.pop(context); // close loader
        }
      }
    },
    child: Container(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.012),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConst.themeColor.withOpacity(0.1),
            ColorConst.themeColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConst.themeColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: size.width * 0.045,
            color: ColorConst.themeColor,
          ),
          SizedBox(width: size.width * 0.02),
          Text(
            addTimeString,
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w600,
              color: ColorConst.themeColor,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildActionButtons(BuildContext context, Size size, dynamic employeeId, String attendanceCguid, int? attendanceId, String formattedDate, List<dynamic> localLogs, Set<dynamic> editedLogs, Set<dynamic> deletedLogs, VoidCallback onCancel) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: ColorConst.themeColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: size.height * 0.014),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w600,
              color: ColorConst.themeColor,
            ),
          ),
        ),
      ),
      SizedBox(width: size.width * 0.02),
      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            if (editedLogs.isEmpty && deletedLogs.isEmpty) {
              onCancel();
              return;
            }

            showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
            
            try {
              bool hasChanges = false;
              bool editSuccess = true;

              if (deletedLogs.isNotEmpty) {
                hasChanges = true;
                for (var delLog in deletedLogs) {
                  await Provider.of<AdminAttenDanceServices>(context, listen: false).deletePunchlog(
                    attendanceId: attendanceId,
                    setEmpid: int.tryParse(employeeId.toString()) ?? 0,
                    setLogId: int.tryParse(delLog.logId.toString()) ?? 0,
                    setStatus: delLog.status
                  );
                }
              }

              List<Map<String, dynamic>> attendenceLogArray = [];
              for (int i = 0; i < localLogs.length; i++) {
                var log = localLogs[i];
                if (!editedLogs.contains(log) || deletedLogs.contains(log)) continue;
                
                String apiTime = '';
                try {
                  String timeStr = log.time.toString();
                  DateTime parsed;
                  if (timeStr.startsWith('T')) {
                    final timePart = timeStr.substring(1);
                    final timeObj = DateFormat("HH:mm").parse(timePart);
                    final dateObj = DateTime.parse(formattedDate);
                    parsed = DateTime(dateObj.year, dateObj.month, dateObj.day, timeObj.hour, timeObj.minute);
                  } else {
                    parsed = DateTime.parse(timeStr);
                  }
                  apiTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(parsed);
                } catch (e) {
                  apiTime = log.time.toString();
                }

                attendenceLogArray.add({
                  "LogId": log.logId ?? 0,
                  "Status": log.status,
                  "AttendenceDate": formattedDate,
                  "Time": apiTime,
                  "Cguid": attendanceCguid,
                  "Remarks": log.remarks ?? ""
                });
              }

              if (attendenceLogArray.isNotEmpty) {
                hasChanges = true;
                var payload = {
                  "IsUser": false,
                  "Attendence": {
                    "AttendenceID": attendanceId ?? 0,
                    "EMPID": int.tryParse(employeeId.toString()) ?? 0,
                    "CGUID": attendanceCguid
                  },
                  "AttendenceLog": attendenceLogArray
                };
                
                final response = await AttendanceApis().saveMultipleAdminLogs(payload);
                if (response == null || (response['success'] != true && response['Success'] != true)) {
                  editSuccess = false;
                  String errorMsg = response != null ? (response['Flag'] ?? response['flag'] ?? "Failed to save punch entries") : "Failed to connect to server";
                  throw Exception(errorMsg);
                }
              }

              Navigator.pop(context); // close loader
              
              if (hasChanges && editSuccess) {
                Navigator.pop(context, true); // close dialog on success
                showtoastmessage(punchEntriesSavedSuccessfullyString);
              } else if (!hasChanges) {
                Navigator.pop(context, false);
              }
            } catch (e) {
               // loader is popped on success, but if exception happens we need to close loader.
               // wait, we didn't pop loader inside the try if it throws!
               Navigator.pop(context); // close loader on failure
               // do not close the dialog so the user can see their edits.
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConst.themeColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: size.height * 0.014),
            elevation: 2,
          ),
          child: Text(
            'Save',
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );
}