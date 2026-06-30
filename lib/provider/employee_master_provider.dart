// // ignore_for_file: strict_top_level_inference

// ignore_for_file: empty_catches, unrelated_type_equality_checks, use_build_context_synchronously, strict_top_level_inference, unused_field

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/api/master_api.dart';
import 'package:tax_hrm/models/address/citylist_model.dart';
import 'package:tax_hrm/models/address/pincode_model.dart';
import 'package:tax_hrm/models/address/statelist_model.dart';
import 'package:tax_hrm/models/customeclass/simpleclass.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/deletedepartment.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/employes/gettotal_user.dart';
import 'package:tax_hrm/models/ifsc/ifsc_model.dart';
import 'package:tax_hrm/models/master_model.dart';
import 'package:tax_hrm/models/role/get_role_model.dart';
import 'package:tax_hrm/provider/address_provider.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/ifsc_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/provider/role_provider.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/randomcguid.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class EmployeeMasterProvider extends ChangeNotifier {
  Employeelists? selectedEmploye;
  DepartMnetModel? selectedDepartment;
  PositionDataL? selectedPostions;
  Getrolemodel? selectedRole;
  Statelistm? selectedStates;
  Citylistm? selectedCitys;
  pincodem? selectedPincodes;
  Mstclass? selectedAccounttype;
  IfscListModel? selectedIfsccode;
  List<Employeelists> employeeList = [];
  List<Employeelists> employeeGroupList = [];
  List<Employeelists> emplists = [];
  List<Employeelists> filteredUsers = [];
  List<Employeelists> allemployes = [];
  List<GetTotalUserModal> getTotalUserList = [];
  List<Mstclass> getallMastersData = [];
  List<Mstclass> bankAccountTypesList = [];
  bool showActiveOnly = false;
  bool showInactiveOnly = false;
  bool islodering = false;
  bool _isPasswordVisible = false;
  int expandedIndex = -1;
  bool showserch = false;
  late TabController tabController;

  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  File? get profileImage => _profileImage;
  bool _removeProfileImage = false;


  bool get isloderings => islodering;
  bool get isPasswordVisible => _isPasswordVisible;

    void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  String? selectedFromDate;
  String? selectedToDate;

  TextEditingController searchController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController joiningController = TextEditingController();
  TextEditingController salaryController = TextEditingController();
  TextEditingController totalHoursController = TextEditingController();
  TextEditingController panNOController = TextEditingController();
  TextEditingController address1Controller = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController address3Controller = TextEditingController();
  TextEditingController mobile1Controller = TextEditingController();
  TextEditingController mobile2Controller = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController heighestDegreeController = TextEditingController();
  TextEditingController degreeNameController = TextEditingController();
  TextEditingController uniSclController = TextEditingController();
  TextEditingController passingYearController = TextEditingController();
  TextEditingController bankNameController = TextEditingController();
  TextEditingController branchNameController = TextEditingController();
  TextEditingController accNoController = TextEditingController();
  TextEditingController uanNOController = TextEditingController();
  TextEditingController esicController = TextEditingController();
  TextEditingController locationRadiusController = TextEditingController(text: '50');
  bool isFetchLocation = false;

  void setFetchLocation(bool value) {
    isFetchLocation = value;
    notifyListeners();
  }

   // Form keys for validation
  final GlobalKey<FormState> formKey1 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKey2 = GlobalKey<FormState>();

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  String selectWorkType = '';
  List workTypeList = ['Office', 'Home'];
  String selectOfficeLocation = '';
  List officeLocationList = ['Surat', 'Bhavnagar'];

  String mobil1countryCodes = '+91';
  String countryView = 'IN';

  String mobil2countryCodes = '+91';
  String countryView2 = 'IN';

  TypedClass? selectGender;
  TypedClass? seselectedSalaryTypesle;
  String? selectedmarital = 'Single';

  // Add these methods to update values
  void updateOfficeLocation(String value) {
    selectOfficeLocation = value;
    notifyListeners();
  }

  void updateWorkType(String value) {
    selectWorkType = value;
    notifyListeners();
  }

  void setGender(TypedClass? value) {
    selectGender = value;
    notifyListeners();
  }

   void clearGender() {
    selectGender = null;
    notifyListeners();
  }


  void setSalaryType(TypedClass value) {
    seselectedSalaryTypesle = value;
    notifyListeners();
  }

  void setMarital(String? value) {
    selectedmarital = value;
    notifyListeners();
  }
   void setAccType(Mstclass? value) {
    selectedAccounttype = value;
    notifyListeners();
  }

  //-------------Get employee list data--------------------//
  Future employeeListApi() async {
    await Employeeclass().emppppapi().then((value) {
      employeeList = value;
      employeeGroupList = value;
      // emplists = value;
      filteredUsers = value;
      allemployes = value;
      filterEmployeeData();
    });
  }

  //-------------Delete employee list data--------------------//
  Future deleteEmployes(eid, context) async {
    await Employeeclass().deleteEmploye(eid).then((value) async {
      DeleteDepartmentmodel deletedResponse = value as DeleteDepartmentmodel;
      if (deletedResponse.success == true) {
        showtoastmessage('Delet Successfully');
      }
      await employeeListApi();
      Provider.of<AppPaginationProvider>(
        context,
        listen: false,
      ).countPaginationPage(emplists, 0);
      notifyListeners();
    });
  }

  //-------------Delete employee list data--------------------//
  Future deleteImages(eid, context) async {
    await Employeeclass().deleteImage(eid).then((value) async {
      DeleteDepartmentmodel deletedResponse = value as DeleteDepartmentmodel;
      if (deletedResponse.success == true) {
        removeProfileImage();
        // showtoastmessage('Delet Successfully');
      }
      // await employeeListApi();
      // Provider.of<AppPaginationProvider>(
      //   context,
      //   listen: false,
      // ).countPaginationPage(emplists, 0);
      notifyListeners();
    });
  }

  //-------------Get all user--------------------//
  Future getTotalUserData() async {
    await Employeeclass().getTotalUserApi().then((value) {
      getTotalUserList = value;
      notifyListeners();
    });
  }

  employeeLoadnigData() async {
    try {
      setloading(true);
      await employeeListApi();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  void toggleExpansion(int index) {
    if (expandedIndex == index) {
      expandedIndex = -1;
    } else {
      expandedIndex = index;
    }
    notifyListeners();
  }



  // Show list based on active status
  void filterEmployeeData() {
    if (showActiveOnly) {
      emplists = allemployes.where((user) => user.isActive == true).toList();
    } else if (showInactiveOnly) {
      emplists = allemployes.where((user) => user.isActive == false).toList();
    } else {
      emplists = allemployes;
    }
    notifyListeners();
  }

  // Search employee section
  void searchEmployee(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      emplists;
    } else {
      emplists = employeeList.where((employee) {
        final name = (employee.firstName ?? "").toString().toLowerCase();
        final role = (employee.role ?? "").toString().toLowerCase();
        final mobile = (employee.mobile1 ?? "").toString().toLowerCase();
        final department = (employee.departmentName ?? "")
            .toString()
            .toLowerCase();
        return name.contains(query) ||
            role.contains(query) ||
            mobile.contains(query) ||
            department.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  void toggleSearch() {
    showserch = !showserch;
    notifyListeners();
  }

  void clearData() {
    searchController.clear();
    showserch = false;
    showActiveOnly = false;
    showInactiveOnly = false;
    expandedIndex = -1;
  }

  void clearEmployeeForm() {
    isAccountSectionExpanded = true;
    isPersonalSectionExpanded = false;
    isContactSectionExpanded = false;
    isEducationSectionExpanded = false;
    isBankSectionExpanded = false;
    selectedEmploye = null;
    selectedDepartment = null;
    selectedPostions = null;
    selectedRole = null;
    selectedStates = null;
    selectedCitys = null;
    selectedPincodes = null;
    selectedAccounttype = null;
    selectedIfsccode = null;
    _profileImage = null;
    _removeProfileImage = false;
    selectedFromDate = null;
    selectedToDate = null;
    isActive = true;
    selectWorkType = '';
    selectOfficeLocation = '';
    countryView = 'IN';
    countryView2 = 'IN';
    selectGender = null;
    seselectedSalaryTypesle = null;
    selectedmarital = 'Single';

    usernameController.clear();
    passwordController.clear();
    firstNameController.clear();
    lastNameController.clear();
    dobController.clear();
    joiningController.clear();
    salaryController.clear();
    totalHoursController.clear();
    panNOController.clear();
    address1Controller.clear();
    address2Controller.clear();
    address3Controller.clear();
    mobile1Controller.clear();
    mobile2Controller.clear();
    emailController.clear();
    heighestDegreeController.clear();
    degreeNameController.clear();
    uniSclController.clear();
    passingYearController.clear();
    bankNameController.clear();
    branchNameController.clear();
    accNoController.clear();
    uanNOController.clear();
    esicController.clear();
    locationRadiusController.text = '50';
    isFetchLocation = false;
  }

  // ================ Add/Edit ============= //
  final List<String> tabs = [
    "Account",
    "Personal",
    "Contact",
    "Education",
    "Bank",
  ];

  bool isActive = true;

  void init(TickerProvider vsync) {
    tabController = TabController(length: tabs.length, vsync: vsync);
  }

  void changeStatus(bool value) {
    isActive = value;
    notifyListeners();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // Pick From Gallery
  Future<void> pickProfileImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
        _removeProfileImage = false;
        notifyListeners();
      }
    } catch (e) { /* ignored */ }
  }

  // Pick From Camera
  Future<void> pickProfileImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
        _removeProfileImage = false;
        notifyListeners();
      }
    } catch (e) { /* ignored */ }
  }

  Future<List<DepartMnetModel>> getfilterDepartment(String ss, context) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<DepartmentServices>(
        context,
        listen: false,
      ).alldepartment.where((e) {
        return e.departmentName.toString().toLowerCase().contains(
          ss.toLowerCase(),
        );
      }).toList();
    });
  }

  setProfileImage(File? image) {
  _profileImage = image;
  _removeProfileImage = false;
  notifyListeners();
}

void removeProfileImage() {
  _profileImage = null;
  _removeProfileImage = true;
  notifyListeners();
}

String? get employeeImageUrl {
  if (_removeProfileImage) return null;

  final image = selectedEmploye?.img?.toString().trim();
  if (image == null || image.isEmpty || image.toLowerCase() == 'null') {
    return null;
  }

  if (image.startsWith('http://') || image.startsWith('https://')) {
    return image;
  }

  if (image.startsWith('UploadFiles/')) {
    return Uri.parse(apibaseurl).resolve(image).toString();
  }

  return Uri.parse(apibaseurl).resolve('UploadFiles/Emp/$image').toString();
}



  void clearDepartment(){
    selectedDepartment = null;
    notifyListeners();
  }


  Future<List<PositionDataL>> getfiltersPostions(String ss, context) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<PositionMasterService>(
        context,
        listen: false,
      ).showPositions.where((e) {
        return e.departmentName.toString().toLowerCase().contains(
          ss.toLowerCase(),
        );
      }).toList();
    });
  }

    void clearPosition(){
    selectedPostions = null;
    notifyListeners();
  }

  Future<List<Getrolemodel>> getroleFilters(String ss, context) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<RoleMstServices>(
        context,
        listen: false,
      ).getRoleList.where((e) {
        return e.role.toString().toLowerCase().contains(ss.toLowerCase());
      }).toList();
    });
  }

  void clearRole(){
    selectedRole = null;
    notifyListeners();
  }

  Future<List<Statelistm>> getFilterState(String ss, context) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<AddresProviders>(
        context,
        listen: false,
      ).mainStateList.where((e) {
        return e.stateName.toString().toLowerCase().contains(ss.toLowerCase());
      }).toList();
    });
  }

  Future<List<Citylistm>> getFilterCitys(String ss, context) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<AddresProviders>(
        context,
        listen: false,
      ).filtersCityList.where((e) {
        return e.cityName.toString().toLowerCase().contains(ss.toLowerCase());
      }).toList();
    });
  }

  Future<List<pincodem>> getFilterPincode(String ss, context) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<AddresProviders>(
        context,
        listen: false,
      ).filtersPincodeList.where((e) {
        return e.code.toString().toLowerCase().contains(ss.toLowerCase());
      }).toList();
    });
  }

  Future<List<IfscListModel>> getFilterIfsc(String ss, context) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<IfscMastServices>(
        context,
        listen: false,
      ).getallIfscDataList.where((e) {
        return e.branchName.toString().toLowerCase().contains(ss.toLowerCase());
      }).toList();
    });
  }


  Future getAllTypesFilterList() async {
    setloading(true);
    getallMastersData.clear();
    bankAccountTypesList.clear();
    await MasterApis().getMasterData().then((value) async {
      getallMastersData = value;
      for (var i = 0; i < getallMastersData.length; i++) {
        if (getallMastersData[i].remark.toString().toLowerCase() ==
            'Bank Account'.toString().toLowerCase()) {
          bankAccountTypesList.add(getallMastersData[i]);
          notifyListeners();
        }
      }
      setloading(false);
      notifyListeners();
    });
  }

  setFilterPostions(context){
    Provider.of<PositionMasterService>(context,listen: false).getFiltersPostionList.clear();
    if(selectedDepartment != null){
      for (var element in Provider.of<PositionMasterService>(context,listen: false).positionlistt) {
        if(element.departmentId  == selectedDepartment!.id){
          Provider.of<PositionMasterService>(context,listen: false).getFiltersPostionList.add(element);
          if(selectedEmploye != null){
            Provider.of<PositionMasterService>(context,listen: false).getFiltersPostionList.forEach((element) {
              if(element.id.toString() == selectedEmploye!.positionId.toString()){
                selectedPostions = element;
              }
            });
          }
         notifyListeners();
        }
      }
    }
  }


// Save function
  Future<void> saveEmployee(BuildContext context, String flag, {dynamic selectedEmployee}) async {
    // Validate form
    bool set1 = formKey1.currentState?.validate() ?? false;
    if (set1 == true) {
      if (flag == 'A') { // Create new employee
        await createNewEmp(context);
      } else if (flag == 'U') { // Update existing employee
        await updateDataEmp(context, selectedEmployee);
      }
    } else {
      // Handle validation failure
      if (mobile1Controller.text.isEmpty) {
        mobile1Controller.text = '';
      }
    }
  }

  String _fullMobile(String countryCode, String mobile) {
    final number = mobile.trim();
    if (number.isEmpty) return '';

    var code = countryCode.trim().replaceAll('+', '');
    if (code.toUpperCase() == 'IN') code = '91';
    if (code.isEmpty || number.startsWith(code)) return number;

    return '$code$number';
  }

  String _mobileWithoutIndiaCode(dynamic value) {
    final mobile = value?.toString() ?? '';
    if (mobile.startsWith('91') && mobile.length > 10) {
      return mobile.substring(2);
    }
    return mobile;
  }

  dynamic _responseMessage(dynamic response) {
    if (response is Map) {
      if (response['Message'] != null) return response['Message'];
      if (response['message'] != null) return response['message'];
      if (response['error'] != null) return response['error'];
      if (response['errors'] != null) {
        if (response['errors'] is Map) {
          final errorsMap = response['errors'] as Map;
          return errorsMap.values.map((v) {
            if (v is List) return v.join(', ');
            return v.toString();
          }).join('; ');
        }
        return response['errors'].toString();
      }
    }
    return null;
  }

  Future<void> _refreshEmployeeList(BuildContext context) async {
    await employeeListApi();
    Provider.of<AppPaginationProvider>(context, listen: false)
        .countPaginationPage(emplists, 0);
  }

  DateTime? _parseEmployeeDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    final normalized = text.split('T').first;
    final formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'dd-MM-yyyy', 'MM/dd/yyyy'];

    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(normalized);
      } catch (e) { /* ignored */ }
    }

    try {
      return DateTime.parse(text);
    } catch (e) {
      return null;
    }
  }

  String displayEmployeeDate(dynamic value) {
    final date = _parseEmployeeDate(value);
    return date == null ? '' : DateFormat('dd/MM/yyyy').format(date);
  }

  String _selectedDateForApi(String? value) => displayEmployeeDate(value);
  
  // Create new employee
   Future<void> createNewEmp(BuildContext context) async {
  try {
    setloading(true);
    notifyListeners();
    
    String fullMobile1 = _fullMobile(countryView, mobile1Controller.text);
    String fullMobile2 = _fullMobile(countryView2, mobile2Controller.text);
    String cguid = generateGuid();
    
    await Employeeclass().createEmpp12(
      FILES: profileImage,
      accno: accNoController.text,
      address1: address1Controller.text,
      address2: address2Controller.text,
      address3: address3Controller.text,
      bankname: bankNameController.text,
      branchname: branchNameController.text,
      cityid: selectedCitys?.cityID.toString() ?? '',
      dob: _selectedDateForApi(selectedFromDate),
      doj: _selectedDateForApi(selectedToDate),
      email: emailController.text,
      firstname: firstNameController.text,
      gender: selectGender?.keys ?? '',
      lastname: lastNameController.text,
      marstatus: selectedmarital ?? '',
      mobile1: fullMobile1,
      mobile2: fullMobile2,
      pan: panNOController.text,
      password: passwordController.text,
      pincode: selectedPincodes?.pinCodeID.toString() ?? '',
      roletypes: selectedRole?.role ?? '',
      salary: seselectedSalaryTypesle?.keys.toString() ?? '',
      accountType: selectedAccounttype?.description.toString() ?? '',
      salaryamount: salaryController.text,
      totalhours: totalHoursController.text,
      username: usernameController.text,
      highestDegree: heighestDegreeController.text,
      degreeName: degreeNameController.text,
      universityName: uniSclController.text,
      passingYear: passingYearController.text,
      uanNo: uanNOController.text,
      esicNo: esicController.text,
      statid: selectedStates?.stateID.toString() ?? '',
      selectedposition: selectedPostions?.id.toString() ?? '',
      selectedifsc: selectedIfsccode?.iFSCID ?? '',
      selectedDepartment: selectedDepartment?.id.toString() ?? '',
      activemood: isActive,
      workType: selectWorkType,
      officeLocation: selectOfficeLocation,
      locationRadius: locationRadiusController.text,
      isFetchLocation: isFetchLocation,
      setCguids: cguid, 
      listenRes: (val) async {
        var response = val;
        final message = _responseMessage(response);
        if (message != null) {
          showtoastmessage('$message');
          setloading(false);
          notifyListeners();
        } else {
          showtoastmessage('Employee Added Successfully');
          await _refreshEmployeeList(context);
          setloading(false);
          notifyListeners();
          if (context.mounted) Navigator.pop(context);
        }
      },
    );
  } catch (e) {
    showtoastmessage('Create Error: $e');
    setloading(false);
    notifyListeners();
  }
}
  
  // Update employee
  Future<void> updateDataEmp(BuildContext context, dynamic selectedEmployee) async {
    try {
      setloading(true);
      notifyListeners();
      
      final employeeId = selectedEmployee is Employeelists
          ? selectedEmployee.id
          : selectedEmployee;

      if (employeeId == null || employeeId.toString().isEmpty) {
        showtoastmessage('Employee id not found');
        setloading(false);
        notifyListeners();
        return;
      }
      
      String fullMobile1 = _fullMobile(countryView, mobile1Controller.text);
      String fullMobile2 = _fullMobile(countryView2, mobile2Controller.text);

      String cguid = generateGuid();

      Future<void> handleUpdateResponse(response) async {
        final message = _responseMessage(response);
        if (message != null) {
          showtoastmessage('$message');
          setloading(false);
          notifyListeners();
          return;
        }

        showtoastmessage('Employee Updated Successfully');
        await _refreshEmployeeList(context);
        setloading(false);
        notifyListeners();
        if (context.mounted) Navigator.pop(context);
      }

  //       if (_profileImage == null) {
  //       await Employeeclass().updateEmployeswithoutImage(
  //       accno: accNoController.text,
  //       address1: address1Controller.text,
  //       address2: address2Controller.text,
  //       address3: address3Controller.text,
  //       bankname: bankNameController.text,
  //       branchname: branchNameController.text,
  //       cityid: selectedCitys?.cityID.toString() ?? '',
  //       dob: _selectedDateForApi(selectedFromDate),
  //       doj: _selectedDateForApi(selectedToDate),
  //       email: emailController.text,
  //       firstname: firstNameController.text,
  //       gender: selectGender?.keys.toString() ?? '',
  //       lastname: lastNameController.text,
  //       marstatus: selectedmarital ?? '',
  //       mobile1: fullMobile1,
  //       mobile2: fullMobile2,
  //       pan: panNOController.text,
  //       password: passwordController.text,
  //       pincode: selectedPincodes?.pinCodeID.toString() ?? '',
  //       roletypes: selectedRole?.role.toString() ?? '',
  //       salary: seselectedSalaryTypesle?.keys.toString() ?? '',
  //       salaryamount: salaryController.text,
  //       totalhours: totalHoursController.text,
  //       username: usernameController.text,
  //       highestDegree: heighestDegreeController.text,
  //       degreeName: degreeNameController.text,
  //       universityName: uniSclController.text,
  //       passingYear: passingYearController.text,
  //       uanNo: uanNOController.text,
  //       esicNo: esicController.text,
  //       accountType: selectedAccounttype?.description.toString() ?? '',
  //       statid: selectedStates?.stateID.toString() ?? '',
  //       selectedposition: selectedPostions?.id.toString() ?? '',
  //       selectedifsc: selectedIfsccode?.iFSCID.toString() ?? '',
  //       selectedDepartment: selectedDepartment?.id.toString() ?? '',
  //       userStatus: isActive,
  //       workType: selectWorkType,
  //       officeLocation: selectOfficeLocation,
  //       setCguids: cguid,
  //       removeImage: _removeProfileImage,
  //       listenRes: handleUpdateResponse,
  //       seteid: employeeId,  // Added this parameter
  //   );
  //   return;
  // }
      
  await Employeeclass().updateEmployes(
  seteid: employeeId,
  FILES: _profileImage,
  accno: accNoController.text,
  address1: address1Controller.text,
  address2: address2Controller.text,
  address3: address3Controller.text,
  bankname: bankNameController.text,
  branchname: branchNameController.text,
  cityid: selectedCitys?.cityID.toString() ?? '',
  dob: _selectedDateForApi(selectedFromDate),
  doj: _selectedDateForApi(selectedToDate),
  email: emailController.text,
  firstname: firstNameController.text,
  gender: selectGender?.keys.toString() ?? '',
  lastname: lastNameController.text,
  marstatus: selectedmarital ?? '',
  mobile1: fullMobile1,
  mobile2: fullMobile2,
  pan: panNOController.text,
  password: passwordController.text,
  pincode: selectedPincodes?.pinCodeID.toString() ?? '',
  roletypes: selectedRole?.role.toString() ?? '',
  salary: seselectedSalaryTypesle?.keys.toString() ?? '',
  salaryamount: salaryController.text,
  totalhours: totalHoursController.text,
  username: usernameController.text,
  highestDegree: heighestDegreeController.text,
  degreeName: degreeNameController.text,
  universityName: uniSclController.text,
  passingYear: passingYearController.text,
  uanNo: uanNOController.text,
  esicNo: esicController.text,
  accountType: selectedAccounttype?.description.toString() ?? '',
  statid: selectedStates?.stateID.toString() ?? '',
  selectedposition: selectedPostions?.id.toString() ?? '',
  selectedifsc: selectedIfsccode?.iFSCID.toString() ?? '',
  selectedDepartment: selectedDepartment?.id.toString() ?? '',
  userStatus: isActive, 
  workType: selectWorkType,
  officeLocation: selectOfficeLocation,
  locationRadius: locationRadiusController.text,
  isFetchLocation: isFetchLocation,
  setCguids: cguid,
  removeImage: _removeProfileImage,
  listenRes: handleUpdateResponse,
);   
    } catch (e) {
      showtoastmessage('Update Error: $e');
      setloading(false);
      notifyListeners();
    }
  }

  // Populate form data when editing an existing employee
// Populate form data when editing an existing employee
// Update the method to accept context
void populateEmployeeData(Employeelists? employee, BuildContext context) {
  if (employee == null) return;
  
  selectedEmploye = employee;
  _profileImage = null;
  _removeProfileImage = false;
  
  // Set basic info (same as above)
  firstNameController.text = employee.firstName ?? '';
  lastNameController.text = employee.lastName ?? '';
  emailController.text = employee.email ?? '';
  panNOController.text = employee.pAN ?? '';
  
  // Set mobile numbers
  mobile1Controller.text = _mobileWithoutIndiaCode(employee.mobile1);
  mobile2Controller.text = _mobileWithoutIndiaCode(employee.mobile2);
  countryView = 'IN';
  countryView2 = 'IN';
  
  // Set addresses
  address1Controller.text = employee.add1 ?? '';
  address2Controller.text = employee.add2 ?? '';
  address3Controller.text = employee.add3 ?? '';
  
  // Set dates
  final dobDate = _parseEmployeeDate(employee.dOB);
  final dojDate = _parseEmployeeDate(employee.dOJ);
  selectedFromDate = dobDate?.toIso8601String();
  selectedToDate = dojDate?.toIso8601String();
  dobController.text = displayEmployeeDate(employee.dOB);
  joiningController.text = displayEmployeeDate(employee.dOJ);
  
  // Set salary
  salaryController.text = employee.salaryAmount?.toString() ?? '';
  totalHoursController.text = employee.totalhours?.toString() ?? '';
  
  // Set username and password
  usernameController.text = employee.userName ?? '';
  passwordController.text = employee.password ?? '';
  
  // Set bank details
  bankNameController.text = employee.bankName ?? '';
  branchNameController.text = employee.branchName ?? '';
  accNoController.text = employee.accNo ?? '';
  heighestDegreeController.text = employee.highestDegree?.toString() ?? '';
  degreeNameController.text = employee.degreeName?.toString() ?? '';
  uniSclController.text = employee.universityName?.toString() ?? '';
  passingYearController.text = employee.passingYear?.toString() ?? '';
  uanNOController.text = employee.uANNo?.toString() ?? '';
  esicController.text = employee.eSICNo?.toString() ?? '';
  
  // Set active status
  isActive = employee.isActive ?? true;
  
  // Set marital status
  if (employee.maritalStatus != null && employee.maritalStatus!.trim().isNotEmpty) {
    final trimmed = employee.maritalStatus!.trim();
    selectedmarital = maritalitem.firstWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => trimmed,
    );
  } else {
    selectedmarital = 'Single';
  }
  
  // Set work type and office location
  if (employee.workType != null && employee.workType!.trim().isNotEmpty) {
    final trimmed = employee.workType!.trim();
    selectWorkType = workTypeList.firstWhere(
      (item) => item.toString().toLowerCase() == trimmed.toLowerCase(),
      orElse: () => trimmed,
    );
  } else {
    selectWorkType = '';
  }

  if (employee.officeLocation != null && employee.officeLocation!.trim().isNotEmpty) {
    final trimmed = employee.officeLocation!.trim();
    selectOfficeLocation = officeLocationList.firstWhere(
      (item) => item.toString().toLowerCase() == trimmed.toLowerCase(),
      orElse: () => trimmed,
    );
  } else {
    selectOfficeLocation = '';
  }
  
  // Set location radius and fetch location flag
  locationRadiusController.text = employee.locationRadius?.toString() ?? '50';
  isFetchLocation = employee.isFetchLocation ?? false;
  
  // Set gender
  if (employee.gender != null && employee.gender!.trim().isNotEmpty) {
    final trimmed = employee.gender!.trim();
    selectGender = gendersList.firstWhere(
      (gender) => gender.keys.toLowerCase() == trimmed.toLowerCase() ||
                  gender.values.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => gendersList.first,
    );
  } else {
    selectGender = null;
  }
  
  // Set salary type
  if (employee.salaryType != null && employee.salaryType!.trim().isNotEmpty) {
    final trimmed = employee.salaryType!.trim();
    seselectedSalaryTypesle = salaryBaseList.firstWhere(
      (salary) => salary.keys.toLowerCase() == trimmed.toLowerCase() ||
                  salary.values.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => salaryBaseList.first,
    );
  } else {
    seselectedSalaryTypesle = null;
  }
  
  // Set Department (nullable)
  if (employee.departmentId != null || employee.departmentName != null) {
    try {
      final departmentProvider = Provider.of<DepartmentServices>(context, listen: false);
      selectedDepartment = departmentProvider.alldepartment.firstWhere(
        (dept) => dept.id.toString() == employee.departmentId?.toString() ||
                  (employee.departmentName != null && dept.departmentName?.toString().toLowerCase() == employee.departmentName?.toString().toLowerCase()),
      );
    } catch (e) {
      selectedDepartment = null;
    }
  }
  
  // Set Position (nullable)
  if (employee.positionId != null || employee.positionName != null) {
    try {
      final positionProvider = Provider.of<PositionMasterService>(context, listen: false);
      selectedPostions = positionProvider.positionlistt.firstWhere(
        (pos) => pos.id.toString() == employee.positionId?.toString() ||
                 (employee.positionName != null && pos.positionName?.toString().toLowerCase() == employee.positionName?.toString().toLowerCase()),
      );
    } catch (e) {
      selectedPostions = null;
    }
  }
  
  // Set Role (nullable)
  if (employee.role != null && employee.role!.isNotEmpty) {
    try {
      final roleProvider = Provider.of<RoleMstServices>(context, listen: false);
      selectedRole = roleProvider.getRoleList.firstWhere(
        (role) => role.role.toString().toLowerCase() == employee.role?.toString().toLowerCase(),
      );
    } catch (e) {
      selectedRole = null;
    }
  }
  
  // Set State (nullable)
  if (employee.stateId != null || employee.stateName != null) {
    try {
      final addressProvider = Provider.of<AddresProviders>(context, listen: false);
      selectedStates = addressProvider.mainStateList.firstWhere(
        (state) => state.stateID.toString() == employee.stateId?.toString() ||
                   (employee.stateName != null && state.stateName?.toString().toLowerCase() == employee.stateName?.toString().toLowerCase()),
      );
      if (selectedStates != null) {
        addressProvider.filtersCity(selectedStates!.stateID);
      }
    } catch (e) {
      selectedStates = null;
    }
  }
  
  // Set City (nullable)
  if (employee.cityId != null || employee.cityName != null) {
    try {
      final addressProvider = Provider.of<AddresProviders>(context, listen: false);
      selectedCitys = addressProvider.mainCityList.firstWhere(
        (city) => city.cityID.toString() == employee.cityId?.toString() ||
                  (employee.cityName != null && city.cityName?.toString().toLowerCase() == employee.cityName?.toString().toLowerCase()),
      );
      if (selectedCitys != null) {
        addressProvider.filterPincodes(selectedCitys!.cityID);
      }
    } catch (e) {
      selectedCitys = null;
    }
  }
  
  // Set Pincode (nullable)
  if (employee.pincodeId != null) {
    try {
      final addressProvider = Provider.of<AddresProviders>(context, listen: false);
      selectedPincodes = addressProvider.mainPincodeList.firstWhere(
        (pin) => pin.pinCodeID.toString() == employee.pincodeId?.toString(),
      );
    } catch (e) {
      selectedPincodes = null;
    }
  }
  
  // Set IFSC (nullable)
  if (employee.iFSC != null && employee.iFSC!.isNotEmpty) {
    try {
      final ifscProvider = Provider.of<IfscMastServices>(context, listen: false);
      selectedIfsccode = ifscProvider.getallIfscDataList.firstWhere(
        (ifsc) => ifsc.branchName == employee.iFSC || ifsc.iFSCID.toString() == employee.iFSC,
      );
    } catch (e) {
      selectedIfsccode = null;
    }
  }
  
  // Set Account Type (nullable)
  if (employee.accType != null && employee.accType!.isNotEmpty) {
    try {
      selectedAccounttype = bankAccountTypesList.firstWhere(
        (accType) =>
            accType.description == employee.accType ||
            accType.masterTag1 == employee.accType ||
            accType.masterId.toString() == employee.accType,
      );
    } catch (e) {
      selectedAccounttype = null;
    }
  }
  
  notifyListeners();
}

  Future<void> loadAllEmployeeData(BuildContext context) async {
    islodering = true;
    
    try {
      // Get internet connection data
      Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
      
      // Load employee data
      await employeeLoadnigData();
      
      // Setup pagination
      Provider.of<AppPaginationProvider>(context, listen: false).countPaginationPage(
        emplists, 
        0
      );
    } catch (e) {
    } finally {
      islodering = false;
    }
  }

  // Add these boolean properties
bool isAccountSectionExpanded = true;
bool isPersonalSectionExpanded = false;
bool isContactSectionExpanded = false;
bool isEducationSectionExpanded = false;
bool isBankSectionExpanded = false;

// Add these methods
void toggleAccountSection() {
  isAccountSectionExpanded = !isAccountSectionExpanded;
  notifyListeners();
}

void togglePersonalSection() {
  isPersonalSectionExpanded = !isPersonalSectionExpanded;
  notifyListeners();
}

void toggleContactSection() {
  isContactSectionExpanded = !isContactSectionExpanded;
  notifyListeners();
}

void toggleEducationSection() {
  isEducationSectionExpanded = !isEducationSectionExpanded;
  notifyListeners();
}

void toggleBankSection() {
  isBankSectionExpanded = !isBankSectionExpanded;
  notifyListeners();
}
}
