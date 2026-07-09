// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:excel/excel.dart' as ex show Border, BorderStyle;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/attendanceadmin.dart';
import 'package:tax_hrm/api/holidayapi.dart';
import 'package:tax_hrm/api/leaveapi.dart';
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/attendance/allemployeattendance.dart';
import 'package:tax_hrm/models/attendance/monthly_excel_report_model.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/employee_master/pdf_csv_print_function.dart';
import 'package:tax_hrm/provider/employee_master_provider.dart';
import 'package:tax_hrm/utils/attendance_perf_logger.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class MonthlyAttendanceExcelService {
  static Future<void> generateAndDownloadReport(BuildContext context, {DateTime? targetMonth}) async {
    final month = targetMonth ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthStr = DateFormat('MMMM yyyy').format(month);
    final fileMonthName = DateFormat('MMMM_yyyy').format(month);

    // 1. Storage Permission Check (using existing project utility)
    bool hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      showtoastmessage("Storage permission is required to save Excel report.");
      return;
    }
    if (!context.mounted) return;

    // Show loading progress dialog
    BuildContext? loadingDialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        loadingDialogContext = dialogContext;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: ColorConst.themeColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Generating Monthly Excel Report for $monthStr...",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    void dismissLoadingDialog() {
      try {
        if (loadingDialogContext != null && loadingDialogContext!.mounted) {
          Navigator.pop(loadingDialogContext!);
          loadingDialogContext = null;
          return;
        }
      } catch (_) {}
      try {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } catch (_) {}
    }

    try {
      await AttendancePerformanceLogger.instance.track(
        'Generate Monthly Employee Attendance Excel ($monthStr)',
        () async {
          // Fetch employee master
          final empProvider = Provider.of<EmployeeMasterProvider>(context, listen: false);
          List<Employeelists> allEmployees = empProvider.allemployes;
          if (allEmployees.isEmpty) allEmployees = empProvider.employeeList;
          if (allEmployees.isEmpty) allEmployees = allManinEmplyeList;

          // Filter only active employees
          List<Employeelists> activeEmployees = allEmployees.where((emp) {
            if (emp.isActive == false) return false;
            return true;
          }).toList();

          if (activeEmployees.isEmpty) {
            dismissLoadingDialog();
            showtoastmessage("No active employee records found for $monthStr.");
            return;
          }

          final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          final DateTime now = DateTime.now();
          final DateTime todayOnly = DateTime(now.year, now.month, now.day);

          // Fetch Holidays for this year/month
          List<GetHolidayViews> holidayList = [];
          try {
            final holidays = await HolidayAPIS().getHolidays();
            if (holidays != null && holidays is List) {
              for (var h in holidays) {
                if (h is GetHolidayViews) holidayList.add(h);
              }
            }
          } catch (e) { /* ignored fallback */ }

          // Fetch Leaves
          List<dynamic> leaveList = [];
          try {
            final leaves = await LeaveApiService().userLeaveList();
            if (leaves != null && leaves.leaveListData != null) {
              leaveList = leaves.leaveListData!;
            }
          } catch (e) { /* ignored fallback */ }

          // Concurrently fetch daily attendance records for the month up to today
          Map<int, List<AllEmployeAttendance>> dailyAttendanceCache = {};
          List<int> validDaysToFetch = [];
          for (int d = 1; d <= daysInMonth; d++) {
            final dateToCheck = DateTime(month.year, month.month, d);
            if (!dateToCheck.isAfter(todayOnly)) {
              validDaysToFetch.add(d);
            }
          }

          // Fetch in batched chunks of 6 parallel requests to ensure optimal speed and zero network overload
          const int batchSize = 6;
          for (int i = 0; i < validDaysToFetch.length; i += batchSize) {
            final chunk = validDaysToFetch.sublist(
              i,
              (i + batchSize > validDaysToFetch.length) ? validDaysToFetch.length : i + batchSize,
            );

            await Future.wait(chunk.map((day) async {
              try {
                final dateObj = DateTime(month.year, month.month, day);
                final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateObj);
                final res = await AdminAttenDanceApis().getDateAttendance(formattedDate);
                if (res != null && res is List<AllEmployeAttendance>) {
                  dailyAttendanceCache[day] = res;
                }
              } catch (e) {
                dailyAttendanceCache[day] = [];
              }
            }));
          }

          // Build EmployeeMonthlyExcelData items
          List<EmployeeMonthlyExcelData> excelRows = [];
          for (var emp in activeEmployees) {
            final empId = emp.id ?? 0;
            final empCode = emp.cguid ?? emp.id?.toString() ?? '-';
            final fullName = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
            final dept = emp.departmentName?.toString() ?? '-';
            final desig = emp.positionName?.toString() ?? '-';

            Map<int, DayExcelStatus> dayStatuses = {};

            for (int d = 1; d <= daysInMonth; d++) {
              final dateObj = DateTime(month.year, month.month, d);
              String statusCode = '-';
              String? inT;
              String? outT;

              if (dateObj.isAfter(todayOnly)) {
                statusCode = '-';
              } else {
                // Check weekend (Saturday / Sunday)
                final int weekday = dateObj.weekday; // 6 = Saturday, 7 = Sunday
                bool isWeekend = (weekday == DateTime.sunday);
                if (weekday == DateTime.saturday) {
                  // Standard 2nd / 4th Saturday or company weekly off rule
                  final int weekOfMonth = ((d - 1) ~/ 7) + 1;
                  if (weekOfMonth == 2 || weekOfMonth == 4) isWeekend = true;
                }

                // Check holiday
                bool isHoliday = false;
                for (var h in holidayList) {
                  if (h.holidayDate != null && h.holidayDate!.toString().isNotEmpty) {
                    try {
                      final fDate = DateTime.parse(h.holidayDate!.toString());
                      final tDate = (h.enddate != null && h.enddate!.toString().isNotEmpty)
                          ? DateTime.parse(h.enddate!.toString())
                          : fDate;
                      final fOnly = DateTime(fDate.year, fDate.month, fDate.day);
                      final tOnly = DateTime(tDate.year, tDate.month, tDate.day);
                      if (!dateObj.isBefore(fOnly) && !dateObj.isAfter(tOnly)) {
                        isHoliday = true;
                        break;
                      }
                    } catch (e) { /* ignore parse error */ }
                  }
                }

                // Check attendance logs for this day
                AllEmployeAttendance? dayRecord;
                final dayLogs = dailyAttendanceCache[d];
                if (dayLogs != null) {
                  for (var att in dayLogs) {
                    if (att.empId == empId) {
                      dayRecord = att;
                      break;
                    }
                  }
                }

                if (dayRecord != null && dayRecord.present == true && dayRecord.inTime != null) {
                  inT = dayRecord.inTime?.toString();
                  outT = dayRecord.outTime?.toString();
                  // Check if half day via leaveType or status
                  final String lType = dayRecord.leaveType?.toString().toLowerCase() ?? '';
                  if (lType.contains('half')) {
                    statusCode = 'HL';
                  } else {
                    statusCode = 'P';
                  }
                } else if (dayRecord != null && (dayRecord.isOnLeave == true || dayRecord.leaveCguid != null)) {
                  // Leave record explicitly found in attendance logs
                  final String lType = dayRecord.leaveType?.toString().toLowerCase() ?? '';
                  if (lType.contains('half')) {
                    statusCode = 'HL';
                  } else {
                    statusCode = 'FL';
                  }
                } else {
                  // Check leave master list for approved leaves
                  bool isOnApprovedLeave = false;
                  bool isHalfLeave = false;
                  for (var lv in leaveList) {
                    try {
                      if (lv.empId == empId && (lv.approveStatus == 'Approved' || lv.approveStatus == 'true' || lv.approveStatus == true)) {
                        final fromD = DateTime.parse(lv.fromDate.toString());
                        final toD = DateTime.parse(lv.toDate.toString());
                        final fOnly = DateTime(fromD.year, fromD.month, fromD.day);
                        final tOnly = DateTime(toD.year, toD.month, toD.day);

                        if (!dateObj.isBefore(fOnly) && !dateObj.isAfter(tOnly)) {
                          isOnApprovedLeave = true;
                          if (lv.leaveDuration != null && (lv.leaveDuration.toString().toLowerCase().contains('half') || lv.leaveDuration.toString() == '0.5')) {
                            isHalfLeave = true;
                          }
                          break;
                        }
                      }
                    } catch (e) { /* ignore parse errors */ }
                  }

                  if (isOnApprovedLeave) {
                    statusCode = isHalfLeave ? 'HL' : 'FL';
                  } else if (isHoliday) {
                    statusCode = 'H';
                  } else if (isWeekend) {
                    statusCode = 'WO';
                  } else if (dayRecord != null && dayRecord.absent == true) {
                    statusCode = 'A';
                  } else {
                    statusCode = 'A'; // Past working day with no punch and no leave
                  }
                }
              }

              dayStatuses[d] = DayExcelStatus(
                day: d,
                status: statusCode,
                inTime: inT,
                outTime: outT,
              );
            }

            final rowData = EmployeeMonthlyExcelData(
              empId: empId,
              empCode: empCode,
              fullName: fullName.isEmpty ? 'Unknown Employee $empId' : fullName,
              departmentName: dept,
              designation: desig,
              dailyStatuses: dayStatuses,
            );
            rowData.calculateSummary(daysInMonth, month);
            excelRows.add(rowData);
          }

          // Sort alphabetically by employee name for professional HR audit formatting
          excelRows.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

          // Company Name determination
          String companyName = selectedcurentcompany?.companyName?.toString() ?? '';
          if (companyName.trim().isEmpty && curentUser != null && curentUser is Map) {
            companyName = curentUser['CompanyName']?.toString() ?? '';
          }
          if (companyName.trim().isEmpty) {
            companyName = 'TAX HRM 2.0';
          }

          // 2. Initialize Excel Workbook
          var excel = Excel.createExcel();
          String defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
          String sheet1Name = 'Monthly_Attendance_Report_$fileMonthName';
          excel.rename(defaultSheetName, sheet1Name);
          Sheet sheet = excel[sheet1Name];
          excel.setDefaultSheet(sheet1Name);

          final int totalColumns = 3 + daysInMonth + 6; // ID, Name, Desig + days + 6 summaries

          // 3. Define Styles
          CellStyle titleStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
            backgroundColorHex: ExcelColor.fromHexString('#1D976C'),
          );

          CellStyle subTitleStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Left,
            fontColorHex: ExcelColor.fromHexString('#2D3748'),
          );

          CellStyle headerStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
            backgroundColorHex: ExcelColor.fromHexString('#2D3748'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle leftHeaderStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Left,
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
            backgroundColorHex: ExcelColor.fromHexString('#2D3748'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle centerDataStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle leftDataStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Left,
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          // Color coded attendance status styles
          CellStyle presentStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#E6F4EA'),
            fontColorHex: ExcelColor.fromHexString('#137333'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle absentStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#FCE8E6'),
            fontColorHex: ExcelColor.fromHexString('#C5221F'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle fullLeaveStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#FEF7E0'),
            fontColorHex: ExcelColor.fromHexString('#B06000'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle halfLeaveStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#FFF0D4'),
            fontColorHex: ExcelColor.fromHexString('#E37400'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle holidayStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
            fontColorHex: ExcelColor.fromHexString('#1A73E8'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle weekendStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#F1F3F4'),
            fontColorHex: ExcelColor.fromHexString('#5F6368'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle summaryNumStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle summaryPercentStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#E6F4EA'),
            fontColorHex: ExcelColor.fromHexString('#137333'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          CellStyle deptTotalLabelStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
            fontColorHex: ExcelColor.fromHexString('#2D3748'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          // Row 0: Merged Title
          var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
          titleCell.value = TextCellValue("MONTHLY EMPLOYEE ATTENDANCE REPORT");
          titleCell.cellStyle = titleStyle;
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
            CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 0),
            customValue: TextCellValue("MONTHLY EMPLOYEE ATTENDANCE REPORT"),
          );

          // Row 1: Company, Selected Month, Generated Date
          var cA1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
          cA1.value = TextCellValue("Company: $companyName");
          cA1.cellStyle = subTitleStyle;

          var cE1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1));
          cE1.value = TextCellValue("Month: $monthStr");
          cE1.cellStyle = subTitleStyle;

          var cI1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1));
          cI1.value = TextCellValue("Generated: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}");
          cI1.cellStyle = subTitleStyle;

          // Row 3: Table Headers
          final List<String> staticHeaders = ['Employee ID', 'Employee Name', 'Designation'];
          for (int i = 0; i < staticHeaders.length; i++) {
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
            cell.value = TextCellValue(staticHeaders[i]);
            cell.cellStyle = (i == 1 || i == 2) ? leftHeaderStyle : headerStyle;
          }

          // Day Headers (1 to daysInMonth)
          for (int d = 1; d <= daysInMonth; d++) {
            final date = DateTime(month.year, month.month, d);
            final dayName = DateFormat('E').format(date);
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + d, rowIndex: 3));
            cell.value = TextCellValue("$d ($dayName)");
            cell.cellStyle = headerStyle;
          }

          // Summary Headers
          final List<String> summaryHeaders = [
            'Total Present',
            'Total Absent',
            'Total Full Leave',
            'Total Half Leave',
            'Total Working Days',
            'Attendance %'
          ];
          for (int s = 0; s < summaryHeaders.length; s++) {
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + daysInMonth + s, rowIndex: 3));
            cell.value = TextCellValue(summaryHeaders[s]);
            cell.cellStyle = headerStyle;
          }

          // Row 4..N: Employee Rows
          for (int i = 0; i < excelRows.length; i++) {
            final emp = excelRows[i];
            final int rIndex = 4 + i;

            // Col 0: Employee ID
            var cellId = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex));
            cellId.value = TextCellValue(emp.empId == 0 ? (emp.empCode.isNotEmpty ? emp.empCode : '-') : emp.empId.toString());
            cellId.cellStyle = centerDataStyle;

            // Col 1: Employee Name
            var cellName = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex));
            cellName.value = TextCellValue(emp.fullName);
            cellName.cellStyle = leftDataStyle;

            // Col 2: Designation
            var cellDesig = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex));
            cellDesig.value = TextCellValue(emp.designation);
            cellDesig.cellStyle = leftDataStyle;

            // Day Columns
            for (int d = 1; d <= daysInMonth; d++) {
              final ds = emp.dailyStatuses[d] ?? DayExcelStatus(day: d, status: '-');
              String codeStr = ds.status;
              CellStyle chosenStyle = centerDataStyle;

              if (ds.status == 'P') {
                codeStr = 'P';
                chosenStyle = presentStyle;
              } else if (ds.status == 'A') {
                codeStr = 'A';
                chosenStyle = absentStyle;
              } else if (ds.status == 'FL') {
                codeStr = 'FL';
                chosenStyle = fullLeaveStyle;
              } else if (ds.status == 'HL') {
                codeStr = 'HL';
                chosenStyle = halfLeaveStyle;
              } else if (ds.status == 'H') {
                codeStr = 'H';
                chosenStyle = holidayStyle;
              } else if (ds.status == 'WO') {
                codeStr = 'WO';
                chosenStyle = weekendStyle;
              } else {
                codeStr = '-';
                chosenStyle = centerDataStyle;
              }

              var cellDay = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + d, rowIndex: rIndex));
              cellDay.value = TextCellValue(codeStr);
              cellDay.cellStyle = chosenStyle;
            }

            // Summary Columns
            int sumStartCol = 3 + daysInMonth;

            var cPres = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol, rowIndex: rIndex));
            cPres.value = TextCellValue(_formatNum(emp.totalPresent));
            cPres.cellStyle = summaryNumStyle;

            var cAbs = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 1, rowIndex: rIndex));
            cAbs.value = TextCellValue(emp.totalAbsent.toString());
            cAbs.cellStyle = summaryNumStyle;

            var cFLeave = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 2, rowIndex: rIndex));
            cFLeave.value = TextCellValue(_formatNum(emp.totalFullLeave));
            cFLeave.cellStyle = summaryNumStyle;

            var cHLeave = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 3, rowIndex: rIndex));
            cHLeave.value = TextCellValue(emp.totalHalfLeave.toString());
            cHLeave.cellStyle = summaryNumStyle;

            var cWork = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 4, rowIndex: rIndex));
            cWork.value = TextCellValue(emp.totalWorkingDays.toString());
            cWork.cellStyle = summaryNumStyle;

            var cPerc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 5, rowIndex: rIndex));
            cPerc.value = TextCellValue("${emp.attendancePercentage.toStringAsFixed(1)}%");
            cPerc.cellStyle = summaryPercentStyle;
          }

          // Grand Total Row for Employee-Wise Sheet
          double grandTotalPresent = 0.0;
          int grandTotalAbsent = 0;
          double grandTotalFullLeave = 0.0;
          int grandTotalHalfLeave = 0;
          int grandTotalWorkingDays = 0;

          for (var emp in excelRows) {
            grandTotalPresent += emp.totalPresent;
            grandTotalAbsent += emp.totalAbsent;
            grandTotalFullLeave += emp.totalFullLeave;
            grandTotalHalfLeave += emp.totalHalfLeave;
            grandTotalWorkingDays += emp.totalWorkingDays;
          }

          int grandTotalRowIndex = 4 + excelRows.length;
          var gIdCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: grandTotalRowIndex));
          gIdCell.value = TextCellValue("Total");
          gIdCell.cellStyle = deptTotalLabelStyle;

          var gNameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: grandTotalRowIndex));
          gNameCell.value = TextCellValue("Grand Total (${excelRows.length} Employees)");
          gNameCell.cellStyle = deptTotalLabelStyle;

          var gDesigCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: grandTotalRowIndex));
          gDesigCell.value = TextCellValue("-");
          gDesigCell.cellStyle = deptTotalLabelStyle;

          for (int d = 1; d <= daysInMonth; d++) {
            var gDayCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + d, rowIndex: grandTotalRowIndex));
            gDayCell.value = TextCellValue("-");
            gDayCell.cellStyle = deptTotalLabelStyle;
          }

          int sumStartColIndex = 3 + daysInMonth;
          var gPres = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartColIndex, rowIndex: grandTotalRowIndex));
          gPres.value = TextCellValue(_formatNum(grandTotalPresent));
          gPres.cellStyle = summaryNumStyle;

          var gAbs = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartColIndex + 1, rowIndex: grandTotalRowIndex));
          gAbs.value = TextCellValue(grandTotalAbsent.toString());
          gAbs.cellStyle = summaryNumStyle;

          var gFLeave = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartColIndex + 2, rowIndex: grandTotalRowIndex));
          gFLeave.value = TextCellValue(_formatNum(grandTotalFullLeave));
          gFLeave.cellStyle = summaryNumStyle;

          var gHLeave = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartColIndex + 3, rowIndex: grandTotalRowIndex));
          gHLeave.value = TextCellValue(grandTotalHalfLeave.toString());
          gHLeave.cellStyle = summaryNumStyle;

          var gWork = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartColIndex + 4, rowIndex: grandTotalRowIndex));
          gWork.value = TextCellValue(grandTotalWorkingDays.toString());
          gWork.cellStyle = summaryNumStyle;

          double grandAvgPerc = grandTotalWorkingDays > 0 ? (grandTotalPresent / grandTotalWorkingDays) * 100.0 : 0.0;
          if (grandAvgPerc > 100.0) grandAvgPerc = 100.0;
          var gPerc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartColIndex + 5, rowIndex: grandTotalRowIndex));
          gPerc.value = TextCellValue("${grandAvgPerc.toStringAsFixed(1)}%");
          gPerc.cellStyle = summaryPercentStyle;

          // 4. Column Width adjustments (Auto Column Widths)
          sheet.setColumnWidth(0, 16.0); // ID
          sheet.setColumnWidth(1, 30.0); // Name
          sheet.setColumnWidth(2, 60.0); // Desig

          for (int d = 1; d <= daysInMonth; d++) {
            if (d == 30 || d == 31) {
              sheet.setColumnWidth(2 + d, 8.0); // 30th & 31st slightly smaller
            } else {
              sheet.setColumnWidth(2 + d, 8.0); // 1st to 29th smaller width
            }
          }
          for (int s = 0; s < summaryHeaders.length; s++) {
            sheet.setColumnWidth(3 + daysInMonth + s, 18.0);
          }

          // 5. Create Monthly Attendance Department Wise Sheet
          Sheet deptSheet = excel['Monthly Attendance Department Wise'];

          var deptTitleCell = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
          deptTitleCell.value = TextCellValue("MONTHLY DEPARTMENT-WISE ATTENDANCE REPORT - $monthStr");
          deptTitleCell.cellStyle = titleStyle;
          deptSheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
            CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 0),
            customValue: TextCellValue("MONTHLY DEPARTMENT-WISE ATTENDANCE REPORT - $monthStr"),
          );

          var deptSubA1 = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
          deptSubA1.value = TextCellValue("Company: $companyName");
          deptSubA1.cellStyle = subTitleStyle;

          var deptSubE1 = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1));
          deptSubE1.value = TextCellValue("Month: $monthStr");
          deptSubE1.cellStyle = subTitleStyle;

          var deptSubI1 = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1));
          deptSubI1.value = TextCellValue("Generated: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}");
          deptSubI1.cellStyle = subTitleStyle;

          Map<String, List<EmployeeMonthlyExcelData>> departmentGroups = {};
          for (var emp in excelRows) {
            String dept = emp.departmentName.trim();
            if (dept.isEmpty || dept == '-') {
              dept = 'Unassigned Department';
            }
            if (!departmentGroups.containsKey(dept)) {
              departmentGroups[dept] = [];
            }
            departmentGroups[dept]!.add(emp);
          }

          List<String> sortedDepartments = departmentGroups.keys.toList()
            ..sort((a, b) {
              if (a == 'Unassigned Department') return 1;
              if (b == 'Unassigned Department') return -1;
              return a.toLowerCase().compareTo(b.toLowerCase());
            });

          CellStyle deptHeaderBannerStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Left,
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
            backgroundColorHex: ExcelColor.fromHexString('#1D976C'),
            leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
            bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          );

          int currentDeptRow = 3;
          for (String dept in sortedDepartments) {
            List<EmployeeMonthlyExcelData> deptEmployees = departmentGroups[dept]!;
            deptEmployees.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

            var bannerCell = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentDeptRow));
            bannerCell.value = TextCellValue("DEPARTMENT: ${dept.toUpperCase()} (${deptEmployees.length} Employee${deptEmployees.length > 1 ? 's' : ''})");
            bannerCell.cellStyle = deptHeaderBannerStyle;
            deptSheet.merge(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentDeptRow),
              CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: currentDeptRow),
              customValue: TextCellValue("DEPARTMENT: ${dept.toUpperCase()} (${deptEmployees.length} Employee${deptEmployees.length > 1 ? 's' : ''})"),
            );
            currentDeptRow++;

            final List<String> deptSubHeaders = ['Employee ID', 'Employee Name', 'Designation'];
            for (int i = 0; i < deptSubHeaders.length; i++) {
              var cell = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentDeptRow));
              cell.value = TextCellValue(deptSubHeaders[i]);
              cell.cellStyle = (i == 1 || i == 2) ? leftHeaderStyle : headerStyle;
            }
            for (int d = 1; d <= daysInMonth; d++) {
              final date = DateTime(month.year, month.month, d);
              final dayName = DateFormat('E').format(date);
              var cell = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + d, rowIndex: currentDeptRow));
              cell.value = TextCellValue("$d ($dayName)");
              cell.cellStyle = headerStyle;
            }
            for (int s = 0; s < summaryHeaders.length; s++) {
              var cell = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + daysInMonth + s, rowIndex: currentDeptRow));
              cell.value = TextCellValue(summaryHeaders[s]);
              cell.cellStyle = headerStyle;
            }
            currentDeptRow++;

            double deptTotalPresent = 0.0;
            int deptTotalAbsent = 0;
            double deptTotalFullLeave = 0.0;
            int deptTotalHalfLeave = 0;
            int deptTotalWorkingDays = 0;

            for (var emp in deptEmployees) {
              deptTotalPresent += emp.totalPresent;
              deptTotalAbsent += emp.totalAbsent;
              deptTotalFullLeave += emp.totalFullLeave;
              deptTotalHalfLeave += emp.totalHalfLeave;
              deptTotalWorkingDays += emp.totalWorkingDays;

              var cellId = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentDeptRow));
              cellId.value = TextCellValue(emp.empId == 0 ? (emp.empCode.isNotEmpty ? emp.empCode : '-') : emp.empId.toString());
              cellId.cellStyle = centerDataStyle;

              var cellName = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentDeptRow));
              cellName.value = TextCellValue(emp.fullName);
              cellName.cellStyle = leftDataStyle;

              var cellDesig = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentDeptRow));
              cellDesig.value = TextCellValue(emp.designation);
              cellDesig.cellStyle = leftDataStyle;

              for (int d = 1; d <= daysInMonth; d++) {
                final ds = emp.dailyStatuses[d] ?? DayExcelStatus(day: d, status: '-');
                String codeStr = ds.status;
                CellStyle chosenStyle = centerDataStyle;

                if (ds.status == 'P') {
                  codeStr = 'P';
                  chosenStyle = presentStyle;
                } else if (ds.status == 'A') {
                  codeStr = 'A';
                  chosenStyle = absentStyle;
                } else if (ds.status == 'FL') {
                  codeStr = 'FL';
                  chosenStyle = fullLeaveStyle;
                } else if (ds.status == 'HL') {
                  codeStr = 'HL';
                  chosenStyle = halfLeaveStyle;
                } else if (ds.status == 'H') {
                  codeStr = 'H';
                  chosenStyle = holidayStyle;
                } else if (ds.status == 'WO') {
                  codeStr = 'WO';
                  chosenStyle = weekendStyle;
                } else {
                  codeStr = '-';
                  chosenStyle = centerDataStyle;
                }

                var cellDay = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + d, rowIndex: currentDeptRow));
                cellDay.value = TextCellValue(codeStr);
                cellDay.cellStyle = chosenStyle;
              }

              int sumStartCol = 3 + daysInMonth;

              var cPres = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol, rowIndex: currentDeptRow));
              cPres.value = TextCellValue(_formatNum(emp.totalPresent));
              cPres.cellStyle = summaryNumStyle;

              var cAbs = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 1, rowIndex: currentDeptRow));
              cAbs.value = TextCellValue(emp.totalAbsent.toString());
              cAbs.cellStyle = summaryNumStyle;

              var cFLeave = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 2, rowIndex: currentDeptRow));
              cFLeave.value = TextCellValue(_formatNum(emp.totalFullLeave));
              cFLeave.cellStyle = summaryNumStyle;

              var cHLeave = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 3, rowIndex: currentDeptRow));
              cHLeave.value = TextCellValue(emp.totalHalfLeave.toString());
              cHLeave.cellStyle = summaryNumStyle;

              var cWork = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 4, rowIndex: currentDeptRow));
              cWork.value = TextCellValue(emp.totalWorkingDays.toString());
              cWork.cellStyle = summaryNumStyle;

              var cPerc = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 5, rowIndex: currentDeptRow));
              cPerc.value = TextCellValue("${emp.attendancePercentage.toStringAsFixed(1)}%");
              cPerc.cellStyle = summaryPercentStyle;

              currentDeptRow++;
            }

            var tCellId = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentDeptRow));
            tCellId.value = TextCellValue("Total");
            tCellId.cellStyle = deptTotalLabelStyle;

            var tCellName = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentDeptRow));
            tCellName.value = TextCellValue("Total ($dept)");
            tCellName.cellStyle = deptTotalLabelStyle;

            var tCellDesig = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentDeptRow));
            tCellDesig.value = TextCellValue("-");
            tCellDesig.cellStyle = deptTotalLabelStyle;

            for (int d = 1; d <= daysInMonth; d++) {
              var tCellDay = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + d, rowIndex: currentDeptRow));
              tCellDay.value = TextCellValue("-");
              tCellDay.cellStyle = deptTotalLabelStyle;
            }

            int sumStartCol = 3 + daysInMonth;
            var cTotalPres = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol, rowIndex: currentDeptRow));
            cTotalPres.value = TextCellValue(_formatNum(deptTotalPresent));
            cTotalPres.cellStyle = summaryNumStyle;

            var cTotalAbs = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 1, rowIndex: currentDeptRow));
            cTotalAbs.value = TextCellValue(deptTotalAbsent.toString());
            cTotalAbs.cellStyle = summaryNumStyle;

            var cTotalFLeave = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 2, rowIndex: currentDeptRow));
            cTotalFLeave.value = TextCellValue(_formatNum(deptTotalFullLeave));
            cTotalFLeave.cellStyle = summaryNumStyle;

            var cTotalHLeave = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 3, rowIndex: currentDeptRow));
            cTotalHLeave.value = TextCellValue(deptTotalHalfLeave.toString());
            cTotalHLeave.cellStyle = summaryNumStyle;

            var cTotalWork = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 4, rowIndex: currentDeptRow));
            cTotalWork.value = TextCellValue(deptTotalWorkingDays.toString());
            cTotalWork.cellStyle = summaryNumStyle;

            double deptAvgPerc = deptTotalWorkingDays > 0 ? (deptTotalPresent / deptTotalWorkingDays) * 100.0 : 0.0;
            if (deptAvgPerc > 100.0) deptAvgPerc = 100.0;
            var cTotalPerc = deptSheet.cell(CellIndex.indexByColumnRow(columnIndex: sumStartCol + 5, rowIndex: currentDeptRow));
            cTotalPerc.value = TextCellValue("${deptAvgPerc.toStringAsFixed(1)}%");
            cTotalPerc.cellStyle = summaryPercentStyle;

            currentDeptRow += 2;
          }

          deptSheet.setColumnWidth(0, 16.0); // ID
          deptSheet.setColumnWidth(1, 30.0); // Name
          deptSheet.setColumnWidth(2, 60.0); // Desig

          for (int d = 1; d <= daysInMonth; d++) {
            if (d == 30 || d == 31) {
              deptSheet.setColumnWidth(2 + d, 8.0); // 30th & 31st slightly smaller
            } else {
              deptSheet.setColumnWidth(2 + d, 8.0); // 1st to 29th smaller width
            }
          }
          for (int s = 0; s < summaryHeaders.length; s++) {
            deptSheet.setColumnWidth(3 + daysInMonth + s, 18.0);
          }

          // Save Workbook
          var fileBytes = excel.save();
          if (fileBytes == null) {
            throw Exception("Failed to encode Excel file bytes.");
          }

          Directory? targetDir;
          if (Platform.isAndroid) {
            targetDir = Directory('/storage/emulated/0/Download/TAX HRM 2.0');
          } else if (Platform.isIOS) {
            targetDir = await getApplicationDocumentsDirectory();
          }

          if (targetDir != null && !await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }

          if (targetDir == null) {
            throw Exception("Could not determine storage directory.");
          }

          String baseName = 'Monthly_Attendance_Report_$fileMonthName';
          String fileName = '$baseName.xlsx';
          String filePath = '${targetDir.path}/$fileName';

          bool saved = false;
          int index = 1;
          while (!saved) {
            try {
              final file = File(filePath);
              if (await file.exists()) {
                try {
                  await file.delete();
                } catch (_) {}
              }
              await file.writeAsBytes(fileBytes);
              saved = true;
            } catch (e) {
              
              
              index++;
            }
          }

          dismissLoadingDialog();

          showtoastmessage("Report downloaded to $filePath");
          
        },
      );
    } catch (e) {
      dismissLoadingDialog();
      log("Failed to generate Excel report: $e");
      showtoastmessage("Failed to generate Excel report: $e");
    }
  }

  static void showMonthYearPickerAndGenerate(BuildContext context, {DateTime? initialDate}) {
    final DateTime now = DateTime.now();
    int selectedMonth = initialDate?.month ?? now.month;
    int selectedYear = initialDate?.year ?? now.year;

    final List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final List<int> years = List<int>.generate(21, (i) => (now.year - 10) + i);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ColorConst.themeColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.date_range_rounded, color: ColorConst.themeColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Monthly Excel Report",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Select month and year to generate report",
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Select Year",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<int>(
                        value: selectedYear,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: years.map((int yr) {
                          return DropdownMenuItem<int>(
                            value: yr,
                            child: Text(
                              yr.toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          if (value != null) {
                            setState(() {
                              selectedYear = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Select Month",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<int>(
                        value: selectedMonth,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: List.generate(12, (index) {
                          final int monthNum = index + 1;
                          return DropdownMenuItem<int>(
                            value: monthNum,
                            child: Text(
                              monthNames[index],
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          );
                        }),
                        onChanged: (int? value) {
                          if (value != null) {
                            setState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              try {
                                if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                                  Navigator.pop(dialogContext);
                                }
                              } catch (_) {}
                            },
                            child: const Text("Cancel", style: TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                            label: const Text("Generate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConst.themeColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              try {
                                if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                                  Navigator.pop(dialogContext);
                                }
                              } catch (_) {}
                              final targetMonth = DateTime(selectedYear, selectedMonth, 1);
                              generateAndDownloadReport(context, targetMonth: targetMonth);
                            },
                          ),
                        ),
                      ],
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

  static String _formatNum(double numVal) {
    if (numVal % 1 == 0) return numVal.toInt().toString();
    return numVal.toStringAsFixed(1);
  }
}
