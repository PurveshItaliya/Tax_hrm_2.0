// ignore_for_file: strict_top_level_inference, prefer_typing_uninitialized_variables

import 'package:tax_hrm/models/company/getallcompany.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/payrool/getpayrollattendancedata.dart';

var curentUser;
List<GetCompanyData> getAllCompany = [];
GetCompanyData? selectedcurentcompany;
List<Employeelists> allManinEmplyeList = [];

List<GetPayRollAttendance> payrollstoreDatalist = [];
List<PositionDataL> positionlistt = [];

bool switchValue = false;

bool lightsAppMode = true;

bool isSelfPunch = true;
