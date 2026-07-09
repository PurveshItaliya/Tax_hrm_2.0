import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:tax_hrm/provider/additionprovider.dart';
import 'package:tax_hrm/provider/address_provider.dart';
import 'package:tax_hrm/provider/admin_leave_provider.dart';
import 'package:tax_hrm/provider/admin_payrollslip_provider.dart';
import 'package:tax_hrm/provider/adminattendance.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/documentprovider.dart';
import 'package:tax_hrm/provider/employee_master_provider.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/eventProvider.dart';
import 'package:tax_hrm/provider/forgotPassword_provider.dart';
import 'package:tax_hrm/provider/holidayprovider.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/ifsc_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/leaderborder_provider.dart';
import 'package:tax_hrm/provider/leaveProviders.dart';
import 'package:tax_hrm/provider/leave_user_provider.dart';
import 'package:tax_hrm/provider/leavemployeeprovider.dart';
import 'package:tax_hrm/provider/notesprovider.dart';
import 'package:tax_hrm/provider/otpverificationprovider.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/provider/payrollprovider.dart';
import 'package:tax_hrm/provider/payslipprovider.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/provider/recuritmentprovider.dart';
import 'package:tax_hrm/provider/registrationprovider.dart';
import 'package:tax_hrm/provider/role_provider.dart';
import 'package:tax_hrm/provider/salaryStructures.dart';
import 'package:tax_hrm/provider/location_tracking_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/provider/splashprovider.dart';
import 'package:tax_hrm/provider/subadminaccessprovider.dart';
import 'package:tax_hrm/provider/timelinesprovider.dart';
import 'package:tax_hrm/provider/userloginprovider.dart';
import 'package:tax_hrm/provider/usermasterprovider.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/theme_provider.dart';

class AppProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AttendanceEmp()),
    ChangeNotifierProvider(create: (_) => AdminAttenDanceServices()),
    ChangeNotifierProvider(create: (_) => UserMasterService()),
    ChangeNotifierProvider(create: (_) => EmployeMastServices()),
    ChangeNotifierProvider(create: (_) => HolidayeMastServices()),
    ChangeNotifierProvider(create: (_) => LeaveMastServices()),
    ChangeNotifierProvider(create: (_) => DocumentsProvider()),
    ChangeNotifierProvider(create: (_) => NotesProviders()),
    ChangeNotifierProvider(create: (_) => ShiftMasterProvider()),
    ChangeNotifierProvider(create: (_) => DepartmentServices()),
    ChangeNotifierProvider(create: (_) => PositionMasterService()),
    ChangeNotifierProvider(create: (_) => LeaveEmployeeeMastServices()),
    ChangeNotifierProvider(create: (_) => EventsMastServices()),
    ChangeNotifierProvider(create: (_) => PayRollProviders()),
    ChangeNotifierProvider(create: (_) => InternetConnectionProvider()),
    ChangeNotifierProvider(create: (_) => RecuritmentProvider()),
    ChangeNotifierProvider(create: (_) => AdditionProvider()),
    ChangeNotifierProvider(create: (_) => SalaryStructureProvider()),
    ChangeNotifierProvider(create: (_) => TimeLineServices()),
    ChangeNotifierProvider(create: (_) => CommandWidigetsProvider()),
    ChangeNotifierProvider(create: (_) => AppPaginationProvider()),
    ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
    ChangeNotifierProvider(create: (_) => SubAdminMenuAccessProvider()),
    ChangeNotifierProvider(create: (_) => Userloginprovider()),
    ChangeNotifierProvider(create: (_) => Otpverificationprovider()),
    ChangeNotifierProvider(create: (_) => HomeProvider()),
    ChangeNotifierProvider(create: (_) => SelfiePunchProvider()),
    ChangeNotifierProvider(create: (_) => LocationTrackingProvider()),
    ChangeNotifierProvider(create: (_) => SettingProvider()),
    ChangeNotifierProvider(create: (_) => RegistrationProvider()),
    ChangeNotifierProvider(create: (_) => SplashProvider()),
    ChangeNotifierProvider(create: (_) => PaySlipProviders()),
    ChangeNotifierProvider(create: (_) => LeaveUserProvider()),
    ChangeNotifierProvider(create: (_)=> AdminLeaveProvider()),
    ChangeNotifierProvider(create: (_)=> EmployeeMasterProvider()),
    ChangeNotifierProvider(create: (_)=> RoleMstServices()),
    ChangeNotifierProvider(create: (_)=> AddresProviders()),
    ChangeNotifierProvider(create: (_)=> IfscMastServices()),
    ChangeNotifierProvider(create: (_)=> AdminPayrollslipProvider()),
    ChangeNotifierProvider(create: (_)=> LeaderborderProvider()),
  ];
}