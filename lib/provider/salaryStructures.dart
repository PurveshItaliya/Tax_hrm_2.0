// ignore_for_file: empty_catches, strict_top_level_inference, file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:tax_hrm/api/payrollapi.dart';
import 'package:tax_hrm/api/payslipapi.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/payrool/monthsbreak.dart';
import 'package:tax_hrm/models/payrool/viewPayroll.dart';
import 'package:tax_hrm/page/salaryslip/month_picker_package.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class SalaryStructureProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Employee selection for payslip
  Employeelists? selectedEmploye;

  // Payslip data
  List<PaySlipView> showPaySlips = [];

  // Download state
  bool downloading = false;

  void setMonth(DateTime date) {
    currentMonth = date;
    notifyListeners();
  }

  Future<void> previousMonth() async {
    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    notifyListeners();
    await getPaySlipsData();
  }

  Future<void> nextMonth() async {
    final nowMonth = DateTime(DateTime.now().year, DateTime.now().month);

    if (currentMonth.isBefore(nowMonth)) {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      notifyListeners();
    }
    await getPaySlipsData();
    notifyListeners();
  }

  void onMonthChanged(DateTime focusedDay) {
    currentMonth = DateTime(focusedDay.year, focusedDay.month);
    notifyListeners();
  }

  // Select Month Picker Function

  Future<void> selectMonthYear(BuildContext context) async {
    final selectedDate = await SimpleMonthYearPicker.showMonthYearPickerDialog(
      context: context,
      selectedYears: currentMonth.year,setCurentMonts: currentMonth.month,
      selectionColor: ColorConst.themeColor,
      titleTextStyle: const TextStyle(),
      monthTextStyle: const TextStyle(),
      yearTextStyle: const TextStyle(),
      disableFuture: true,
    );

    currentMonth = selectedDate;
    await getPaySlipsData();
    notifyListeners();
  }

  List<MonthwiseBreak>  getAllMonthsBreak = [];
  Future getMonthsBreaks({setEmployeId, setMonth,setYear})async{
    await  PayRollApiSerices().getMonthsBreak(setEmployeId, setMonth,setYear).then((val){
      getAllMonthsBreak = val;
      notifyListeners();
    });
  }

  // Payslip data loading
  Future getPaySlipsData() async {
    setloading(true);
    try {
      final value = await PaySlipApiSerices().getPaySlipData(
        setEmpid: curentUser['Role'] == 'Admin' ? (selectedEmploye != null ? selectedEmploye!.id.toString()  : 0) : curentUser['Id'],
        setMonths: currentMonth.month,
        setYears: currentMonth.year
      );
      showPaySlips = value;
      if (showPaySlips.isNotEmpty) {
        parseHoursFromPayslip(showPaySlips.first);
      } else {
        // Reset hours if no data
        totalWorkingHours = 0;
        workingHours = 0;
        totalBreakHours = 0;
        overTimeHours = 0;
      }
    } catch (error) { /* ignored */ } finally {
      setloading(false);
      notifyListeners();
    }
  }

  // Employee selection
  void selectEmploye(Employeelists? employe) {
    selectedEmploye = employe;
    getPaySlipsData();
    notifyListeners();
  }

  // Clear employee selection
  void clearEmployeSelection() {
    selectedEmploye = null;
    getPaySlipsData();
    notifyListeners();
  }

  // Delete payslip
  Future deletepayslis(BuildContext context, {required String setpayslipcguid, required String setEmployeId, required int setMonth, required int setYear}) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Payslip'),
            content: const Text('Are you sure you want to delete this payslip?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        setloading(true);
        await PaySlipApiSerices().deletePlaySlipData(payslipcguid: setpayslipcguid).then((value) {
          showtoastmessage('Payslip deleted successfully');
          getPaySlipsData();
        });
      }
    } catch (e) { /* ignored */ } finally {
      setloading(false);
    }
  }

  // Download PDF
  Future<void> downloadAndSavePDF(String url, String fileName) async {
    try {
      // Set loading to true
      setloading(true);
      notifyListeners();
      final response = await http.get(Uri.parse(url));

      Directory? externalDir;

      int fileIndex = 1;
      String filePath;
      if(Platform.isAndroid) {
        externalDir = Directory('/storage/emulated/0/Download/TAX HRM 2.0');
        if (!(externalDir.existsSync())) {
          externalDir.createSync(recursive: true);
        }
      } else if(Platform.isIOS) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        externalDir = Directory('${appDocDir.path}/TAX HRM 2.0');
        if (!(externalDir.existsSync())) {
          externalDir.createSync(recursive: true);
        }
      }

      do {
        filePath = '${externalDir!.path}/$fileName($fileIndex).pdf';
        fileIndex++;
      } while (await File(filePath).exists());
      File path  = File(filePath);

      await path.writeAsBytes(response.bodyBytes).then((value) async {
        showtoastmessage('PDF Download Successfully!!!');
      },);
      setloading(false);
    } catch (e) {
      setloading(false);
      showtoastmessage('PDF Download Failed!!!');
    } finally {
      setloading(false);
      notifyListeners();
    }
  }

  // Initialize data
  Future<void> initializeData() async {
    currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    await getPaySlipsData();
  }

  // Set state helper (for compatibility with widget state)
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // ==================== HOURS DATA (From JSON) ====================
  // Raw values from payslip
  double totalWorkingHours = 0;   
  double workingHours = 0;        
  double totalBreakHours = 0;     
  double overTimeHours = 0;       

  /// Net hours = working + break
  double get netWorkingHours => workingHours + totalBreakHours;

  double get remainingHours {
    final diff = totalWorkingHours - netWorkingHours;
    return diff > 0 ? diff : 0;
  }

  /// Extra hours if user exceeded total hours
  double get extraHours {
    final diff = netWorkingHours - totalWorkingHours;
    return diff > 0 ? diff : 0;
  }

  double get expectedWorkingHours => totalWorkingHours;

  double get overtimeHours => overTimeHours;

  // =========================
  // Formatted outputs
  // =========================

  String get formattedTotalWorkingHours => _formatHours(totalWorkingHours);

  String get formattedWorkingHours => _formatHours(workingHours);

  String get formattedTotalBreakHours => _formatHours(totalBreakHours);

  String get formattedNetWorkingHours => _formatHours(netWorkingHours);

  String get formattedRemainingHours => _formatHours(remainingHours);

  String get formattedExtraHours => _formatHours(extraHours);

  String get formattedOvertimeHours => _formatHours(overtimeHours);

  void parseHoursFromPayslip(PaySlipView payslip) {
    totalWorkingHours = payslip.totalHours ?? 0;
    workingHours = payslip.workingHours ?? 0;
    overTimeHours = payslip.oTHour ?? 0;

    totalBreakHours = _parseTimeStringToHours(
      payslip.totalBreak ?? '0',
    );
  }

  String _formatHours(double hours) {
    if (hours <= 0) return '0h';

    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();

    if (minutes > 0) {
      return '${wholeHours}h ${minutes}m';
    }
    return '${wholeHours}h';
  }

  double _parseTimeStringToHours(String timeString) {
    if (timeString.isEmpty ||
        timeString == '0' ||
        timeString == '00:00') {
      return 0;
    }

    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        return hours + (minutes / 60);
      }

      final hours = double.tryParse(timeString);
      if (hours != null) return hours;
    } catch (e) { /* ignored */ }

    return 0;
  }


}
