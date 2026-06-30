// ignore_for_file: file_names, must_be_immutable, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/otpverificationprovider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class OtpVerificationOfLogin extends StatefulWidget {
  final  dynamic userDatas; 
  String loginPhone,loginEmail;
  // authType: 1. Login --> login = 2. Forgot --> forgot, 3. Registration Now --> create
  String authType;
  OtpVerificationOfLogin(this.userDatas,this.loginPhone,this.loginEmail, this.authType, {super.key});

  @override
  State<OtpVerificationOfLogin> createState() => _OtpVerificationOfLoginState();
}

class _OtpVerificationOfLoginState extends State<OtpVerificationOfLogin> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    Provider.of<Otpverificationprovider>(context, listen: false).loading();
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final otpverificationprovider = Provider.of<Otpverificationprovider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomeAppBar(backString, size,iconsOntap: () {backScreen(context);}),
              body: Padding(
                padding: EdgeInsets.all(size.width * 0.03),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            heightSpacer(size.height * 0.03),
                            Text(verificationCodeString,style: TextStyle(color: ColorConst.otpTitleColor, fontFamily: fontInterBoldString, fontSize: size.width * 0.07),),
                            heightSpacer(size.height * 0.008),
                            Text(otpTitlesString,textAlign: TextAlign.center,style: TextStyle(color: ColorConst.textgrey, fontFamily: fontInterMediumString, fontSize: 15),),
                            if(widget.loginEmail != "")...[ 
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Radio(activeColor: ColorConst.themeColor,value: true, groupValue: otpverificationprovider.otpType, onChanged: (val){otpverificationprovider.changeOtpType(val!);}),
                                  Text(mobileString,style: normalHeadingText(size,fontFamilys: fontInterSemiBoldString,fontSizes: 15.0),),
                                  Radio(activeColor: ColorConst.themeColor,value: false, groupValue: otpverificationprovider.otpType, onChanged: (val){otpverificationprovider.changeOtpType(val!);}),
                                  Text(emailString,style: normalHeadingText(size,fontFamilys: fontInterSemiBoldString,fontSizes: 15.0),),
                                ],
                              ),
                            ] else ...[
                              heightSpacer(size.height * 0.04),
                            ],
                            Text("$verifyOtpSendString ${otpverificationprovider.otpType == true ? "number ${maskMobile(widget.loginPhone)}" : "Email ${maskEmail(widget.loginEmail)}"} ",textAlign: TextAlign.center,style: TextStyle(color: ColorConst.textgrey, fontFamily: fontInterMediumString, fontSize: 15),),
                            heightSpacer(size.height * 0.04),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Pinput(
                                  length: 6,
                                  readOnly: otpverificationprovider.textFormReadOnly,
                                  controller: otpverificationprovider.setOtpController,
                                  obscureText: otpverificationprovider.isOtpHidden,
                                  obscuringCharacter: '*',
                                  onChanged: (value) {},
                                  onCompleted: (value) async {
                                    await otpverificationprovider.otphandleSubmit(context, widget.authType, widget.userDatas);
                                  },
                                  defaultPinTheme: PinTheme(width: size.width * 0.12,height: size.width * 0.12,textStyle: const TextStyle(fontSize: 14),decoration: BoxDecoration(borderRadius: BorderRadius.circular(9),border: Border.all(color: ColorConst.themeColor,width: 1),),),
                                  focusedPinTheme: PinTheme(width: size.width * 0.12,height: size.width * 0.12,textStyle: const TextStyle(fontSize: 14),decoration: BoxDecoration(borderRadius: BorderRadius.circular(9),border: Border.all(color: ColorConst.themeColor,width: 1),),),
                                  submittedPinTheme: PinTheme(width: size.width * 0.12,height: size.width * 0.12,textStyle: const TextStyle(fontSize: 14),decoration: BoxDecoration(borderRadius: BorderRadius.circular(9),border: Border.all(color: ColorConst.themeColor,width: 1),),),
                                ),
                                SizedBox(width: size.width * 0.03),
                                GestureDetector(onTap: otpverificationprovider.passordHideShowSelect,child: Icon(otpverificationprovider.isOtpHidden ? Icons.visibility_off : Icons.visibility,color: ColorConst.themeColor,),),
                              ],
                            ),
                            heightSpacer(size.height * 0.04),
                            otpverificationprovider.showexpired == true ? Text('Your OTP Expire !!',style: normalHeadingText(size),) :SizedBox(),
                            otpverificationprovider.showtimervalue == true ? Text('Please enter OTP within ${otpverificationprovider.remainingTime.toString()} seconds',style: normalHeadingText(size)) :SizedBox(),
                            
                            if(otpverificationprovider.showexpired == true || otpverificationprovider.showtimervalue == true)...[heightSpacer(size.height * 0.04),],

                            widget.authType == 'forgot' || widget.authType == 'create' ? otpverificationprovider.islodering ? loaderDesign() :  btnDesign(size,titles: verifyString, isgradient: true, borderColors: ColorConst.themeColor,textColors: ColorConst.white,onTap: () async {
                              await otpverificationprovider.otphandleSubmit(context,widget.authType,widget.userDatas);
                            },) :
                            otpverificationprovider.islodering ? loaderDesign() :
                            Row(
                              children: [
                                Expanded(child: otpverificationprovider.isSendOtpLoader == true ? loaderDesign() : btnDesign(size,titles: sendOtpString,onTap: otpverificationprovider.enterUserOtp != ""?(){}:() async {await otpverificationprovider.sendOtphandleSubmit(isAdmin: otpverificationprovider.otpType,mobileNo: widget.loginPhone,emailAddress: widget.loginEmail);}, isgradient: true,),),
                                widthSpacer(size.width*0.02),
                                Expanded(
                                  child: btnDesign(size,titles: verifyString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () async {
                                    await otpverificationprovider.otphandleSubmit(context,widget.authType,widget.userDatas);
                                  },),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
  }
}
