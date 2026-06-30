// ignore_for_file: strict_top_level_inference

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:tax_hrm/api/leaveapi.dart';
import 'package:tax_hrm/api/leavesapi.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/models/leavetype/getuserList.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class AdminLeaveProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  List<LeaveListData>  mainallLeavesData = [];
  List<LeaveListData> approvedLeaves = [];
  List<LeaveListData> pendingLeaves = [];
  List<LeaveListData> rejectedLeaves = [];
  List<GetLeaveMaster> mainLeaveTypeList = [];

  initializeData() async {
    try {
      setloading(true);
      await getLeaveTypeList();
      await getUserLeaveLists();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
  }

  Future<void> getLeaveTypeList() async {
    mainLeaveTypeList = await LeaveMasterApiService().getLeaveMlist();
    notifyListeners();
  }

  Future getUserLeaveLists() async {
    await LeaveApiService().userLeaveList().then((value) async {
      mainallLeavesData = value;
      notifyListeners();
      await filterLeavesByStatus();
    });
  }

  Future filterLeavesByStatus() async {
    approvedLeaves = mainallLeavesData.where((leave) => leave.approveStatus == 'A').toList();
    pendingLeaves = mainallLeavesData.where((leave) => leave.approveStatus == 'P').toList();
    rejectedLeaves = mainallLeavesData.where((leave) => leave.approveStatus == 'R').toList();
    notifyListeners();
  }

  double parseLeaveCount(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double selectedLeaveGainLimit(GetLeaveMaster? leaveType) {
    if (leaveType == null) return 0;
    switch (leaveType.leaveLimit?.toString()) {
      case 'Monthly':
        return parseLeaveCount(leaveType.monthly);
      case 'Quarterly':
        return parseLeaveCount(leaveType.quarterly);
      case 'HalfYearly':
        return parseLeaveCount(leaveType.halfYear);
      case 'Yearly':
        return parseLeaveCount(leaveType.yearlyLimit);
      default:
        return 0;
    }
  }

  bool isLeaveInLimit(DateTime leaveDate, DateTime selectedDate, GetLeaveMaster leaveType) {
    if (selectedDate.year != leaveDate.year) return false;

    switch (leaveType.leaveLimit?.toString()) {
      case 'Monthly':
        return leaveDate.month == selectedDate.month;
      case 'Quarterly':
        final selectedQuarter = ((selectedDate.month - 1) ~/ 3) + 1;
        final leaveQuarter = ((leaveDate.month - 1) ~/ 3) + 1;
        return selectedQuarter == leaveQuarter;
      case 'HalfYearly':
        final selectedHalf = selectedDate.month <= 6 ? 1 : 2;
        final leaveHalf = leaveDate.month <= 6 ? 1 : 2;
        return selectedHalf == leaveHalf;
      case 'Yearly':
        return true;
      default:
        return false;
    }
  }

  double eligibleLeaveForRequest(LeaveListData leave) {
    GetLeaveMaster? selectedLeaveType;
    for (final element in mainLeaveTypeList) {
      if (element.leaveTypeId == leave.leaveTypeId) {
        selectedLeaveType = element;
        break;
      }
    }

    final requestLeaveDate = DateTime.tryParse(leave.fromDate.toString());
    if (selectedLeaveType == null || requestLeaveDate == null) return 0;

    final gainLeave = selectedLeaveGainLimit(selectedLeaveType);
    double usedLeave = 0;

    for (final element in mainallLeavesData) {
      if (element.empLeaveId == leave.empLeaveId) continue;

      if (element.empId == leave.empId &&
          element.approveStatus == 'A' &&
          element.leaveTypeId == leave.leaveTypeId) {
        final leaveDate = DateTime.tryParse(element.fromDate.toString());
        if (leaveDate != null && isLeaveInLimit(leaveDate, requestLeaveDate, selectedLeaveType)) {
          usedLeave += parseLeaveCount(element.leaveDuration);
        }
      }
    }

    return gainLeave - usedLeave;
  }

  Future<void> approveLeaveRequest(BuildContext context, LeaveListData leave) async {
    final requestDuration = parseLeaveCount(leave.leaveDuration);
    final eligibleLeave = eligibleLeaveForRequest(leave);

    if (requestDuration > eligibleLeave) {
      showtoastmessage('You can not Approve leave more than eligible leave');
      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.topSlide,
      showCloseIcon: true,
      title: 'Approve',
      desc: 'Leave Approve Successfully!',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await updateLeaveStatus(leave, 'A');
      },
    ).show();
  }

  Future<void> rejectLeaveRequest(BuildContext context, LeaveListData leave) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.topSlide,
      showCloseIcon: true,
      title: 'Warning',
      desc: 'Are you sure you want to reject?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await updateLeaveStatus(leave, 'R');
      },
    ).show();
  }

  Future<void> updateLeaveStatus(LeaveListData leave, String status) async {
    setloading(true);
    try {
      await LeaveMasterApiService().updateLeave(
        leaveId: leave.empLeaveId,
        sendCguid: leave.cguid,
        setEmpid: leave.empId,
        leaveTypeCguids: leave.leaveTypeCguid,
        fromdate: leave.fromDate.toString(),
        leaveTypeid: leave.leaveTypeId,
        leaveYears: leave.leaveYear ?? DateTime.now().year,
        leavedec: leave.leaveDuration,
        remarks: leave.remarks,
        todate: leave.toDate,
        leaveStatus: status,
        dayTypes: leave.dayType,
      );
      await getUserLeaveLists();
    } catch (e) {
      showtoastmessage('Error updating leave');
    } finally {
      setloading(false);
    }
  }
}
