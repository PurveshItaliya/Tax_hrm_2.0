// ignore_for_file: strict_top_level_inference, empty_catches, unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/adminprofileapi.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/models/authclass/adminloginclass.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/usermaster/userbyid.dart';
import 'package:tax_hrm/models/users/updateuser.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class UserMasterService extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  TextEditingController usernamecontroller = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameControllerS = TextEditingController();
  TextEditingController lastNameControllerS = TextEditingController();
  TextEditingController regtypecontroller = TextEditingController();
  TextEditingController mobileController2 = TextEditingController();
  TextEditingController departmentControllerS = TextEditingController();
  TextEditingController positionControllerS = TextEditingController();
  TextEditingController officeControoler = TextEditingController();
  TextEditingController workTypeController = TextEditingController();
  TextEditingController selectDOBController = TextEditingController();
  TextEditingController selectDOJController = TextEditingController();
  bool showpassword = true;
  
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  DateTime? holdSelectedFromDate;
  DateTime? holdSelectedToDate;
  File? images;  

  PhoneNumber? phoneNumber;
  PhoneNumber? phoneNumber2;
  String mobil1countryCodes = '';
  String mobil2countryCodes = '';

  
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

    // user profile data
  Employeelists? setEmpProfile;

  // admin profile data
  AdminProfiles? setAdminProfile;

  userProfileData(context) async {
    try {
      images = null;
      showpassword = true;
      setloading(true);
      await setProfileData(context);
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  void passordHideShow() {
    showpassword = !showpassword;
    notifyListeners();
  }

  Future<void> getImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      images = File(pickedImage.path);
      notifyListeners();
    }
  }

  setProfileData(context) async {
    if (curentUser['Role'] == 'Admin' && curentUser['OriginalRole'] == null) {
      await AdminProfileApiClass().getAdminProfileData().then((value) async {
        setAdminProfile = value;
        Employeelists? matchedEmp;
        try {
          await Provider.of<EmployeMastServices>(context, listen: false).getemployee();
          final empList = Provider.of<EmployeMastServices>(context, listen: false).emplists;
          for (var element in empList) {
            if (element.role == curentUser['Role']) {
              matchedEmp = element;
              break;
            }
          }
        } catch (e) {}
        if (matchedEmp != null) {
          setEmpProfile = matchedEmp;
          setEmpProfile!.isAdmin = true;
        } else if (value != null) {
          setEmpProfile = Employeelists()
            ..id = value.id
            ..firstName = value.firstName
            ..lastName = value.lastName
            ..mobile1 = value.mobile
            ..email = value.email
            ..userName = value.username
            ..password = value.password
            ..role = value.role ?? 'Admin'
            ..isActive = value.isActive ?? true
            ..isAdmin = true
            ..custId = value.custId
            ..cguid = value.cguid
            ..iPAddress = value.iPAddress
            ..cRM = value.cRM
            ..officeman = value.officeman
            ..hRM = value.hRM;
        }
        notifyListeners();
        phoneNumber = PhoneNumber.fromCompleteNumber(
          completeNumber: setAdminProfile!.mobile.toString(),
        );
        mobileController.text = phoneNumber!.number;
        mobil1countryCodes = phoneNumber!.countryCode;
        usernamecontroller.text = setAdminProfile!.username.toString();
        passwordController.text = setAdminProfile!.password.toString();
        emailController.text = setAdminProfile!.email.toString();
        firstNameControllerS.text = setAdminProfile!.firstName.toString();
        lastNameControllerS.text = setAdminProfile!.lastName.toString();
        regtypecontroller.text = setAdminProfile!.name.toString();
      });
    } else {
      await Provider.of<EmployeMastServices>(context,listen: false,).getemployee().then((value) { 
        Provider.of<EmployeMastServices>(context,listen: false,).emplists.forEach((element) {
          if (curentUser['Id'] == element.id) {
            setEmpProfile = element;
            notifyListeners();
            usernamecontroller.text = setEmpProfile!.userName.toString();
            passwordController.text = setEmpProfile!.password.toString();
            firstNameControllerS.text = setEmpProfile!.firstName.toString();
            lastNameControllerS.text = setEmpProfile!.lastName.toString();
            emailController.text = setEmpProfile!.email.toString();
            selectedFromDate = setEmpProfile!.dOB == null? null : DateTime.parse(setEmpProfile!.dOB.toString());
            selectedToDate = setEmpProfile!.dOJ == null? null : DateTime.parse(setEmpProfile!.dOJ.toString());
            holdSelectedFromDate = setEmpProfile!.dOB == null? null : DateTime.parse(setEmpProfile!.dOB.toString());
            holdSelectedToDate = setEmpProfile!.dOJ == null? null : DateTime.parse(setEmpProfile!.dOJ.toString());
            selectDOBController.text = setEmpProfile!.dOB == null ? "" : DateFormat('dd-MM-yyyy').format(DateTime.parse(setEmpProfile!.dOB.toString()));
            selectDOJController.text = setEmpProfile!.dOJ == null ? "" : DateFormat('dd-MM-yyyy').format(DateTime.parse(setEmpProfile!.dOJ.toString()));
            departmentControllerS.text = setEmpProfile!.departmentName ?? '';
            positionControllerS.text = setEmpProfile!.positionName ?? '';
            officeControoler.text = setEmpProfile!.officeLocation ?? '';
            workTypeController.text = setEmpProfile!.workType ?? '';

            phoneNumber = PhoneNumber.fromCompleteNumber(
              completeNumber: setEmpProfile!.mobile1.toString(),
            );
            mobileController.text = phoneNumber!.number;
            mobil1countryCodes = phoneNumber!.countryCode;
            if (setEmpProfile!.mobile2 != null) {
              phoneNumber2 = PhoneNumber.fromCompleteNumber(
                completeNumber: setEmpProfile!.mobile2.toString(),
              );
              mobileController2.text = phoneNumber2!.number;
              mobil2countryCodes = phoneNumber2!.countryCode;
            } else {
              mobileController2.text = setEmpProfile?.mobile2 ?? '';
              mobil2countryCodes = 'IN';
            } 
          }
        });
      });
    }
  }

  Future<void> pickUserStartDate(
    BuildContext context,
    bool dob,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dob == true ? selectedFromDate ?? DateTime.now(): selectedToDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            cardColor: Colors.yellowAccent,
            highlightColor: ColorConst.black,
            colorScheme: ColorScheme.dark(
              onBackground: ColorConst.black,
              onPrimaryContainer: Colors.amber,
              primary: ColorConst.themeColor,
              onPrimary: ColorConst.black,
              surface: ColorConst.white,
              onSurface: ColorConst.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ColorConst.themeColor,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (dob == true) {
      if (picked != null) {
        selectedFromDate = picked;
        selectDOBController.text = DateFormat('dd-MM-yyyy').format(selectedFromDate!);
      }
      notifyListeners();
    } else {
      if (picked != null) {
        selectedToDate = picked;
        selectDOJController.text = DateFormat('dd-MM-yyyy').format(selectedToDate!);
      }
      notifyListeners();
    }
  }

  updateHandleSubmit(context,formKey) async {
    try {
      setloading(true);
      notifyListeners();
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      if (formKey.currentState!.validate()) {
        if(curentUser['Role'] == 'User') {
          await updateUser(context,);
        } else {
          await updateAdminUser(context,);
        }
        autovalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  //**************************************** update User Profile ********************************** */

  updateUser(context,) async {
    try {
      await updateEmployProfile(
        activeStatus: setEmpProfile!.isActive,
        addres1: setEmpProfile!.add1,addres2: setEmpProfile!.add2,addres3: setEmpProfile!.add3,
        bankname: setEmpProfile!.bankName.toString(),brancename: setEmpProfile!.branchName.toString(),context: context,
        fnames: firstNameControllerS.text,
        lnames: lastNameControllerS.text,
        selectedImage:  images,
        setAccountNumber: setEmpProfile!.accNo.toString(),
        setAccountType: setEmpProfile!.accType.toString(),
        setcityid: setEmpProfile!.cityId,
        setdepartmet: setEmpProfile!.departmentId,
        setifsccode: setEmpProfile!.iFSC,
        setmobile1: mobil1countryCodes+mobileController.text,
        setmobile2: mobil2countryCodes+mobileController2.text,
        setpan: setEmpProfile!.pAN,
        setpassword: setEmpProfile!.password,
        setpincodeid: setEmpProfile!.pincodeId,
        setposition: setEmpProfile!.positionId,
        setsalary: setEmpProfile!.salaryType,
        setsalaryamounts: setEmpProfile!.salaryAmount,
        setstatid: setEmpProfile!.stateId,
        unames: setEmpProfile!.userName,
        userdob: selectedFromDate.toString(),userdoj:  selectedToDate.toString(),
        useremail: emailController.text,
        usergander: setEmpProfile!.gender,
        userstatus: setEmpProfile!.maritalStatus,
        userrole: setEmpProfile!.role,
        setselectedeid: setEmpProfile!.id.toString(),
      );
    } catch (e) { /* ignored */ }
  }

  updateEmployProfile({selectedImage,setAccountNumber,addres1,addres2,addres3,bankname,brancename,setcityid,userdob,userdoj,useremail,fnames,usergander,lnames,userstatus,setmobile1,setmobile2,setpan,setpassword,setpincodeid,userrole,setsalary,setsalaryamounts,unames,setstatid,setposition,setifsccode,setdepartmet,context,setselectedeid,activeStatus,setAccountType,}) async {
    try {
      await Employeeclass().updateEmployes(listenRes: (val) async {
        var response = val;
        if (response['Message'] != null) {
          showtoastmessage('${response['Message']}');
        } else {
          await Provider.of<EmployeMastServices>(context,listen: false,).getemployee().then((value) async {
            Provider.of<EmployeMastServices>(context,listen: false,).emplists.forEach((element) async {
              if (curentUser['Id'] == element.id) {

                curentUser['FirstName'] = element.firstName;
                curentUser['LastName'] = element.lastName;
                curentUser['Mobile1'] = element.mobile1;
                curentUser['Mobile2'] = element.mobile2;
                curentUser['Email'] = element.email;
                curentUser['DOB'] = element.dOB;
                curentUser['DOJ'] = element.dOJ;

                String udata = jsonEncode(curentUser);
                await SaveUser().saveUserData(udata);
                await SaveUser().getUserDatas().then((values) async {
                  if (values != '') {
                    var halos = jsonDecode(values);
                    curentUser = jsonDecode(values);
                    Navigator.pop(context);        
                    showtoastmessage('Update Successfully');
                    setloading(false);
                    notifyListeners();
                    await Provider.of<SettingProvider>(context, listen: false).settingLoadding(context);
                   
                  }
                });
              }
            });
          });
        
        }
      },
      FILES: selectedImage,
      accno: setAccountNumber,
      address1: addres1,
      address2: addres2,
      address3: addres3,
      bankname: bankname,
      branchname: brancename,
      cityid: setcityid,
      dob: userdob,
      doj: userdoj,
      email: useremail,
      firstname: fnames,
      gender: usergander,
      lastname: lnames,
      marstatus: userstatus,
      mobile1: setmobile1,
      mobile2: setmobile2,
      pan: setpan,
      password: setpassword,
      pincode: setpincodeid,
      roletypes: userrole,
      salary: setsalary,
      salaryamount: setsalaryamounts,
      username: unames,
      statid: setstatid,
      selectedposition: setposition,
      selectedifsc: setifsccode,
      selectedDepartment: setdepartmet,
      seteid: setselectedeid,
      userStatus: activeStatus,
      accountType: setAccountType,
    )
    .then((value) {}).onError((error, stackTrace) {
        setloading(false);
        notifyListeners();
      },);
    } catch (e) {
      showtoastmessage('Some Thing Wrong');
    }
  }

  //**************************************** update User Profile ********************************** */

  //**************************************** update Admin User Profile ********************************** */

  updateAdminUser(context,) async {
    try {
      await updateAdminUserProfile(
        context,
        setemail: emailController.text,
        setfname: firstNameControllerS.text,
        setLname: lastNameControllerS.text,
        setpassword: passwordController.text,
        setmobilenumber: mobil1countryCodes+mobileController.text
      );
    } catch (e) { /* ignored */ }
  }

  updateAdminUserProfile(context,{setemail,setfname,setLname,setpassword,setmobilenumber}) async {
    try {
      await AdminProfileApiClass().updateAdminProfile(
        email: setemail,
        firstName: setfname,
        isActive: curentUser['IsActive'],
        lastName: setLname,
        password: setpassword,
        role: curentUser['Role'],
        username: curentUser['Username'],
        mobile: setmobilenumber
      ).then((value) async {
        UpdateAdmin updateResponse  = value as UpdateAdmin;

        UserLogin loginuser = UserLogin(
          cRM: curentUser['CRM'],
          cguid: curentUser['Cguid'],
          custId: curentUser['CustId'],
          email: updateResponse.tokens!.email,
          firstName: updateResponse.tokens!.firstName,
          hRM: curentUser['HRM'],
          id: curentUser['Id'],
          ipAddress: curentUser['IPAddress'],
          isActive: curentUser['IsActive'],
          isDefault: curentUser['IsDefault'],
          lastName: updateResponse.tokens!.lastName,
          mobile: updateResponse.tokens!.mobile,
          officeman: curentUser['Officeman'],
          username: curentUser['Username'],
          packageId: curentUser['PackageId'],
          token: curentUser['token'],
          password: updateResponse.tokens!.password,
          regTypeId: curentUser['RegTypeId'],
          role: curentUser['Role'],
          success: curentUser['success'],
          licenseDate: curentUser['LicenseDate'],
          registerdate: curentUser['registerdate'],
          companyId: curentUser['CompanyId'],
        );
        
        if (updateResponse.sucess == true) {
          String udata = jsonEncode(loginuser);
          await SaveUser().saveUserData(udata);
          await SaveUser().getUserDatas().then((value) async {
            if (value != '') {
              curentUser = jsonDecode(value);
              Navigator.pop(context);        
              showtoastmessage('Update Successfully');
              setloading(false);
              notifyListeners();
              await Provider.of<SettingProvider>(context, listen: false).settingLoadding(context);
            }
          });
        }
      }).onError((error, stackTrace) {
        setloading(false);
        notifyListeners();
      },);
    } catch (e) { /* ignored */ }
  }


  //**************************************** update Admin User Profile ********************************** */

}
