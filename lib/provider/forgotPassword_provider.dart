// ignore_for_file: file_names, strict_top_level_inference, empty_catches

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/api/registration_api.dart';
import 'package:tax_hrm/page/authpages/otpverification.dart';
import 'package:tax_hrm/page/authpages/userloginpage.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class ForgotPasswordProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  clearData() {
    mobileNoController.clear();
    phonecode = 'IN';
    code = '91';
    passwordController.clear();
    confirmPasswordController.clear();
    password = true;
    confirmPassword = true;
    passwordError = null;
  }


  TextEditingController mobileNoController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  String  phonecode = 'IN';
  String  code ='91';
  String? passwordError;

  // Password Visible variable
  bool password = true;
  bool confirmPassword = true;

  void togglePasswordVisibility() {
    password = !password;
    validatePasswordMatch();
  }

  void toggleConfirmPasswordVisibility() {
    confirmPassword = !confirmPassword;
    validatePasswordMatch();
  }

  validatePasswordMatch() {
    if (passwordController.text != confirmPasswordController.text) {
      passwordError = 'Passwords do not match';
    } else {
      passwordError = null;
    }
    notifyListeners();
  }

  final formKey = GlobalKey<FormState>();

  Future sendOtpMobile(context) async {
    try {
      setloading(true);
      await RegistrationApi().sendOtp('$code${mobileNoController.text}').then((value) {
        var setResponse = value;

        if(setResponse['Success'] == true) {
          nextScreen(context, OtpVerificationOfLogin(setResponse['data'], mobileNoController.text, '', 'forgot'), onthenValue: (value) {});
        }else{
          showtoastmessage('Something Went Wrong');
        }
      });
    } finally {
      setloading(false);
    }
  }

  Future updateForgotPassword(context) async {
    try{
      setloading(true);
      var url = Uri.parse("$apibaseurl/api/MASTER/ForgotPassword?Mobile=${code + mobileNoController.text}&Password=${confirmPasswordController.text}");
      var response = await http.get(url);

      if(response.statusCode == 200) {
       nextscreenReplace(context, UserLoginPage(isAdmin: true));
       clearData();
       showtoastmessage('Password Updated Successfully');
        setloading(false);
        notifyListeners();
      }
      return jsonDecode(response.body);
    } catch(e) { /* ignored */ }
  }
}
