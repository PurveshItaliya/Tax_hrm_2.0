import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/forgotPassword_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/loadersshow.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ForgotPasswordProvider>(context, listen: false).clearData();
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final forgotPasswordProvider = Provider.of<ForgotPasswordProvider>(context);
    return checkInterNetConnection.connectionType == 0 ? const NoInternetViewPage() : Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: showCustomeAppBar(backString, size,iconsOntap: () {
        backScreen(context);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: forgotPasswordProvider.islodering  ? circleThemLoader() : Padding(
        padding:  EdgeInsets.symmetric(horizontal: size.width * 0.03),
        child: btnDesign(size,titles: sendOtpString, isgradient: true, onTap: () {
          if(forgotPasswordProvider.formKey.currentState!.validate()) {
            forgotPasswordProvider.sendOtpMobile(context);
          } else {
            if(forgotPasswordProvider.mobileNoController.text.isEmpty) {
              forgotPasswordProvider.mobileNoController.text = '0';
            }
          }
        }),
      ),
      body: Form(
        key: forgotPasswordProvider.formKey,
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.03),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(forgotPasswordStrng, style: TextStyle(fontSize: size.height * 0.035, fontWeight: FontWeight.w700, fontFamily: fontInterBoldString)),
                heightSpacer(size.height  * 0.015),
                Text(forgotSDescStrng, style: TextStyle(fontSize: size.height * 0.02, fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString)),
                    
                Padding(
                   padding:  EdgeInsets.only(top: size.height * 0.04, bottom: size.height * 0.03),
                   child: PhoneNumberTextFiled(hintText: '$enterYourString $mobileString', getcodes: forgotPasswordProvider.phonecode, onChanged: (value) {
                    forgotPasswordProvider.code = value.countryCode.toString().replaceAll('+', '');
                   }, controller: forgotPasswordProvider.mobileNoController, fillColors: ColorConst.white, readOnly: forgotPasswordProvider.islodering),
                ),
                    
                CommonTextField(controller: forgotPasswordProvider.passwordController, hintText: passwordString, fillColors: ColorConst.white,suffixIcon: IconButton(
                  onPressed: () {
                    forgotPasswordProvider.togglePasswordVisibility();
                  },
                  icon: Icon(forgotPasswordProvider.password ? Icons.visibility : Icons.visibility_off),
                ), validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $passwordString';
                  }
                  return null;
                }, obscureText: forgotPasswordProvider.password, readOnly: forgotPasswordProvider.islodering),
                    
                heightSpacer(size.height * 0.03),
                    
                CommonTextField(controller: forgotPasswordProvider.confirmPasswordController, hintText: confirmPasswordString, fillColors: ColorConst.white,suffixIcon: IconButton(
                  onPressed: () {
                    forgotPasswordProvider.toggleConfirmPasswordVisibility();
                  },
                  icon: Icon(forgotPasswordProvider.confirmPassword ? Icons.visibility : Icons.visibility_off),
                ), validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $confirmPasswordString';
                  }
                  if (value != forgotPasswordProvider.passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                }, obscureText: forgotPasswordProvider.confirmPassword, readOnly: forgotPasswordProvider.islodering),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
