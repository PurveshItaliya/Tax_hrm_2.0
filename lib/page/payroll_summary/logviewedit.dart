// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/provider/adminattendance.dart';

// Main Add Punch Dialog
Future<void> showAddPunchDialog(BuildContext context, Size size, DateTime currentDate, String setCguid, String setAttendanceIds, employeeId) async {
  final dateTitle = DateFormat('dd/MM/yyyy').format(currentDate);
  final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
  
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
                  _buildHeader(size, context),
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

                                      final logs = attendanceEmp.selectedDateLog?.attendenceLog ?? [];
                                      if (logs.isEmpty) {
                                        return Center(
                                          child: Text(
                                            "No punches found for this date",
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: logs.length,
                                        itemBuilder: (context, index) {
                                          final log = logs[index];
                                          String timeStr = '';
                                          if (log.time != null) {
                                            try {
                                              timeStr = DateFormat('hh:mm a').format(DateTime.parse(log.time.toString()));
                                            } catch (e) {
                                              timeStr = log.time.toString();
                                            }
                                          }
                                          final isIn = log.status == 'IN';
                                          final isOut = log.status == 'OUT';
                                          final attendanceId = attendanceEmp.selectedDateLog?.attendence?.attendenceID;

                                          return _buildPunchRow(size, timeStr, isIn, isOut, false, context, log, attendanceId);
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
                        _buildAddTimeButton(size, context, currentDate, employeeId, setCguid),
                        SizedBox(height: size.height * 0.02),
                        _buildActionButtons(context, size),
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
                                existingTime == null ? 'Add Time' : 'Edit Time',
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Select punch time and type',
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
                                    'Date',
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
                                            'Selected Time',
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
                                          'Change',
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

Widget _buildHeader(Size size, BuildContext context) {
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
                'Add Punch',
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Manage employee attendance',
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
                  'Date',
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
            'Time',
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
              'In',
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
              'Out',
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
              'Action',
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

Widget _buildPunchRow(Size size, String time, bool isInChecked, bool isOutChecked, bool isDeleted, context, dynamic log, int? attendanceId) {
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
                onChanged: (bool? value) {},
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
                onChanged: (bool? value) {},
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
                  await showAddTimeDialog(context, size, existingTime: time);
                  // if (result != null) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(
                  //       content: Text('Punch entry at $time updated'),
                  //       backgroundColor: Colors.green,
                  //       duration: Duration(seconds: 2),
                  //     ),
                  //   );
                  // }
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
                  _showDeleteConfirmationDialog(context, size, time, log, attendanceId);
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

void _showDeleteConfirmationDialog(BuildContext context, Size size, String time, dynamic log, int? attendanceId) {
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
              'Delete Entry',
              style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the punch entry at $time?',
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
            onPressed: () async {
              Navigator.pop(context);
              if (log != null && attendanceId != null) {
                // Call API
                await Provider.of<AdminAttenDanceServices>(context, listen: false).deletePunchlog(
                  attendanceId: attendanceId,
                  setEmpid: log.empId,
                  setLogId: log.logId,
                  setStatus: log.status
                );
                
                // Refresh list
                String formattedDate = '';
                try {
                  formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(log.time.toString()));
                } catch(e) {
                  formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                }
                Provider.of<AttendanceEmp>(context, listen: false).getDateBloges(formattedDate, log.empId);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Punch entry at $time deleted'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
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
              'Delete',
              style: TextStyle(fontSize: size.width * 0.032),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildAddTimeButton(Size size, BuildContext context, DateTime currentDate, employeeId, String setCguid) {
  return GestureDetector(
    onTap: () async {
      final result = await showAddTimeDialog(context, size);
      if (result != null) {
        try {
          final timeStr = result['time'].toString();
          
          showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
          
          final formattedDateStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentDate);
          
          final response = await AttendanceApis().attendanceAddAdmin(
             attendanceDate: formattedDateStr,
             setInTime: timeStr,
             setEmpid: employeeId,
             setCguid: setCguid,
             setRemarks: "Added by admin",
             setweekoff: currentDate.weekday == DateTime.sunday
          );
          
          Navigator.pop(context); // close loader
          
          if (response != null && response.success == true) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
            Provider.of<AttendanceEmp>(context, listen: false).getDateBloges(formattedDate, employeeId);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added new punch at $timeStr'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            final errorMsg = response?.flag ?? 'Server rejected the request';
            throw Exception(errorMsg);
          }
        } catch (e) {
          Navigator.pop(context); // close loader on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add punch: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
            'Add Time',
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

Widget _buildActionButtons(BuildContext context, Size size) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
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
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Punch entries saved successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
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