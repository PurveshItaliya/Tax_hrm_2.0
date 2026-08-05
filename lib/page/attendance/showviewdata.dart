// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:excel/excel.dart' as ex show Border, BorderStyle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/attendance/viewAttendance_screen.dart';
import 'package:tax_hrm/page/usertimelineview/usertimeline.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/page/employee_master/pdf_csv_print_function.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:tax_hrm/page/attendance/monthly_attendance_excel_service.dart';

class ShowAttenDanceEmployeData extends StatefulWidget {
  const ShowAttenDanceEmployeData({super.key});

  @override
  State<ShowAttenDanceEmployeData> createState() => _ShowAttenDanceEmployeDataState();
}

class _ShowAttenDanceEmployeDataState extends State<ShowAttenDanceEmployeData> {
  // Search Controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _filteredEmployeeList = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AdminAttenDanceServices>(context, listen: false);
    
    // Check if data is already cached for today
    bool hasDataForToday = provider.empAttendanceList.isNotEmpty &&
        provider.currentMonth.year == DateTime.now().year &&
        provider.currentMonth.month == DateTime.now().month &&
        provider.currentMonth.day == DateTime.now().day;

    if (!hasDataForToday) {
      // Set loading true synchronously so the first frame shows the shimmer instead of "No Data Found"
      provider.islodering = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.updateMonth(DateTime.now(), context);
      });
    }
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterEmployees();
    });
  }

  void _filterEmployees() {
    final attendanceProviders = Provider.of<AdminAttenDanceServices>(context, listen: false);
    if (_searchQuery.isEmpty) {
      _filteredEmployeeList = List.from(attendanceProviders.empAttendanceList);
    } else {
      _filteredEmployeeList = attendanceProviders.empAttendanceList.where((employee) {
        final fullName = '${employee.firstName} ${employee.lastName}'.toLowerCase();
        final firstName = employee.firstName?.toLowerCase() ?? '';
        final lastName = employee.lastName?.toLowerCase() ?? '';
        return fullName.contains(_searchQuery) || 
               firstName.contains(_searchQuery) || 
               lastName.contains(_searchQuery);
      }).toList();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredEmployeeList = [];
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProviders = Provider.of<AdminAttenDanceServices>(context);
    Provider.of<LanguageProvider>(context);
    Size size = MediaQuery.of(context).size;
    String formattedDate = DateFormat('d MMMM, yyyy').format(attendanceProviders.currentMonth);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Update filtered list when data changes
    if (_filteredEmployeeList.isEmpty && _searchQuery.isEmpty) {
      _filteredEmployeeList = List.from(attendanceProviders.empAttendanceList);
    }
    
    return RefreshIndicator(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : ColorConst.white,
      color: ColorConst.themeColor,
      onRefresh: () async {
        // Only refresh current selected data without changing month
        await attendanceProviders.refreshCurrentMonthData(context);
        _clearSearch();
        return;
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : ColorConst.scaffoldColor,
          appBar: showBottomAppBar(attendanceString, size, centerTitles: false),
        body: attendanceProviders.isloderings 
            ? attendanceAllEmployeeShimmer(size) 
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: size.height * 0.12),
                child: Column(
                  children: [
                    _buildHeaderSection(size, attendanceProviders, formattedDate),
                    _buildStatsSection(size, attendanceProviders),
                    _buildSearchSection(size),
                    _buildEmployeeListSection(size, attendanceProviders),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'daily') {
          _downloadExcel();
        } else if (value == 'monthly') {
          final attendanceProviders = Provider.of<AdminAttenDanceServices>(context, listen: false);
          MonthlyAttendanceExcelService.showMonthYearPickerAndGenerate(context, initialDate: attendanceProviders.currentMonth);
        }
      },
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'daily',
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: Colors.blue),
              SizedBox(width: 10),
              Text(todayAttendanceReportString, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'monthly',
          child: Row(
            children: [
              Icon(Icons.date_range_rounded, size: 18, color: Colors.green),
              SizedBox(width: 10),
              Text(monthlyExcelReportString, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ColorConst.themeColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: ColorConst.themeColor.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              exportString,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: fontInterMediumString,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );  
  }

  void _populateEmployeeSheet(Sheet sheet, List<dynamic> list, List<dynamic> allEmployees, CellStyle headerStyle) {
    sheet.setColumnWidth(0, 10.0);
    sheet.setColumnWidth(1, 25.0);
    sheet.setColumnWidth(2, 30.0); // Designation
    sheet.setColumnWidth(3, 15.0); // Status
    sheet.setColumnWidth(4, 15.0); // In Time
    sheet.setColumnWidth(5, 15.0); // Out Time

    List<String> headers = [idString, employessNameString, designationString, statusString, inTimeString, outTimeString];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    CellStyle cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    CellStyle leftAlignCellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    for (int i = 0; i < list.length; i++) {
      final employee = list[i];
      final isPresent = employee.inTime != null && employee.absent == false;
      final isOnLeave = employee.isOnLeave == true;
      final isAbsent = employee.absent == true && !isOnLeave;
      
      String status = 'Unknown';
      if (isOnLeave) {
        status = onLeaveString;
      } else if (isPresent) {
        status = presentString;
      } else if (isAbsent) {
        status = absentString;
      }

      String inTimeStr = employee.inTime == null 
          ? '-' 
          : DateFormat('hh:mm a').format(DateTime.parse(employee.inTime.toString()));
      String outTimeStr = employee.outTime == null 
          ? '-' 
          : DateFormat('hh:mm a').format(DateTime.parse(employee.outTime.toString()));

      String designation = '-';
      for (var emp in allEmployees) {
        if (emp.id == employee.empId) {
          designation = emp.positionName ?? '';
          if (designation.trim().isEmpty) {
             designation = emp.departmentName ?? '-';
          }
          if (designation.trim().isEmpty) {
             designation = '-';
          }
          break;
        }
      }

      var cell0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1));
      cell0.value = TextCellValue(employee.empId.toString());
      cell0.cellStyle = cellStyle;

      var cell1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1));
      cell1.value = TextCellValue('${employee.firstName} ${employee.lastName}');
      cell1.cellStyle = leftAlignCellStyle;

      var cell2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1));
      cell2.value = TextCellValue(designation);
      cell2.cellStyle = leftAlignCellStyle;

      var cell3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1));
      cell3.value = TextCellValue(status);
      cell3.cellStyle = cellStyle;

      var cell4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1));
      cell4.value = TextCellValue(inTimeStr);
      cell4.cellStyle = cellStyle;

      var cell5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1));
      cell5.value = TextCellValue(outTimeStr);
      cell5.cellStyle = cellStyle;
    }
  }

  Future<void> _downloadExcel() async {
    final attendanceProviders = Provider.of<AdminAttenDanceServices>(context, listen: false);
    final empMastProviders = Provider.of<EmployeMastServices>(context, listen: false);
    final displayList = attendanceProviders.empAttendanceList;
    List<dynamic> allEmpList = empMastProviders.mainEmployeList;
    if (allEmpList.isEmpty) allEmpList = empMastProviders.emplists;
    if (allEmpList.isEmpty) allEmpList = empMastProviders.allemployes;
    final currentDate = attendanceProviders.currentMonth;
    final formattedDate = DateFormat('dd-MMM-yyyy').format(currentDate);

    if (displayList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(noDataAvailableToDownloadString)),
      );
      return;
    }

    try {
      var excel = Excel.createExcel();
      String defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheetName, 'Dashboard');

      Sheet dashSheet = excel['Dashboard'];
      Sheet allSheet = excel[allEmployeesString];
      Sheet presentSheet = excel['Present'];
      Sheet absentSheet = excel['Absent'];
      Sheet leaveSheet = excel['On Leave'];
      Sheet designationSheet = excel['Designation Wise'];
      
      excel.setDefaultSheet('Dashboard');

      // Dashboard Sheet Formatting
      dashSheet.setColumnWidth(0, 20.0);
      dashSheet.setColumnWidth(1, 15.0);

      CellStyle titleStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1D976C'),
      );

      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#333333'),
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      );

      CellStyle dataStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      );

      CellStyle leftAlignDataStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Left,
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      );
      
      var cA1 = dashSheet.cell(CellIndex.indexByString("A1"));
      cA1.value = TextCellValue("Attendance Dashboard");
      cA1.cellStyle = titleStyle;
      dashSheet.merge(CellIndex.indexByString("A1"), CellIndex.indexByString("B1"), customValue: TextCellValue("Attendance Dashboard"));
      
      var cA3 = dashSheet.cell(CellIndex.indexByString("A3"));
      cA3.value = TextCellValue("Date:");
      cA3.cellStyle = leftAlignDataStyle;
      var cB3 = dashSheet.cell(CellIndex.indexByString("B3"));
      cB3.value = TextCellValue(formattedDate);
      cB3.cellStyle = dataStyle;
      
      var cA5 = dashSheet.cell(CellIndex.indexByString("A5"));
      cA5.value = TextCellValue("Metric");
      cA5.cellStyle = headerStyle;
      var cB5 = dashSheet.cell(CellIndex.indexByString("B5"));
      cB5.value = TextCellValue("Count");
      cB5.cellStyle = headerStyle;
      
      var cA6 = dashSheet.cell(CellIndex.indexByString("A6"));
      cA6.value = TextCellValue(totalEmployeesString);
      cA6.cellStyle = leftAlignDataStyle;
      var cB6 = dashSheet.cell(CellIndex.indexByString("B6"));
      cB6.value = TextCellValue('${attendanceProviders.mainHoldEmpList.length}');
      cB6.cellStyle = dataStyle;
      
      var cA7 = dashSheet.cell(CellIndex.indexByString("A7"));
      cA7.value = TextCellValue("Present");
      cA7.cellStyle = leftAlignDataStyle;
      var cB7 = dashSheet.cell(CellIndex.indexByString("B7"));
      cB7.value = TextCellValue('${attendanceProviders.totalPresents}');
      cB7.cellStyle = dataStyle;
      
      var cA8 = dashSheet.cell(CellIndex.indexByString("A8"));
      cA8.value = TextCellValue("Absent");
      cA8.cellStyle = leftAlignDataStyle;
      var cB8 = dashSheet.cell(CellIndex.indexByString("B8"));
      cB8.value = TextCellValue('${attendanceProviders.totalAbsent}');
      cB8.cellStyle = dataStyle;
      
      var cA9 = dashSheet.cell(CellIndex.indexByString("A9"));
      cA9.value = TextCellValue("On Leave");
      cA9.cellStyle = leftAlignDataStyle;
      var cB9 = dashSheet.cell(CellIndex.indexByString("B9"));
      cB9.value = TextCellValue('${attendanceProviders.totalIsOnLeave}');
      cB9.cellStyle = dataStyle;

      // Separate Data by Category
      List<dynamic> presentList = [];
      List<dynamic> absentList = [];
      List<dynamic> leaveList = [];

      for (var emp in displayList) {
        if (emp.isOnLeave == true) {
          leaveList.add(emp);
        } else if (emp.inTime != null && emp.absent == false) {
          presentList.add(emp);
        } else {
          absentList.add(emp);
        }
      }

      // Populate Sheets
      _populateEmployeeSheet(allSheet, displayList, allEmpList, headerStyle);
      _populateEmployeeSheet(presentSheet, presentList, allEmpList, headerStyle);
      _populateEmployeeSheet(absentSheet, absentList, allEmpList, headerStyle);
      _populateEmployeeSheet(leaveSheet, leaveList, allEmpList, headerStyle);

      // Populate Designation Wise Sheet (Separate tables for each designation)
      designationSheet.setColumnWidth(0, 10.0); // ID
      designationSheet.setColumnWidth(1, 25.0); // Employee Name
      designationSheet.setColumnWidth(2, 15.0); // Status
      designationSheet.setColumnWidth(3, 15.0); // In Time
      designationSheet.setColumnWidth(4, 15.0); // Out Time

      CellStyle designationHeaderStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1D976C'),
      );

      // Group displayList by designation
      Map<String, List<dynamic>> designationGroups = {};
      for (var empAttendance in displayList) {
        String designation = '-';
        for (var emp in allEmpList) {
          if (emp.id == empAttendance.empId) {
            designation = emp.positionName ?? '';
            if (designation.trim().isEmpty) {
              designation = emp.departmentName ?? '-';
            }
            if (designation.trim().isEmpty) {
              designation = '-';
            }
            break;
          }
        }
        if (!designationGroups.containsKey(designation)) {
          designationGroups[designation] = [];
        }
        designationGroups[designation]!.add(empAttendance);
      }

      int currentRow = 0;
      designationGroups.forEach((designation, list) {
        // Designation Title Header
        var headerCell = designationSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        headerCell.value = TextCellValue("Designation: $designation");
        headerCell.cellStyle = designationHeaderStyle;
        designationSheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
          customValue: TextCellValue("Designation: $designation"),
        );
        currentRow++;

        // Table Column Headers
        List<String> subHeaders = [idString, employessNameString, statusString, inTimeString, outTimeString];
        for (int i = 0; i < subHeaders.length; i++) {
          var cell = designationSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
          cell.value = TextCellValue(subHeaders[i]);
          cell.cellStyle = headerStyle;
        }
        currentRow++;

        // Table Rows
        for (var employee in list) {
          final isPresent = employee.inTime != null && employee.absent == false;
          final isOnLeave = employee.isOnLeave == true;
          final isAbsent = employee.absent == true && !isOnLeave;
          
          String status = 'Unknown';
          if (isOnLeave) {
            status = onLeaveString;
          } else if (isPresent) {
            status = presentString;
          } else if (isAbsent) {
            status = absentString;
          }

          String inTimeStr = employee.inTime == null 
              ? '-' 
              : DateFormat('hh:mm a').format(DateTime.parse(employee.inTime.toString()));
          String outTimeStr = employee.outTime == null 
              ? '-' 
              : DateFormat('hh:mm a').format(DateTime.parse(employee.outTime.toString()));

          var cell0 = designationSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
          cell0.value = TextCellValue(employee.empId.toString());
          cell0.cellStyle = dataStyle;

          var cell1 = designationSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
          cell1.value = TextCellValue('${employee.firstName} ${employee.lastName}');
          cell1.cellStyle = leftAlignDataStyle;

          var cell2 = designationSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
          cell2.value = TextCellValue(status);
          cell2.cellStyle = dataStyle;

          var cell3 = designationSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
          cell3.value = TextCellValue(inTimeStr);
          cell3.cellStyle = dataStyle;

          var cell4 = designationSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
          cell4.value = TextCellValue(outTimeStr);
          cell4.cellStyle = dataStyle;

          currentRow++;
        }

        // Space between tables
        currentRow += 2;
      });

      var fileBytes = excel.save();
      if (fileBytes != null) {
        Directory? externalDir;
        if (Platform.isAndroid) {
          bool permission = await requestStoragePermission();
          if (!permission) {
            showtoastmessage("Storage permission required to download Excel");
            return;
          }
          externalDir = Directory('/storage/emulated/0/Download/TAX HRM 2.0');
        } else if (Platform.isIOS) {
          externalDir = await getApplicationDocumentsDirectory();
        }

        if (externalDir != null) {
          if (!await externalDir.exists()) {
            await externalDir.create(recursive: true);
          }
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '${externalDir.path}/Attendance_${formattedDate}_$timestamp.xlsx';
          File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          showtoastmessage('Excel Downloaded Successfully! Saved in Download/TAX HRM 2.0');
        }
      }
    } catch (e) {
      showtoastmessage('Failed to download Excel. Please try again.');
    }
  }

  // ==================== SEARCH SECTION ====================
  Widget _buildSearchSection(Size size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.transparent : Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                cursorColor: ColorConst.black,
                style: TextStyle(
                  color: ColorConst.black,
                  fontFamily: fontInterRegularString,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: searchEmployeeHintString,
                  isDense: true,
                  hintStyle: TextStyle(
                    color: ColorConst.hintextColor,
                    fontFamily: fontInterMediumString,
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 6),
                    child: Icon(Icons.search_rounded, size: 18, color: ColorConst.themeColor),
                  ),
                  prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _clearSearch,
                          icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
                ),
              ), 
            ),
          ),
          const SizedBox(width: 8),
          _buildExportButton(),
        ],
      ),
    );
  }

  // ==================== HEADER SECTION ====================
  Widget _buildHeaderSection(Size size, AdminAttenDanceServices attendanceProviders, String formattedDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final currentMonth = attendanceProviders.currentMonth;
    
    // Check if current selected month is current month (disable next button)
    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month && currentMonth.day == now.day;
    // Check if can go next (only disable if it's current month)
    final canGoNext = !isCurrentMonth;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          GestureDetector(
            onTap: () {
              _clearSearch(); // Clear search when changing month
              attendanceProviders.changeDate(false);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConst.themeColor.withOpacity(0.1),
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 14, color: ColorConst.themeColor),
            ),
          ),
          
          // Date Picker Button
          GestureDetector(
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                locale: Locale(LanguageProvider.currentLanguageCode),
                initialDate: attendanceProviders.currentMonth,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                selectableDayPredicate: (day) => day.weekday != DateTime.sunday,
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(
                        primary: ColorConst.themeColor,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      dialogBackgroundColor: ColorConst.white,
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                _clearSearch(); // Clear search when changing date
                attendanceProviders.updateMonth(pickedDate, context);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: ColorConst.themeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColorConst.themeColor.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 13, color: ColorConst.themeColor),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorConst.themeColor,
                      fontFamily: fontInterSemiBoldString,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Next Button - Disabled for current month
          GestureDetector(
            onTap: canGoNext ? () {
              _clearSearch(); // Clear search when changing month
              attendanceProviders.changeDate(true);
            } : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canGoNext 
                    ? ColorConst.themeColor.withOpacity(0.1) 
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                size: 14,
                color: canGoNext ? ColorConst.themeColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATISTICS SECTION ====================
  Widget _buildStatsSection(Size size, AdminAttenDanceServices attendanceProviders) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5,
        children: [
          _buildStatCard(
            size: size,
            title: employeesString,
            value: '${attendanceProviders.mainHoldEmpList.length}',
            color: ColorConst.blueColor,
            icon: Icons.people_alt,
            onTap: () {
              _clearSearch(); // Clear search when filtering
              attendanceProviders.setEmpAttendanceList(attendanceProviders.mainHoldEmpList);
            },
          ),
          _buildStatCard(
            size: size,
            title: presentString,
            value: attendanceProviders.totalPresents.toString(),
            color: ColorConst.greenColor,
            icon: Icons.check_circle,
            onTap: () {
              _clearSearch(); // Clear search when filtering
              attendanceProviders.filtersOntapData(true);
            },
          ),
          _buildStatCard(
            size: size,
            title: absentString,
            value: attendanceProviders.totalAbsent.toString(),
            color: ColorConst.red,
            icon: Icons.cancel,
            onTap: () {
              _clearSearch(); // Clear search when filtering
              attendanceProviders.filtersOntapData(false);
            },
          ),
          _buildStatCard(
            size: size,
            title: onLeaveString,
            value: attendanceProviders.totalIsOnLeave.toString(),
            color: ColorConst.paidLeaveColor,
            icon: Icons.beach_access,
            onTap: () {
              _clearSearch(); // Clear search when filtering
              attendanceProviders.filterIsONleave();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required Size size,
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.transparent : color.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: isDark ? Colors.grey.shade800 : color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontFamily: fontInterMediumString,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: fontInterBoldString,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPLOYEE LIST SECTION ====================
  Widget _buildEmployeeListSection(Size size, AdminAttenDanceServices attendanceProviders) {
    // Use filtered list if search is active, otherwise use original list
    final displayList = _searchQuery.isNotEmpty ? _filteredEmployeeList : attendanceProviders.empAttendanceList;
    return displayList.isEmpty
        ? _searchQuery.isNotEmpty
            ? _buildNoSearchResults()
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: noDataFoundsDesign(size, noDataFoundsString, nodataFoundsImagString, width: 140.0),
              )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: displayList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              String setPhone = '';
              Provider.of<EmployeMastServices>(context, listen: false).allemployes.forEach((element) {
                if (element.id == displayList[index].empId) {
                  setPhone = '${element.mobile1}';
                }
              });
              return _buildEmployeeCard(size, attendanceProviders, index, setPhone, displayList);
            },
          );
  }

  Widget _buildNoSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            noEmployeesFoundString,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              fontFamily: fontInterSemiBoldString,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trySearchingWithDifferentNameString,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              fontFamily: fontInterRegularString,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _clearSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ColorConst.themeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ColorConst.themeColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                clearSearchString,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: fontInterSemiBoldString,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Size size, AdminAttenDanceServices attendanceProviders, int index, String setPhone, List displayList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employee = displayList[index];
    final isPresent = employee.inTime != null && employee.absent == false;
    final isOnLeave = employee.isOnLeave == true;
    final isAbsent = employee.absent == true && !isOnLeave;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          nextScreen(
            context,
            AttendanceScreen(empData: employee),
            onthenValue: (value) => attendanceProviders.updateMonth(DateTime.now(), context),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorConst.themeColor.withOpacity(0.8), ColorConst.themeColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ColorConst.themeColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${employee.firstName?[0] ?? ''}${employee.lastName?[0] ?? ''}'.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${employee.firstName} ${employee.lastName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: fontInterBoldString,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'ID: ${employee.empId}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontFamily: fontInterMediumString,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(
                      isOnLeave: isOnLeave,
                      isPresent: isPresent,
                      isAbsent: isAbsent,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSmallActionButton(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      nextScreen(
                        context,
                        EmployeTimelines(userId: employee.empId.toString()),
                        onthenValue: (value) {},
                      );
                    },
                    icon: Icons.history_rounded,
                    color: ColorConst.themeColor,
                    isDark: isDark,
                    tooltip: 'View Timeline',
                  ),
                  const SizedBox(width: 6),
                  _buildSmallActionButton(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      var url = 'https://Wa.me/$setPhone';
                      await launch(url);
                    },
                    isImage: true,
                    image: whatsappImgString,
                    color: ColorConst.greenColor,
                    isDark: isDark,
                    tooltip: 'WhatsApp Message',
                  ),
                  const SizedBox(width: 6),
                  _buildSmallActionButton(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      await Future.delayed(const Duration(milliseconds: 150));
                      final attendanceEmp = Provider.of<AttendanceEmp>(context, listen: false);
                      String timestampString = attendanceProviders.currentMonth.toString();
                      String formattedTimestampString = timestampString.replaceAll('Z', '');
                      
                      await attendanceEmp.getDateBloges(formattedTimestampString, employee.empId.toString());
                      
                      if (context.mounted) {
                         showDayDetails(
                           context,
                           size,
                           attendanceEmp.selectedDateLog,
                           timestampString,
                           1,
                           attendanceEmp,
                           attendanceProviders,
                           curentUser,
                           employee,
                         );
                      }
                    },
                    isImage: true,
                    image: punchHistoryImgString,
                    color: ColorConst.blueColor,
                    imageColor: isDark ? Colors.white : ColorConst.blueColor,
                    isDark: isDark,
                    tooltip: 'Day Attendance Log',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isOnLeave,
    required bool isPresent,
    required bool isAbsent,
    required bool isDark,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String text;

    if (isOnLeave) {
      bgColor = ColorConst.paidLeaveColor.withOpacity(0.1);
      borderColor = ColorConst.paidLeaveColor.withOpacity(0.5);
      textColor = ColorConst.paidLeaveColor;
      icon = Icons.beach_access_rounded;
      text = onLeaveString;
    } else if (isPresent) {
      bgColor = ColorConst.greenColor.withOpacity(0.1);
      borderColor = ColorConst.greenColor.withOpacity(0.5);
      textColor = ColorConst.greenColor;
      icon = Icons.check_circle_rounded;
      text = presentString;
    } else if (isAbsent) {
      bgColor = ColorConst.red.withOpacity(0.1);
      borderColor = ColorConst.red.withOpacity(0.5);
      textColor = ColorConst.red;
      icon = Icons.cancel_rounded;
      text = absentString;
    } else {
      bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
      borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
      textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      icon = Icons.help_outline_rounded;
      text = pendingString;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontFamily: fontInterSemiBoldString,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required VoidCallback onTap,
    IconData? icon,
    bool isImage = false,
    String? image,
    Color color = Colors.white,
    bool isDark = false,
    String? tooltip,
    Color? imageColor,
  }) {
    Color btnColor = color == Colors.white && isImage ? ColorConst.greenColor : color;
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: btnColor.withOpacity(isDark ? 0.2 : 0.1),
            border: Border.all(color: btnColor.withOpacity(isDark ? 0.5 : 0.4), width: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: (isImage || image != null) && image != null
              ? Image.asset(image, height: 19, width: 19, color: imageColor)
              : Icon(icon, size: 19, color: isDark ? Colors.white : btnColor),
        ),
      ),
    );
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }




}