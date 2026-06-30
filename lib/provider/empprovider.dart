// ignore_for_file: strict_top_level_inference, avoid_function_literals_in_foreach_calls

import 'package:flutter/material.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';

class EmployeMastServices extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  List<Employeelists> emplists = [];
  List<Employeelists> employesList1 = [];
  List<Employeelists> selectedEmployesList = [];
  List<Employeelists> mainEmployeList = [];
  List<Employeelists> employesSubAdminDataList  = [];

  //------------------------------------- Get Employee Details ---------------------------------\\
  
  Future getemployee() async {
    setloading(true);
    await Employeeclass().emppppapi().then((value) {
      allManinEmplyeList = value;
      emplists = value;
      employesList1 = value;
      selectedEmployesList = value;
      mainEmployeList = value;
      employesSubAdminDataList = value;
      notifyListeners();
      if (allManinEmplyeList.isNotEmpty) {
        employesSubAdminDataList = employesSubAdminDataList.where((element) => element.role == 'Sub-Admin').toList();
      }
    });
  }

  //----------------------------------------- Get Employee Details ------------------------\\
  List<Employeelists> allemployes = [];
  Future getAllEmployesData() async {
    setloading(true);
    emplists.clear();
    await Employeeclass().emppppapi().then((value) {
      allemployes = value;
      allemployes.forEach((element) {
        if (element.isActive != false) {
          emplists.add(element);
          notifyListeners();
        }
      });
      setloading(false);
      notifyListeners();
    });
  }

  // employee conducted by
  Future<List<Employeelists>> getFilterEmployeeby(String ss) async {
    return allemployes.where((e) {return e.firstName.toString().toLowerCase().contains(ss.toLowerCase());}).toList();
  }

  // employee conducted by
  Future<List<Employeelists>> getFilterEmployeeList(String ss) async {
    return emplists.where((e) {return e.firstName.toString().toLowerCase().contains(ss.toLowerCase());}).toList();
  }

}
