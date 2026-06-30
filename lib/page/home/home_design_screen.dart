 import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

Widget buildDateHeader(Size size) {
  return Consumer<HomeProvider>(
    builder: (context, homeProvider, child) {
      return Container(
        width: size.width,
        margin: EdgeInsets.all(size.width * 0.03),
        padding: EdgeInsets.all(size.width * 0.03),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ColorConst.grey,
              spreadRadius: 0.1,
              blurRadius: 0.1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Attendance',
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (homeProvider.isCurrentlyWorking)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _todayAttendanceWidget(
                    size,
                    Icons.login,
                    homeProvider.checkInTime,
                    "Check In",
                  ),
                ),
                Expanded(
                  child: _todayAttendanceWidget(
                    size,
                    Icons.logout,
                    homeProvider.checkOutTime,
                    "Check Out",
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _todayAttendanceWidget(
                        size,
                        Icons.history,
                        homeProvider.currentWorkingHours,
                        "Working HR'S",
                      ),
                      if (homeProvider.isCurrentlyWorking)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget buildAttendanceBoard(Size size,useEffect,mounted,{VoidCallback? onAllPressed}) {
  return Consumer<AdminAttenDanceServices>(
    builder: (context, attendanceService, child) {
      // Get current date
      DateTime currentDate = DateTime.now();
      
      // Track if this is first load
      bool isFirstLoad = attendanceService.mainHoldEmpList.isEmpty;
      
      // Initialize data on first load if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attendanceService.mainHoldEmpList.isEmpty && !attendanceService.islodering) {
          attendanceService.toDayDateAttendance(currentDate);
        }
      });
      
      // Auto update data every 30 seconds without showing loader
      useEffect(() {
        final timer = Timer.periodic(Duration(seconds: 30), (timer) {
          if (!attendanceService.islodering && mounted) {
            // Call API without showing loader
            attendanceService.toDayDateAttendance(currentDate);
          }
        });
        
        return timer.cancel;
      }, []);
      
      // Calculate percentage based on actual data
      int totalEmployees = attendanceService.mainHoldEmpList.length;
      int presentCount = attendanceService.totalPresents;
      
      double percentage = totalEmployees > 0 ? (presentCount / totalEmployees) * 100 : 0;
      
      
      return Container(
        width: size.width,
        margin: EdgeInsets.all(size.width * 0.03),
        padding: EdgeInsets.all(size.width * 0.03),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ColorConst.grey,
              spreadRadius: 0.1,
              blurRadius: 0.1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with All Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Attendance',
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(currentDate),
                        style: TextStyle(
                          fontSize: size.width * 0.025,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Last Updated Badge with Refresh Button
                    GestureDetector(
                      onTap: () {
                        if (!attendanceService.islodering) {
                          // Manual refresh with loader
                          attendanceService.toDayDateAttendance(currentDate);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorConst.themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              size: size.width * 0.03,
                              color: ColorConst.themeColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: size.width * 0.025,
                                fontWeight: FontWeight.w600,
                                color: ColorConst.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.015),
                    // All Button
                    GestureDetector(
                      onTap: onAllPressed,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorConst.themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text("See All",
                            style: TextStyle(
                                fontSize: size.width * 0.025,
                                fontWeight: FontWeight.w600,
                                color: ColorConst.themeColor,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_circle_right_rounded,color: ColorConst.themeColor, size: size.width * 0.04,)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Show loader only on first load, not during auto-refresh
            if (attendanceService.islodering && isFirstLoad)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: ColorConst.themeColor,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Loading attendance data...',
                      style: TextStyle(
                        fontSize: size.width * 0.03,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (totalEmployees == 0 && !attendanceService.islodering)
              // Show empty state when no data
              SizedBox(
                height: size.height * 0.15,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: size.width * 0.1,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No attendance data available for today',
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Progress Circle Container
                    GestureDetector(
                      onTap: () {
                        // Reset to show all employees
                        attendanceService.setEmpAttendanceList(attendanceService.mainHoldEmpList);
                      },
                      child: SizedBox(
                        width: size.width * 0.20,
                        height: size.width * 0.20,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: size.width * 0.18,
                              height: size.width * 0.18,
                              child: CircularProgressIndicator(
                                value: percentage / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(ColorConst.themeColor),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${percentage.toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: size.width * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConst.themeColor,
                                  ),
                                ),
                                Text(
                                  "Present",
                                  style: TextStyle(
                                    fontSize: size.width * 0.025,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: size.width * 0.04),
                    
                    // Present Card
                    GestureDetector(
                      onTap: () {
                        attendanceService.filtersOntapData(true);
                      },
                      child: Container(
                        width: size.width * 0.22,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: size.width * 0.05,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 6),
                            Text(
                              attendanceService.totalPresents.toString(),
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Present",
                              style: TextStyle(
                                fontSize: size.width * 0.028,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "${totalEmployees > 0 ? ((attendanceService.totalPresents / totalEmployees) * 100).toStringAsFixed(0) : 0}%",
                              style: TextStyle(
                                fontSize: size.width * 0.02,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: size.width * 0.02),
                    
                    // Absent Card
                    GestureDetector(
                      onTap: () {
                        attendanceService.filtersOntapData(false);
                      },
                      child: Container(
                        width: size.width * 0.22,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              size: size.width * 0.05,
                              color: Colors.red,
                            ),
                            SizedBox(height: 6),
                            Text(
                              attendanceService.totalAbsent.toString(),
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Absent",
                              style: TextStyle(
                                fontSize: size.width * 0.028,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "${totalEmployees > 0 ? ((attendanceService.totalAbsent / totalEmployees) * 100).toStringAsFixed(0) : 0}%",
                              style: TextStyle(
                                fontSize: size.width * 0.02,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: size.width * 0.02),
                    
                    // On Leave Card
                    GestureDetector(
                      onTap: () {
                        attendanceService.filterIsONleave();
                      },
                      child: Container(
                        width: size.width * 0.22,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.beach_access_outlined,
                              size: size.width * 0.05,
                              color: Colors.orange,
                            ),
                            SizedBox(height: 6),
                            Text(
                              attendanceService.totalIsOnLeave.toString(),
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "On Leave",
                              style: TextStyle(
                                fontSize: size.width * 0.028,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "${totalEmployees > 0 ? ((attendanceService.totalIsOnLeave / totalEmployees) * 100).toStringAsFixed(0) : 0}%",
                              style: TextStyle(
                                fontSize: size.width * 0.02,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}


Widget _todayAttendanceWidget(
  Size size,
  IconData icon,
  String time,
  String label,
) {
  return Column(
    children: [
      Container(
        width: size.width * 0.12,
        height: size.width * 0.12,
        decoration: BoxDecoration(
          color: ColorConst.themeColor.withOpacity(0.09),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: ColorConst.themeColor,
          size: size.width * 0.06,
        ),
      ),
      SizedBox(height: 8),
      Text(
        time,
        style: TextStyle(
          color: ColorConst.black,
          fontFamily: fontInterSemiBoldString,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: ColorConst.greyColor,
          fontFamily: fontInterSemiBoldString,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    ],
  );
}
