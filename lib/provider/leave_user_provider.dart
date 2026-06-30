// ignore_for_file: use_build_context_synchronously, strict_top_level_inference, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/leaveapi.dart';
import 'package:tax_hrm/api/leavesapi.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/models/leavetype/getuserList.dart';
import 'package:tax_hrm/page/bottom_bar_screen.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class LeaveUserProvider extends ChangeNotifier {
  // ==================== LOADING STATES ====================
  bool islodering = false;
  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  // ==================== EDIT MODE ====================
  bool isEditMode = false;
  String? editingLeaveCguid;
  int? editingLeaveId;
  int? editingLeaveEmpId;

  // ==================== FORM CONTROLLERS ====================
  TextEditingController txtLeaveStartDate = TextEditingController();
  TextEditingController txtLeaveEndDate = TextEditingController();
  TextEditingController txtReason = TextEditingController();

  // ==================== DATE VARIABLES ====================
  DateTime selectedFromDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();

  // ==================== LEAVE TYPE SELECTION ====================
  int selectedIndex = 0;
  final List<String> leaveType = ["Full Day", "1st Half", "2nd Half"];
  
  bool get isFullDay => selectedIndex == 0;
  bool get isFirstHalf => selectedIndex == 1;
  bool get isSecondHalf => selectedIndex == 2;
  
  String get selectedLeaveDuration => leaveType[selectedIndex];
  String get selectedDayType {
    if (isFullDay) return 'Full Day';
    if (isFirstHalf) return 'First Half';
    return 'Second Half';
  }

  // ==================== LEAVE TYPES FROM API ====================
  List<GetLeaveMaster> leaveTypeList = [];
  GetLeaveMaster? selectedLeaveTypeData;
  GetLeaveMaster? leaveTypeData;
  String? selectedLeaveTypeName;
  GetLeaveMaster? slTypeData;

  Employeelists? selectedEmployee;
  
  // Getters
  Employeelists? get getSelectedEmployee => selectedEmployee;

  String? selectedLeaveStatusName;
  List<GetLeaveStatus> leaveStatusList = [
    GetLeaveStatus('P', 'Pending'),
    GetLeaveStatus('A', 'Approved'),
    GetLeaveStatus('R', 'Reject'),
  ];

  // ==================== LEAVE COUNTING ====================
  String showGainCounting = '0';
  String showUsedCounting = '0';
  String showEligibleCounting = '0';

  String showPaidLeaves = '0';
  String showTotalGainPaidLeaves = '0';

  // ==================== USER LEAVES ====================
  List<LeaveListData> userLeaves = [];

  // ==================== FORM VALIDATION ====================
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  // ==================== LEAVE TYPE BUTTON ====================
  void leaveTypeButtonFunction(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  // ==================== LOAD LEAVE TYPES FROM API ====================
  Future<void> loadLeaveTypes() async {
    try {
      final result = await LeaveMasterApiService().getLeaveMlist();
      leaveTypeList = result;
      setPaidLeaveTypeData();
      notifyListeners();
    } catch (e) { /* ignored */ }
  }

  // ==================== LOAD USER LEAVES ====================
  Future<void> loadUserLeaves() async {
    try {
      final result = await LeaveApiService().userLeaveList();
      userLeaves = result;
      notifyListeners();
    } catch (e) { /* ignored */ }
  }

  // ==================== LOAD PAID LEAVE SUMMARY ====================
  Future<void> loadPaidLeaveSummary() async {
    try {
      await loadLeaveTypes();
      await loadUserLeaves();
      _calculatePaidLeaveSummary();
    } catch (e) { /* ignored */ }
  }

  // ==================== LOAD LEAVE DATA ====================
  Future<void> loadLeaveData(context,{bool isEdit = false, dynamic leaveData}) async {
    try {
      setloading(true);
      resetForm();
      final empProvider = Provider.of<EmployeMastServices>(context, listen: false);
      await loadLeaveTypes();
      await loadUserLeaves();
      if (curentUser['Role'] == 'Admin') {
        await empProvider.getAllEmployesData();
      }
      if (isEdit && leaveData != null) {
        setEditLeaveData(leaveData,empProvider);
      }
      setloading(false);
    } catch (e) {
      setloading(false);
    }
  }

  // ==================== SET EDIT LEAVE DATA ====================
  void setEditLeaveData(dynamic leaveData,dynamic empProvider) {
    isEditMode = true;
    editingLeaveCguid = leaveData.cguid?.toString();
    editingLeaveId = _parseInt(leaveData.empLeaveId);
    editingLeaveEmpId = _parseInt(leaveData.empId);
    
    // Parse dates
    selectedFromDate = _parseLeaveDate(leaveData.fromDate) ?? DateTime.now();
    selectedToDate = _parseLeaveDate(leaveData.toDate) ?? DateTime.now();
    
    // Set text controllers
    txtLeaveStartDate.text = DateFormat('dd-MM-yyyy').format(selectedFromDate);
    txtLeaveEndDate.text = DateFormat('dd-MM-yyyy').format(selectedToDate);
    txtReason.text = leaveData.remarks?.toString() ?? '';

    for (var i in empProvider.allemployes) {
      if(i.id == editingLeaveEmpId) {
        selectedEmployee = i;
      }
    }

    for (var j in leaveStatusList) {

      if(j.keys == leaveData.approveStatus) {
        selectedLeaveStatusName = j.values;
      }
    }
    
    // Set leave type (Full Day / Half Day)
    if (leaveData.dayType?.toString() == 'Full Day') {
      selectedIndex = 0;
    } else if (leaveData.dayType?.toString() == 'First Half') {
      selectedIndex = 1;
    } else if (leaveData.dayType?.toString() == 'Second Half') {
      selectedIndex = 2;
    } else {
      // Default to Full Day if unknown
      selectedIndex = 0;
    }
    
    // Set selected leave type
    selectedLeaveTypeName = leaveData.leaveTypeFName?.toString();
    if (selectedLeaveTypeName != null && leaveTypeList.isNotEmpty) {
      selectedLeaveTypeData = leaveTypeList.firstWhere(
        (element) => element.leaveTypeFName == selectedLeaveTypeName,
        orElse: () => leaveTypeList.first,
      );
    }
    
    // Calculate eligible leave
    _calculateEligibleLeave();
    
    notifyListeners();
  }

  // ==================== SELECT LEAVE TYPE ====================
  void selectLeaveType(String? value) {
    if (value != null && leaveTypeList.isNotEmpty) {
      selectedLeaveTypeData = leaveTypeList.firstWhere(
        (element) => element.leaveTypeFName == value,
        orElse: () => leaveTypeList.first,
      );
      selectedLeaveTypeName = value;
      _calculateEligibleLeave();
      notifyListeners();
    }
  }

  void selectLeaveStatus(String? value) {
    if (value != null && leaveStatusList.isNotEmpty) {
      selectedLeaveStatusName = value;
      notifyListeners();
    }
  }

  // ==================== HELPER METHODS ====================
  double parseLeaveCount(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  bool _isApprovedStatus(dynamic value) {
    final status = value?.toString().trim().toUpperCase();
    return status == 'A' || status == 'APPROVED';
  }

  DateTime? _parseLeaveDate(dynamic value) {
    final dateText = value?.toString().trim();
    if (dateText == null || dateText.isEmpty) return null;

    final parsedDate = DateTime.tryParse(dateText);
    if (parsedDate != null) return parsedDate;

    for (final pattern in ['dd-MM-yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(dateText);
      } catch (_) { /* ignored */ }
    }
    return null;
  }

  String formatLeaveCount(double value) {
    return _formatNumber(value);
  }

  void setPaidLeaveTypeData() {
    slTypeData = null;
    for (var element in leaveTypeList) {
      final leaveTypeName = element.leaveTypeFName?.toString().trim().toUpperCase();
      final leaveTypeValue = element.leaveType?.toString().trim().toUpperCase();

      if (leaveTypeName == 'PAID LEAVE' || leaveTypeValue == 'PAID') {
        slTypeData = element;
        return;
      }
    }
  }

  double selectedLeaveGainLimit(leavesData) {
    if (leavesData == null) return 0;
    switch (leavesData!.leaveLimit) {
      case 'Monthly':
        return parseLeaveCount(leavesData!.monthly);
      case 'Quarterly':
        return parseLeaveCount(leavesData!.quarterly);
      case 'HalfYearly':
        return parseLeaveCount(leavesData!.halfYear);
      case 'Yearly':
        return parseLeaveCount(leavesData!.yearlyLimit);
      default:
        return 0;
    }
  }

  bool isLeaveInSelectedLimit(DateTime leaveDate) {
    if (selectedLeaveTypeData == null) return false;
    return isLeaveInLimit(leaveDate, selectedLeaveTypeData!);
  }

  bool isLeaveInLimit(DateTime leaveDate, GetLeaveMaster leaveTypeData) {
    if (selectedFromDate.year != leaveDate.year) {
      return false;
    }

    switch (leaveTypeData.leaveLimit) {
      case 'Monthly':
        return leaveDate.month == selectedFromDate.month;
      case 'Quarterly':
        final selectedQuarter = ((selectedFromDate.month - 1) ~/ 3) + 1;
        final leaveQuarter = ((leaveDate.month - 1) ~/ 3) + 1;
        return selectedQuarter == leaveQuarter;
      case 'HalfYearly':
        final selectedHalf = selectedFromDate.month <= 6 ? 1 : 2;
        final leaveHalf = leaveDate.month <= 6 ? 1 : 2;
        return selectedHalf == leaveHalf;
      case 'Yearly':
        return true;
      default:
        return false;
    }
  }

  // ==================== CALCULATE ELIGIBLE LEAVE ====================
  void _calculateEligibleLeave() {
    _resetEligibleLeaveCounts();
    if (selectedLeaveTypeData == null) {
      notifyListeners();
      return;
    }

    final selectedEmpId = _selectedEligibilityEmployeeId;
    if (selectedEmpId == null) {
      notifyListeners();
      return;
    }

    final gainLeave = selectedLeaveGainLimit(selectedLeaveTypeData);
    double usedLeave = 0;

    for (var element in userLeaves) {
      // Skip the current leave being edited
      final elementEmpId = _parseInt(element.empId);
      final elementLeaveId = _parseInt(element.empLeaveId);
      final elementLeaveTypeId = _parseInt(element.leaveTypeId);

      if (curentUser['Role'] != 'Admin' &&
          isEditMode &&
          editingLeaveEmpId == selectedEmpId &&
          editingLeaveId == elementLeaveId) {
        continue;
      }
      
      if (elementEmpId == selectedEmpId &&
          _isApprovedStatus(element.approveStatus) &&
          elementLeaveTypeId == selectedLeaveTypeData!.leaveTypeId) {
        final leaveDate = _parseLeaveDate(element.fromDate);
        if (leaveDate != null && isLeaveInSelectedLimit(leaveDate)) {
          usedLeave += parseLeaveCount(element.leaveDuration);
        }
      }
    }

    showGainCounting = formatLeaveCount(gainLeave);
    showUsedCounting = formatLeaveCount(usedLeave);
    showEligibleCounting = formatLeaveCount(gainLeave - usedLeave);
    notifyListeners();
  }

  void _resetEligibleLeaveCounts() {
    showGainCounting = '0';
    showUsedCounting = '0';
    showEligibleCounting = '0';
  }

  int? get _selectedEligibilityEmployeeId {
    if (curentUser['Role'] == 'Admin') {
      return selectedEmployee?.id;
    }
    return curentUser['Id'];
  }

  int get _selectedSubmitEmployeeId {
    if (curentUser['Role'] == 'Admin') {
      return selectedEmployee?.id ?? 0;
    }
    return curentUser['Id'];
  }

  String get _selectedLeaveStatusKey {
    if (curentUser['Role'] != 'Admin' || selectedLeaveStatusName == null) {
      return 'P';
    }

    return leaveStatusList
        .firstWhere(
          (element) => element.values == selectedLeaveStatusName,
          orElse: () => leaveStatusList.first,
        )
        .keys;
  }

  void _calculatePaidLeaveSummary() {
    showTotalGainPaidLeaves = '0';
    showPaidLeaves = '0';

    setPaidLeaveTypeData();
    if (slTypeData == null) {
      notifyListeners();
      return;
    }

    final gainLeave = selectedLeaveGainLimit(slTypeData);
    double usedLeave = 0;

    for (var element in userLeaves) {
      if (element.empId == curentUser['Id'] &&
          element.approveStatus == 'A' &&
          element.leaveTypeId == slTypeData!.leaveTypeId) {
        final leaveDate = DateTime.tryParse(element.fromDate.toString());
        if (leaveDate != null && isLeaveInLimit(leaveDate, slTypeData!)) {
          usedLeave += parseLeaveCount(element.leaveDuration);
        }
      }
    }

    showTotalGainPaidLeaves = formatLeaveCount(gainLeave);
    showPaidLeaves = formatLeaveCount(usedLeave);
    notifyListeners();
  }

  String _formatNumber(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }


  // ==================== RESET FORM ====================
  void resetForm() {
    isEditMode = false;
    editingLeaveCguid = null;
    editingLeaveId = null;
    editingLeaveEmpId = null;
    selectedFromDate = DateTime.now();
    selectedToDate = DateTime.now();
    txtLeaveStartDate.clear();
    txtLeaveEndDate.clear();
    txtReason.clear();
    selectedIndex = 0;
    selectedLeaveTypeData = null;
    selectedLeaveTypeName = null;
    showGainCounting = '0';
    showUsedCounting = '0';
    selectedEmployee = null;
    selectedLeaveStatusName = null;
    showEligibleCounting = '0';
    autovalidateMode = AutovalidateMode.disabled;
    notifyListeners();
  }

  // ==================== CALCULATE LEAVE DAYS ====================
  double _calculateDurationCounts() {
    if (selectedFromDate == selectedToDate) {
      return isFullDay ? 1 : 0.5;
    } else {
      int totalDays = selectedToDate.difference(selectedFromDate).inDays + 1;
      return isFullDay ? totalDays.toDouble() : totalDays / 2;
    }
  }

  // ==================== SUBMIT NEW LEAVE ====================
  Future<void> addHandleSubmit(BuildContext context, GlobalKey<FormState> formKey) async {
    if (islodering) return;
    
    try {
      setloading(true);
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      
      if (formKey.currentState!.validate()) {
        if (curentUser['Role'] == 'Admin' && selectedEmployee == null) {
          showtoastmessage('Select Employee');
          return;
        }

        if (selectedLeaveTypeData == null) {
          showtoastmessage('Select Leave Type');
          return;
        }

        final durationCounts = _calculateDurationCounts();
        final allowleave = double.tryParse(showEligibleCounting) ?? 0;
        
        if (allowleave < durationCounts) {
          showtoastmessage('You cannot apply leave more than eligible leave');
          return;
        }
        
        String setGuid = generateCustomUuid();
        String dayType = selectedDayType;
        
        await LeaveMasterApiService().applyLeave(
          setEmployeId: _selectedSubmitEmployeeId,
          leaveTypeCguids: selectedLeaveTypeData?.cguid ?? '',
          fromdate: selectedFromDate.toString(),
          leaveTypeid: selectedLeaveTypeData?.leaveTypeId ?? 0,
          leaveYears: DateTime.now().year,
          leavedec: durationCounts,
          remarks: txtReason.text,
          sendCguid: setGuid,
          todate: selectedToDate.toString(),
          leaveStatusSet: _selectedLeaveStatusKey,
          dayTypes: dayType,
        ).then((value) {
          showtoastmessage('Leave applied successfully');
          resetForm();
          nextScreen(context, AnimatedBottomBar(), onthenValue: (val) {});
          autovalidateMode = AutovalidateMode.disabled;
        }).catchError((error) {
          showtoastmessage('Error applying leave: $error');
        });
      }
    } catch (e) {
      showtoastmessage('Error applying leave');
    } finally {
      setloading(false);
    }
  }

  // ==================== UPDATE EXISTING LEAVE ====================
  Future<void> updateHandleSubmit(BuildContext context, GlobalKey<FormState> formKey) async {
    if (islodering) return;
    
    try {
      setloading(true);
      FocusManager.instance.primaryFocus?.unfocus();
      
      if (formKey.currentState!.validate()) {
        if (curentUser['Role'] == 'Admin' && selectedEmployee == null) {
          showtoastmessage('Select Employee');
          return;
        }

        if (selectedLeaveTypeData == null) {
          showtoastmessage('Select Leave Type');
          return;
        }

        final durationCounts = _calculateDurationCounts();
        final allowleave = double.tryParse(showEligibleCounting) ?? 0;
        
        if (allowleave < durationCounts) {
          showtoastmessage('You cannot apply leave more than eligible leave');
          return;
        }
        
        String dayType = selectedDayType;
        
        // Call update API (adjust according to your API structure)
        await LeaveMasterApiService().updateLeave(
          sendCguid: editingLeaveCguid ?? '',
          setEmpid: _selectedSubmitEmployeeId,
          leaveTypeCguids: selectedLeaveTypeData?.cguid ?? '',
          fromdate: selectedFromDate.toString(),
          leaveTypeid: selectedLeaveTypeData?.leaveTypeId ?? 0,
          leaveYears: DateTime.now().year,
          leavedec: durationCounts,
          remarks: txtReason.text,
          todate: selectedToDate.toString(),
          leaveStatus: _selectedLeaveStatusKey,
          dayTypes: dayType,
        ).then((value) {
          showtoastmessage('Leave updated successfully');
          resetForm();
          nextScreen(context, AnimatedBottomBar(), onthenValue: (val) {});
          autovalidateMode = AutovalidateMode.disabled;
        }).catchError((error) {
          showtoastmessage('Error updating leave: $error');
        });
      }
    } catch (e) {
      showtoastmessage('Error updating leave');
    } finally {
      setloading(false);
    }
  }

  // ==================== DATE PICKER ====================
  Future<void> pickStartDate(BuildContext context, Size size, bool setFirstDate) async {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final firstSelectableDate = setFirstDate
        ? isEditMode && selectedFromDate.isBefore(currentDate)
            ? selectedFromDate
            : currentDate
        : selectedFromDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: setFirstDate ? selectedFromDate : selectedToDate,
      firstDate: firstSelectableDate,
      lastDate: DateTime(2140),
      selectableDayPredicate: (DateTime val) => val.weekday != 7,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: ColorConst.themeColor,
              onPrimary: ColorConst.white,
              surface: ColorConst.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: ColorConst.themeColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    if (setFirstDate) {
      if (picked.isBefore(selectedToDate) || _isSameDate(picked, selectedToDate)) {
        selectedFromDate = picked;
        txtLeaveStartDate.text = DateFormat('dd-MM-yyyy').format(selectedFromDate);
      } else {
        selectedFromDate = picked;
        selectedToDate = picked;
        txtLeaveStartDate.text = DateFormat('dd-MM-yyyy').format(selectedFromDate);
        txtLeaveEndDate.text = DateFormat('dd-MM-yyyy').format(selectedToDate);
      }
    } else {
      if (picked.isAfter(selectedFromDate) || _isSameDate(picked, selectedFromDate)) {
        selectedToDate = picked;
        txtLeaveEndDate.text = DateFormat('dd-MM-yyyy').format(selectedToDate);
      } else {
        showtoastmessage('End date cannot be before Start date');
      }
    }
    
    // Recalculate eligible leave when dates change
    _calculateEligibleLeave();
    notifyListeners();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void selectEmployee(Employeelists? employee) {
    selectedEmployee = employee;
    if (selectedLeaveTypeData == null) {
      notifyListeners();
      return;
    }
    _calculateEligibleLeave();
  }

  // Future<void> loadLeaveDataForEmployee(int? empId) async {
  // if (empId == null) return;
  // setloading(true);
  // try {
  //   await loadLeaveTypes();
  //   await loadUserLeavesForEmployee(empId);
  //   setloading(false);
  // } catch (e) {
  //   setloading(false);
  // }
// }


}

class GetLeaveStatus{
  String keys,values;
  GetLeaveStatus(this.keys,this.values);
}
