 

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
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: size.width * 0.015,
        ),
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConst.isDark 
                ? Colors.white.withOpacity(0.06) 
                : Colors.black.withOpacity(0.04),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConst.isDark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                      todaysAttendanceString,
                      style: TextStyle(
                        fontSize: size.width * 0.042,
                        fontWeight: FontWeight.bold,
                        fontFamily: fontInterSemiBoldString,
                        color: ColorConst.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: size.width * 0.032,
                        fontFamily: fontInterSemiBoldString,
                        color: ColorConst.textgrey,
                      ),
                    ),
                  ],
                ),
                if (homeProvider.isCurrentlyWorking)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xff10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xff10B981).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xff10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeUpperString,
                          style: TextStyle(
                            color: Color(0xff10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontFamily: fontInterSemiBoldString,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _todayAttendanceWidget(
                    size,
                    Icons.login_rounded,
                    homeProvider.checkInTime,
                    checkInString,
                    const Color(0xff10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _todayAttendanceWidget(
                    size,
                    Icons.logout_rounded,
                    homeProvider.checkOutTime,
                    checkOutString,
                    const Color(0xffF43F5E),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _todayAttendanceWidget(
                    size,
                    Icons.schedule_rounded,
                    homeProvider.currentWorkingHours,
                    workingHrsString,
                    ColorConst.themeColor,
                    isWorking: homeProvider.isCurrentlyWorking,
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

Widget buildAttendanceBoard(Size size, mounted, {VoidCallback? onAllPressed}) {
  return Consumer<AdminAttenDanceServices>(
    builder: (context, attendanceService, child) {
      // Get current date
      DateTime currentDate = DateTime.now();
      
      // Track if this is first load
      bool isFirstLoad = attendanceService.mainHoldEmpList.isEmpty;

      // Calculate percentage based on actual data
      int totalEmployees = attendanceService.mainHoldEmpList.length;
      int presentCount = attendanceService.totalPresents;
      
      double percentage = totalEmployees > 0 ? (presentCount / totalEmployees) * 100 : 0;
      
      
      return Container(
        width: size.width,
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: size.width * 0.015,
        ),
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConst.isDark 
                ? Colors.white.withOpacity(0.06) 
                : Colors.black.withOpacity(0.04),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConst.isDark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                        todaysAttendanceString,
                        style: TextStyle(
                          fontSize: size.width * 0.042,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontInterSemiBoldString,
                          color: ColorConst.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(currentDate),
                        style: TextStyle(
                          fontSize: size.width * 0.032,
                          fontFamily: fontInterSemiBoldString,
                          color: ColorConst.textgrey,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorConst.themeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ColorConst.themeColor.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: size.width * 0.032,
                              color: ColorConst.themeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: size.width * 0.028,
                                fontWeight: FontWeight.bold,
                                fontFamily: fontInterSemiBoldString,
                                color: ColorConst.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // All Button
                    GestureDetector(
                      onTap: onAllPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorConst.themeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ColorConst.themeColor.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(seeAllString,
                            style: TextStyle(
                                fontSize: size.width * 0.028,
                                fontWeight: FontWeight.bold,
                                fontFamily: fontInterSemiBoldString,
                                color: ColorConst.themeColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_circle_right_rounded,color: ColorConst.themeColor, size: size.width * 0.038,)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Show loader only on first load, not during auto-refresh
            if (attendanceService.islodering && isFirstLoad)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: ColorConst.themeColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading attendance data...',
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          fontFamily: fontInterSemiBoldString,
                          color: ColorConst.textgrey,
                        ),
                      ),
                    ],
                  ),
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
                        Icons.bar_chart_rounded,
                        size: size.width * 0.1,
                        color: ColorConst.textgrey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$noDataAvailableString $todaysAttendanceString',
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          fontFamily: fontInterSemiBoldString,
                          color: ColorConst.textgrey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  // Progress Circle Container
                  GestureDetector(
                    onTap: () {
                      // Reset to show all employees
                      attendanceService.setEmpAttendanceList(attendanceService.mainHoldEmpList);
                    },
                    child: SizedBox(
                      width: size.width * 0.16,
                      height: size.width * 0.16,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: size.width * 0.15,
                            height: size.width * 0.15,
                            child: CircularProgressIndicator(
                              value: percentage / 100,
                              strokeWidth: 4.5,
                              backgroundColor: ColorConst.isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.04),
                              valueColor: AlwaysStoppedAnimation<Color>(ColorConst.themeColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${percentage.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  fontSize: size.width * 0.028,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: fontInterSemiBoldString,
                                  color: ColorConst.themeColor,
                                ),
                              ),
                              Text(
                                "Present",
                                style: TextStyle(
                                  fontSize: size.width * 0.018,
                                  fontFamily: fontInterSemiBoldString,
                                  color: ColorConst.textgrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  // Vertical divider
                  Container(
                    height: size.width * 0.12,
                    width: 1.2,
                    color: ColorConst.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                  ),
                  const SizedBox(width: 12),
                  
                  // Stat cards
                  Expanded(
                    child: Row(
                      children: [
                        _adminStatColumn(
                          size,
                          Icons.check_circle_outline_rounded,
                          attendanceService.totalPresents.toString(),
                          "Present",
                          Colors.blue,
                          onTap: () => attendanceService.filtersOntapData(true),
                        ),
                        const SizedBox(width: 6),
                        _adminStatColumn(
                          size,
                          Icons.remove_circle_outline_rounded,
                          attendanceService.totalAbsent.toString(),
                          "Absent",
                          Colors.red,
                          onTap: () => attendanceService.filtersOntapData(false),
                        ),
                        const SizedBox(width: 6),
                        _adminStatColumn(
                          size,
                          Icons.beach_access_rounded,
                          attendanceService.totalIsOnLeave.toString(),
                          "On Leave",
                          Colors.orange,
                          onTap: () => attendanceService.filterIsONleave(),
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

Widget _adminStatColumn(
  Size size,
  IconData icon,
  String value,
  String label,
  Color color, {
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(ColorConst.isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: size.width * 0.032,
                fontWeight: FontWeight.bold,
                fontFamily: fontInterSemiBoldString,
                color: ColorConst.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: size.width * 0.022,
                fontFamily: fontInterSemiBoldString,
                color: ColorConst.textgrey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _todayAttendanceWidget(
  Size size,
  IconData icon,
  String time,
  String label,
  Color accentColor, {
  bool isWorking = false,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      vertical: size.width * 0.03,
      horizontal: size.width * 0.015,
    ),
    decoration: BoxDecoration(
      color: ColorConst.greyOpicityColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isWorking 
            ? const Color(0xff10B981).withOpacity(0.4) 
            : (ColorConst.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        width: 1,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size.width * 0.09,
          height: size.width * 0.09,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: size.width * 0.045,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            color: ColorConst.black,
            fontFamily: fontInterSemiBoldString,
            fontWeight: FontWeight.bold,
            fontSize: size.width * 0.032,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWorking) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xff10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: ColorConst.textgrey,
                  fontFamily: fontInterSemiBoldString,
                  fontWeight: FontWeight.w600,
                  fontSize: size.width * 0.025,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
