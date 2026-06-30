// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/api/authapi.dart';
import 'package:tax_hrm/models/authclass/adminloginclass.dart';
import 'package:tax_hrm/models/authclass/checkclass.dart';
import 'package:tax_hrm/models/authclass/emploginclass.dart';
import 'package:tax_hrm/page/authpages/otpverification.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class Userloginprovider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  TextEditingController textusercontroller = TextEditingController();
  TextEditingController textpasswordcontroller = TextEditingController();
  bool showpassword = true;
  bool textFormReadOnly = false;

  
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  void passordHideShow() {
    showpassword = !showpassword;
    notifyListeners();
  }

  loading() async {
    autovalidateMode = AutovalidateMode.disabled;
  }

  clearData() {
    textusercontroller.clear();
    textpasswordcontroller.clear();
  }

  handleSubmit(context,{isAdmin,formKey}) async {
    try {
      setloading(true);
      textFormReadOnly = true;
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      if (formKey.currentState!.validate()) {
        await empHandleSubmit(context,isAdmin);
        autovalidateMode = AutovalidateMode.disabled;
      }
      textFormReadOnly = false;
      setloading(false);
    } catch (e) {
      textFormReadOnly = false;
      setloading(false);
    }
  }

  // check mobile number api
  empHandleSubmit(context,isAdmin) async {
    await AuthLoginService().checkPhoneNumbers(textusercontroller.text,textpasswordcontroller.text).then((value) async {
      CheckNumbers  setresponse  = value as CheckNumbers;
      if(setresponse.success == true){
        if(isAdmin){
          if(setresponse.data!.role == "Admin"){
            await adminLogin(context);
          } else {
            showtoastmessage('Change Role !!!');  
          }
        } else {
          if(setresponse.data!.role == "User" || setresponse.data!.role == "Sub-Admin"){
            await empLogin(context);
          } else {
            showtoastmessage('Change Role !!!'); 
          }
        }
      } else {
        showtoastmessage('Invalid Credential !!!');
      }
    }).onError((error, stackTrace){
      showtoastmessage('Invalid Credential !!!');
      setloading(false);
    });
  }

  // admin Login api
  adminLogin(context) async {
    await AuthLoginService().calllogin(textusercontroller.text,textpasswordcontroller.text).then((value)async{
      UserLogin loginReponse =value as UserLogin;
      if(loginReponse.id == 0 && loginReponse.role == ''){
        showtoastmessage('Invalid Credential !!!');
      } else{
        if(loginReponse.hRM  != null){
          var holdData = value;
          nextScreen(context, OtpVerificationOfLogin(holdData,loginReponse.mobile.toString(),loginReponse.email.toString(), 'login'),onthenValue: (value){});
        }else{
          showtoastmessage('Invalid Credential !!!');
        }
      }
    }).onError((error, stackTrace){
      setloading(false);
    });
  }

  // user Login api
  empLogin(context) async {
   await AuthLoginService().callEmployeLogin(textusercontroller.text,textpasswordcontroller.text).then((value) async {
      EmpUserLogin loginReponse =value as EmpUserLogin;
      if(loginReponse.role == null){
        showtoastmessage('Invalid Credential !!!');
      }else{
        if(loginReponse.hRM  != null && loginReponse.hRM != false){
          var holdData = value;
          nextScreen(context, OtpVerificationOfLogin(holdData,loginReponse.mobile1.toString(),loginReponse.email.toString(), 'login'),onthenValue: (value){});
        }else{
          showtoastmessage('Invalid Credential !!!');  
        }
      }
    }).onError((error, stackTrace){
      setloading(false);
    });
  }

}
