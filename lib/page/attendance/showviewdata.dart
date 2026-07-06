// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:excel/excel.dart' as ex show Border, BorderStyle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/attendance/viewAttendance_screen.dart';
import 'package:tax_hrm/page/attendance/viewimage.dart';
import 'package:tax_hrm/page/usertimelineview/usertimeline.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:url_launcher/url_launcher.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminAttenDanceServices>(context, listen: false).updateMonth(DateTime.now(), context);
    });
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
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProviders = Provider.of<AdminAttenDanceServices>(context);
    Size size = MediaQuery.of(context).size;
    String formattedDate = DateFormat('d MMMM, yyyy').format(attendanceProviders.currentMonth);
    
    // Update filtered list when data changes
    if (_filteredEmployeeList.isEmpty && _searchQuery.isEmpty) {
      _filteredEmployeeList = List.from(attendanceProviders.empAttendanceList);
    }
    
    return RefreshIndicator(
      backgroundColor: ColorConst.white,
      color: ColorConst.themeColor,
      onRefresh: () async {
        // Only refresh current selected data without changing month
        await attendanceProviders.refreshCurrentMonthData(context);
        _clearSearch();
        return;
      },
      child: Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: showBottomAppBar(attendanceString, size, centerTitles: false),
        body: attendanceProviders.isloderings 
            ? attendanceAllEmployeeShimmer(size) 
            : Column(
                children: [
                  _buildHeaderSection(size, attendanceProviders, formattedDate),
                  _buildStatsSection(size, attendanceProviders),
                  _buildExportButton(size),
                  _buildSearchSection(size),
                  _buildEmployeeListSection(size, attendanceProviders),
                ],
              ),
      ),
    );
  }

  Widget _buildExportButton(Size size) {
    return GestureDetector(
      onTap: _downloadExcel,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
        padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
        decoration: BoxDecoration(
          color: ColorConst.themeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ColorConst.themeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_download_outlined, color: Colors.white, size: size.width * 0.05),
            SizedBox(width: size.width * 0.02),
            Text(
              'Export Excel Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: fontInterBoldString,
                fontSize: size.width * 0.035,
              ),
            ),
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

    List<String> headers = ['ID', 'Employee Name', 'Designation', 'Status', 'In Time', 'Out Time'];
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

    for (int i = 0; i < list.length; i++) {
      final employee = list[i];
      final isPresent = employee.inTime != null && employee.absent == false;
      final isOnLeave = employee.isOnLeave == true;
      final isAbsent = employee.absent == true && !isOnLeave;
      
      String status = 'Unknown';
      if (isOnLeave) {
        status = 'On Leave';
      } else if (isPresent) {
        status = 'Present';
      } else if (isAbsent) {
        status = 'Absent';
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
      cell1.cellStyle = cellStyle;

      var cell2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1));
      cell2.value = TextCellValue(designation);
      cell2.cellStyle = cellStyle;

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
        const SnackBar(content: Text('No data available to download')),
      );
      return;
    }

    try {
      var excel = Excel.createExcel();
      String defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheetName, 'Dashboard');

      Sheet dashSheet = excel['Dashboard'];
      Sheet allSheet = excel['All Employees'];
      Sheet presentSheet = excel['Present'];
      Sheet absentSheet = excel['Absent'];
      Sheet leaveSheet = excel['On Leave'];
      
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
      
      var cA1 = dashSheet.cell(CellIndex.indexByString("A1"));
      cA1.value = TextCellValue("Attendance Dashboard");
      cA1.cellStyle = titleStyle;
      dashSheet.merge(CellIndex.indexByString("A1"), CellIndex.indexByString("B1"), customValue: TextCellValue("Attendance Dashboard"));
      
      var cA3 = dashSheet.cell(CellIndex.indexByString("A3"));
      cA3.value = TextCellValue("Date:");
      cA3.cellStyle = dataStyle;
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
      cA6.value = TextCellValue("Total Employees");
      cA6.cellStyle = dataStyle;
      var cB6 = dashSheet.cell(CellIndex.indexByString("B6"));
      cB6.value = TextCellValue('${attendanceProviders.mainHoldEmpList.length}');
      cB6.cellStyle = dataStyle;
      
      var cA7 = dashSheet.cell(CellIndex.indexByString("A7"));
      cA7.value = TextCellValue("Present");
      cA7.cellStyle = dataStyle;
      var cB7 = dashSheet.cell(CellIndex.indexByString("B7"));
      cB7.value = TextCellValue('${attendanceProviders.totalPresents}');
      cB7.cellStyle = dataStyle;
      
      var cA8 = dashSheet.cell(CellIndex.indexByString("A8"));
      cA8.value = TextCellValue("Absent");
      cA8.cellStyle = dataStyle;
      var cB8 = dashSheet.cell(CellIndex.indexByString("B8"));
      cB8.value = TextCellValue('${attendanceProviders.totalAbsent}');
      cB8.cellStyle = dataStyle;
      
      var cA9 = dashSheet.cell(CellIndex.indexByString("A9"));
      cA9.value = TextCellValue("On Leave");
      cA9.cellStyle = dataStyle;
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

      var fileBytes = excel.save();
      if (fileBytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/Attendance_${formattedDate}_$timestamp.xlsx';
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        await Share.shareXFiles([XFile(filePath)], text: 'Attendance Report $formattedDate');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating Excel: $e')),
      );
    }
  }

  // ==================== SEARCH SECTION ====================
  Widget _buildSearchSection(Size size) {
    return Container(
      margin: EdgeInsets.only(left: size.width * 0.04, right: size.width * 0.04, bottom:  size.width * 0.02,),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ColorConst.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CommonTextField(controller: _searchController,prefixIcon:  Padding(
          padding: const EdgeInsets.only(left: 7),
          child: Icon(Icons.search_rounded,size: size.width * 0.05,color: ColorConst.themeColor,),
        ),
        hintText: 'Search by employee name...',
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(onPressed: _clearSearch,icon: Icon(Icons.close_rounded,size: size.width * 0.045,color: Colors.grey.shade400,),)
                : null,
          ), 
      ),
    );
  }

  // ==================== HEADER SECTION ====================
  Widget _buildHeaderSection(Size size, AdminAttenDanceServices attendanceProviders, String formattedDate) {
    final now = DateTime.now();
    final currentMonth = attendanceProviders.currentMonth;
    
    // Check if current selected month is current month (disable next button)
    final isCurrentMonth = currentMonth.year ==now.year && currentMonth.month ==now.month && currentMonth.day ==now.day;
    // Check if can go next (only disable if it's current month)
    final canGoNext = !isCurrentMonth;
    
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: ColorConst.white,
        boxShadow: [
          BoxShadow(color: ColorConst.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              GestureDetector(
                onTap: () {
                  _clearSearch(); // Clear search when changing month
                  attendanceProviders.changeDate(false);
                },
                child: Container(
                  padding: EdgeInsets.all(size.width * 0.02),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConst.themeColor.withOpacity(0.1),
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: size.width * 0.045, color: ColorConst.themeColor),
                ),
              ),
              
              // Date Picker Button
              GestureDetector(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
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
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.008),
                  decoration: BoxDecoration(
                    color: ColorConst.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: size.width * 0.035, color: ColorConst.themeColor),
                      SizedBox(width: size.width * 0.02),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
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
                  padding: EdgeInsets.all(size.width * 0.02),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canGoNext 
                        ? ColorConst.themeColor.withOpacity(0.1) 
                        : Colors.grey.shade100,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: size.width * 0.045,
                    color: canGoNext ? ColorConst.themeColor : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          heightSpacer(size.height * 0.01),
        ],
      ),
    );
  }

  // ==================== STATISTICS SECTION ====================
  Widget _buildStatsSection(Size size, AdminAttenDanceServices attendanceProviders) {
    return Container(
      margin: EdgeInsets.all(size.width * 0.04),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.4,
        children: [
          _buildStatCard(
            size: size,
            title: "Employees",
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
            title: "On Leave",
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.02),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: size.width * 0.045),
                ),
                widthSpacer(size.width * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: size.width * 0.028,
                        color: Colors.grey.shade600,
                        fontFamily: fontInterMediumString,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: fontInterBoldString,
                      ),
                    )
                  ],
                ),
              ],
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
    return Expanded(
      child: Container(
        width: size.width,
        margin: EdgeInsets.all(size.width * 0.01),
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: displayList.isEmpty
            ? _searchQuery.isNotEmpty
                ? _buildNoSearchResults(size)
                : Container(alignment: Alignment.center,child: SingleChildScrollView(child: noDataFoundsDesign(size, 'No Data Found', nodataFoundsImagString, width: size.width * 0.5)))
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: displayList.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  String setPhone = '';
                  Provider.of<EmployeMastServices>(context, listen: false).allemployes.forEach((element) {
                    if (element.id == displayList[index].empId) {
                      setPhone = '${element.mobile1}';
                    }
                  });
                  return _buildEmployeeCard(size, attendanceProviders, index, setPhone, displayList);
                },
              ),
      ),
    );
  }

  // No search results widget
  Widget _buildNoSearchResults(Size size) {
    return Container(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: size.width * 0.12,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              'No employees found',
              style: TextStyle(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontFamily: fontInterSemiBoldString,
              ),
            ),
            SizedBox(height: size.height * 0.005),
            Text(
              'Try searching with different name',
              style: TextStyle(
                fontSize: size.width * 0.03,
                color: Colors.grey.shade400,
                fontFamily: fontInterRegularString,
              ),
            ),
            SizedBox(height: size.height * 0.02),
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.012,
                ),
                decoration: BoxDecoration(
                  color: ColorConst.themeColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConst.themeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Clear Search',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: fontInterSemiBoldString,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Size size, AdminAttenDanceServices attendanceProviders, int index, String setPhone, List displayList) {
    final employee = displayList[index];
    final isPresent = employee.inTime != null && employee.absent == false;
    final isOnLeave = employee.isOnLeave == true;
    final isAbsent = employee.absent == true && !isOnLeave;
    
    return InkWell(
      onTap: () {
        nextScreen(
          context,
          AttendanceScreen(empData: employee),
          onthenValue: (value) => attendanceProviders.updateMonth(DateTime.now(), context),
        );
      },
      child: Container(
        padding: EdgeInsets.all(size.width * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${employee.firstName} ${employee.lastName}',
                        style: TextStyle(
                          fontSize: size.height * 0.018,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontInterBoldString,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_searchQuery.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: size.height * 0.004),
                          child: Text(
                            'ID: ${employee.empId}',
                            style: TextStyle(
                              fontSize: size.width * 0.025,
                              color: ColorConst.themeColor.withOpacity(0.7),
                              fontFamily: fontInterRegularString,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      onTap: () {
                        nextScreen(
                          context,
                          EmployeTimelines(userId: employee.empId.toString()),
                          onthenValue: (value) {},
                        );
                      },
                      size: size,
                      icon: Icons.timeline,
                      color: ColorConst.themeColor,
                    ),
                    SizedBox(width: size.width * 0.01),
                    _buildActionButton(
                      onTap: () async {
                        var url = 'https://Wa.me/$setPhone';
                        await launch(url);
                      },
                      size: size,
                      isImage: true,
                      image: whatsappImgString,
                    ),
                  ],
                ),
              ],
            ),
            heightSpacer(size.height * 0.01),
            
            Row(
              children: [
                if (!isOnLeave)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: size.width * 0.012, horizontal: size.width * 0.025),
                    decoration: BoxDecoration(
                      border: Border.all(color: isPresent ? ColorConst.greenColor : ColorConst.grey),
                      color: isPresent ? ColorConst.greenColor : ColorConst.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPresent ? Icons.check_circle : Icons.help_outline,
                          size: size.width * 0.035,
                          color: isPresent ? Colors.white : ColorConst.grey,
                        ),
                        SizedBox(width: size.width * 0.01),
                        Text(
                          presentString,
                          style: TextStyle(
                            color: isPresent ? Colors.white : ColorConst.grey,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontInterSemiBoldString,
                            fontSize: size.width * 0.028,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(vertical: size.width * 0.012, horizontal: size.width * 0.025),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorConst.paidLeaveColor),
                      color: ColorConst.paidLeaveColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.beach_access, size: size.width * 0.035, color: Colors.white),
                        SizedBox(width: size.width * 0.01),
                        Text(
                          onLeaveString,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontInterSemiBoldString,
                            fontSize: size.width * 0.028,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(width: size.width * 0.02),
                
                if (!isOnLeave)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: size.width * 0.012, horizontal: size.width * 0.025),
                    decoration: BoxDecoration(
                      color: isAbsent ? ColorConst.red : ColorConst.white,
                      border: Border.all(color: isAbsent ? ColorConst.red : ColorConst.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel,
                          size: size.width * 0.035,
                          color: isAbsent ? Colors.white : ColorConst.grey,
                        ),
                        SizedBox(width: size.width * 0.01),
                        Text(
                          absentString,
                          style: TextStyle(
                            color: isAbsent ? Colors.white : ColorConst.grey,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontInterSemiBoldString,
                            fontSize: size.width * 0.028,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                _buildPunchButton(size, attendanceProviders, employee, index, displayList),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required Size size,
    IconData? icon,
    bool isImage = false,
    String? image,
    Color color = Colors.white,
  }) {
    if (isImage && image != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(size.width * 0.02),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(image, height: size.width * 0.04, width: size.width * 0.04),
        ),
      );
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.02),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: size.width * 0.04, color: color),
      ),
    );
  }

  Widget _buildPunchButton(Size size, AdminAttenDanceServices attendanceProviders, dynamic employee, int index, List displayList) {
    return GestureDetector(
      onTap: () {
        attendanceProviders.punchInTimeController.text = employee.inTime == null 
            ? punchInTimeString 
            : DateFormat('hh:mm a').format(DateTime.parse(employee.inTime.toString()));
        attendanceProviders.punchOutTimeController.text = employee.outTime == null 
            ? punchOutTimeString 
            : DateFormat('hh:mm a').format(DateTime.parse(employee.outTime.toString()));
        
        _showAttendanceBottomSheet(context, size, attendanceProviders, index, displayList);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.025, vertical: size.height * 0.008),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorConst.themeColor, ColorConst.themeColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorConst.themeColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: size.width * 0.035, color: Colors.white),
            SizedBox(width: size.width * 0.01),
            Text(
              punchTimeString,
              style: TextStyle(
                fontSize: size.width * 0.026,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: fontInterSemiBoldString,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ATTENDANCE BOTTOM SHEET ====================
  void _showAttendanceBottomSheet(BuildContext context, Size size, AdminAttenDanceServices attendanceProviders, int index, List displayList) {
    final currentDate = attendanceProviders.currentMonth;
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(currentDate);
    final dayName = DateFormat('EEEE').format(currentDate);
    final dayNumber = DateFormat('d').format(currentDate);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                height: size.height * 0.52,
                decoration: BoxDecoration(
                  color: ColorConst.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: size.height * 0.012),
                      width: size.width * 0.15,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.fromLTRB(size.width * 0.05, size.height * 0.02, size.width * 0.05, size.height * 0.01),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(size.width * 0.03),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [ColorConst.themeColor, ColorConst.themeColor.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConst.themeColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  dayNumber,
                                  style: TextStyle(
                                    fontSize: size.width * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: fontInterBoldString,
                                  ),
                                ),
                                Text(
                                  dayName.substring(0, 3),
                                  style: TextStyle(
                                    fontSize: size.width * 0.03,
                                    color: Colors.white70,
                                    fontFamily: fontInterMediumString,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: size.width * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${displayList[index].firstName} ${displayList[index].lastName}',
                                  style: TextStyle(
                                    fontSize: size.width * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConst.black,
                                    fontFamily: fontInterBoldString,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: size.height * 0.004),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: size.width * 0.03,
                                    color: Colors.grey.shade600,
                                    fontFamily: fontInterRegularString,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(size.width * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                size: size.width * 0.045,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      height: 1,
                      margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      color: Colors.grey.shade200,
                    ),
                    
                    SizedBox(height: size.height * 0.02),
                    
                    buildPunchCard(
                      size: size,
                      title: 'PUNCH IN',
                      time: attendanceProviders.punchInTimeController.text,
                      icon: Icons.login_rounded,
                      color: Colors.green,
                      gradientStart: const Color(0xFF00B4DB),
                      gradientEnd: const Color(0xFF0083B0),
                      status: displayList[index].inTime != null ? 'Completed' : 'Pending',
                      onTap: () async {
                        if (displayList[index].inTime == null) {
                          await attendanceProviders.showTimePickerDialog(
                            context: context,
                            title: punchInString,
                            isPunchIn: true,
                            attendanceProviders: attendanceProviders,
                            empId: displayList[index].empId!.toInt(),
                            attendanceId: null,
                            currentMonth: currentDate,
                          );
                          setSheetState(() {});
                          // Refresh data after punch in
                          setState(() {
                            _filterEmployees();
                          });
                        }
                      },
                      isCompleted: displayList[index].inTime != null,
                    ),
                    
                    SizedBox(height: size.height * 0.015),
                    
                    buildPunchCard(
                      size: size,
                      title: 'PUNCH OUT',
                      time: attendanceProviders.punchOutTimeController.text,
                      icon: Icons.logout_rounded,
                      color: Colors.red,
                      gradientStart: const Color(0xFFFA709A),
                      gradientEnd: const Color(0xFFFEE140),
                      status: displayList[index].outTime != null ? 'Completed' : 'Pending',
                      onTap: () async {
                        if (displayList[index].inTime != null && 
                            displayList[index].outTime == null) {
                          await attendanceProviders.showTimePickerDialog(
                            context: context,
                            title: punchOutString,
                            isPunchIn: false,
                            attendanceProviders: attendanceProviders,
                            empId: displayList[index].empId!.toInt(),
                            attendanceId: displayList[index].attendenceID,
                            currentMonth: currentDate,
                          );
                          setSheetState(() {});
                          // Refresh data after punch out
                          setState(() {
                            _filterEmployees();
                          });
                        }
                      },
                      isCompleted: displayList[index].outTime != null,
                    ),
                    
                    const Spacer(),
                    
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      padding: EdgeInsets.all(size.width * 0.03),
                      decoration: BoxDecoration(
                        color: ColorConst.themeColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ColorConst.themeColor.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: size.width * 0.04, color: ColorConst.themeColor),
                          SizedBox(width: size.width * 0.02),
                          Expanded(
                            child: Text(
                              'Punch in before 10:00 AM to avoid late marking',
                              style: TextStyle(
                                fontSize: size.width * 0.028,
                                color: Colors.grey.shade700,
                                fontFamily: fontInterRegularString,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}