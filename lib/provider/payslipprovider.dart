// ignore_for_file: strict_top_level_inference, empty_catches, avoid_function_literals_in_foreach_calls

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tax_hrm/api/payslipapi.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/deletedepartment.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/payrool/viewPayroll.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class PaySlipProviders extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  DateTime paySlipcurrentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Employeelists? selectedEmployeeList;

  void updateMonth(DateTime month, BuildContext context) {
    paySlipcurrentMonth = month;
    notifyListeners();
    loadingData(selectedEmployeeList == null ?0:selectedEmployeeList!.id,false);
  }

  // employee Name select
  employessontap(value) {
    selectedEmployeeList = value;
    notifyListeners();
    loadingData(selectedEmployeeList!.id,false);
  }

  arrorHandleSubmit(listIndexs) {
    listIndexs.payslipBoolValue = !listIndexs.payslipBoolValue;
    notifyListeners();
  }

  iconOntap() {
    selectedEmployeeList = null;
    notifyListeners();
    loadingData(0,false);
  }

  List<PaySlipView> showPaySlips = [];

  loadingData(usetEmpid,refreshValue) async {
    try {
      setloading(true);
      if(refreshValue){
        selectedEmployeeList = null;
        paySlipcurrentMonth = DateTime(DateTime.now().year, DateTime.now().month);
      }
      await getPaySlipData(usetEmpid: usetEmpid,usetMonths: paySlipcurrentMonth.month,usetYears: paySlipcurrentMonth.year);
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  getPaySlipData({usetEmpid,usetMonths,usetYears}) async {
    await PaySlipApiSerices().getPaySlipData(setEmpid: usetEmpid,setMonths: usetMonths,setYears: usetYears).then((value) {
      showPaySlips = value;
    }).onError((error, stackTrace) {});
  }

  //****************************************** Delete paySlip Master ****************************************************** */

  // delete paySlip master
  deletePaySlipMaster(context,{payslipcguid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await PaySlipApiSerices().deletePlaySlipData(payslipcguid: payslipcguid).then((value) async {
        DeleteDepartmentmodel  deleteResponse  = value as DeleteDepartmentmodel;
        if(deleteResponse.success == true){
          if(deleteResponse.data == "Success"){
            await loadingData(0,false);
          }
        }
        setloading(false);
      }).onError((error, stackTrace) {
        setloading(false);
      },);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  //****************************************** Delete paySlip Master ****************************************************** */

  downloadPdf(url,empName) async {
    try {
      setloading(true);
      notifyListeners();
      await downloadAndSavePDF(url,empName);
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  Future<void> downloadAndSavePDF(String url, String empName) async {
    final response = await http.get(Uri.parse(url));

    Directory? externalDir;

    int fileIndex = 1;
    String filePath;
    if(Platform.isAndroid) {
      externalDir = Directory('/storage/emulated/0/Download/TAX HRM 2.0');
    } else if(Platform.isIOS) {
      externalDir = await getApplicationDocumentsDirectory();
    }

    // Create the directory if it does not exist
    if (!(externalDir!.existsSync())) {
      externalDir.createSync(recursive: true);
    }

    do {
      filePath = '${externalDir.path}/$empName($fileIndex).pdf';
      fileIndex++;
    } while (await File(filePath).exists());
    File path  = File(filePath);

    await path.writeAsBytes(response.bodyBytes).then((value) {
      showtoastmessage('PDF Download Successfully!!!');
    },);
  }

}
