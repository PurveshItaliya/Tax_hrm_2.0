// ignore_for_file: file_names, must_be_immutable

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/authpages/forgotpassword_screen.dart';
import 'package:tax_hrm/page/authpages/select_package_screen.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/userloginprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/utils/validation.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class UserLoginPage extends StatefulWidget {
  final bool isAdmin;
  const UserLoginPage({super.key, required this.isAdmin});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<Userloginprovider>(context,listen: false,).loading();
  }

  final userLoginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(
      context,
    );
    final userloginprovider = Provider.of<Userloginprovider>(
      context,
    );
    Provider.of<LanguageProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              body: Padding(
                padding: EdgeInsets.all(size.width * 0.03),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: userLoginFormKey,
                          autovalidateMode: userloginprovider.autovalidateMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              heightSpacer(size.height * 0.08),
                              Text("${widget.isAdmin == false ? LanguageProvider.translate("Employee", "Employee") : LanguageProvider.translate("Owner / Admin Access", "Owner / Admin Access")} $loginString",style: TextStyle(color: ColorConst.black, fontFamily: fontInterBoldString, fontSize: size.width * 0.04),),
                              heightSpacer(size.height * 0.012),
                              Text(loginTitleString,style: TextStyle(color: ColorConst.textgrey, fontFamily: fontInterSemiBoldString, fontSize: size.width * 0.045),),
                              heightSpacer(size.height * 0.04),
                              CommonTextField(readOnly: userloginprovider.textFormReadOnly,controller: userloginprovider.textusercontroller,hintText: userNameString,validator: (p0) => allValidation(p0!),),
                              heightSpacer(size.height * 0.03),
                              CommonTextField(obscureText: userloginprovider.showpassword,controller: userloginprovider.textpasswordcontroller,hintText: passwordString,readOnly: userloginprovider.textFormReadOnly,suffixIcon: IconButton(onPressed: userloginprovider.passordHideShow, icon: Icon(userloginprovider.showpassword == true ? Icons.visibility :Icons.visibility_off,color: ColorConst.passwordColor,)),validator: (p0) => allValidation(p0!),),
                              heightSpacer(size.height * 0.03),

                              widget.isAdmin ?
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () {
                                    nextScreen(context, ForgotPasswordScreen(), onthenValue: (value) {});
                                  },
                                  child: Text(forgotPasswordString, style: TextStyle(color: ColorConst.themeColor, fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString))),
                              ) : Container(),
                              widget.isAdmin ? heightSpacer(size.height * 0.015) : Container(),

                              widget.isAdmin ?
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(text: donthaveAccString, style: TextStyle(color: ColorConst.black, fontWeight: FontWeight.w400, fontFamily: fontInterRegularString)),
                                      TextSpan(text: regiNowString, style: TextStyle(color: ColorConst.themeColor, fontWeight: FontWeight.w400, fontFamily: fontInterRegularString), recognizer: TapGestureRecognizer()..onTap = () {
                                      nextScreen(context, SelectPackageScreen(), onthenValue: (value) {});
                                      }),
                                    ],
                                  ),
                                ),
                              ) : Container(),

                              heightSpacer(size.height * 0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                    userloginprovider.islodering ? loaderDesign() : btnDesign(size,titles: loginString,onTap: () async {
                      await userloginprovider.handleSubmit(context,isAdmin: widget.isAdmin,formKey:userLoginFormKey);
                    }, isgradient: true),
                    heightSpacer(size.height * 0.03),
                  ],
                ),
              ),
            );
  }
}
