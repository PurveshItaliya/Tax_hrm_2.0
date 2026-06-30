// ignore_for_file: strict_top_level_inference

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/regiostrationmodel/registration.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/registrationprovider.dart';
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

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  @override
  void initState() {
    super.initState();
    Provider.of<RegistrationProvider>(context, listen: false).getRegistrationdata();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final registrationProvider = Provider.of<RegistrationProvider>(context);
    return checkInterNetConnection.connectionType == 0 ? const NoInternetViewPage() : Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: showCustomeAppBar(backString, size,iconsOntap: () {
        backScreen(context);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:  registrationProvider.islodering ? Container() : Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
        child: btnDesign(size, titles: submitString,isgradient: true, onTap: () {
          if(registrationProvider.formKey.currentState!.validate()) {

            registrationProvider.checkUserMobileData(context);
            
          }else{
            if(registrationProvider.mobile.text.isEmpty) {
              registrationProvider.mobile.text ='0';
            }
          }
        },),
      ),
      body: registrationProvider.islodering ? scanloading() : Form(
        key: registrationProvider.formKey,
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.03),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:  EdgeInsets.symmetric(vertical: size.height * 0.008),
                      child: Text(regFirmTypeString, style: textStyleDesign(size)),
                    ),
                    DropdownButtonFormField2<RegistrationType>(
                      isExpanded: true,
                      // hint: Text('Select $regFirmTypeString'),
                      hint: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          registrationProvider.selectedFirms?.name ?? 'Select $regFirmTypeString',
                          style: TextStyle(
                            fontSize: size.height * 0.018,
                            color: registrationProvider.selectedFirms == null ? ColorConst.grey : ColorConst.black,
                          ),
                        ),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ColorConst.white,
                        border: OutlineInputBorder(borderSide: BorderSide(color: ColorConst.grey, width: 1.3), borderRadius: BorderRadius.circular(4)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorConst.grey, width: 1.3), borderRadius: BorderRadius.circular(4)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorConst.grey, width: 1.3), borderRadius: BorderRadius.circular(4)),
                        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorConst.grey, width: 1.3), borderRadius: BorderRadius.circular(4)),
                        focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorConst.grey, width: 1.3), borderRadius: BorderRadius.circular(4)),
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      items: registrationProvider.showregstypelist.map(
                      (item) => DropdownItem<RegistrationType>(
                        value: item,
                        child: Text(
                          item.name.toString(),
                          style: TextStyle(
                            fontSize: size.height * 0.018,
                          ),
                        ),
                      )).toList(),
                      onChanged: (value) {
                        registrationProvider.setSelectedFirms(value);
                      },
                      validator: (value) {
                        if(value == null) {
                          return 'Select $regFirmTypeString';
                        }
                        return null;
                      },
                      dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(color: ColorConst.white)),
                      // menuItemStyleData: MenuItemStyleData(height: size.height * 0.05),
                    ),
                  ],
                ),
                
                heightSpacer(size.height * 0.015),
                CommonTextField(controller: registrationProvider.fname, hintText: '$enterYourString $firstNameString', showHeading: firstNameString, showTextStyle:  textStyleDesign(size), fillColors: ColorConst.white, validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $firstNameString';
                  }
                  return null;
                }),
                
                heightSpacer(size.height * 0.015),
                CommonTextField(controller: registrationProvider.lname, hintText: '$enterYourString $lastNameString', showHeading: lastNameString, showTextStyle:  textStyleDesign(size), fillColors: ColorConst.white, validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $lastNameString';
                  }
                  return null;
                }),
                
                heightSpacer(size.height * 0.015),
                CommonTextField(controller: registrationProvider.companyNames, hintText: '$enterYourString $companyNameString', showHeading: companyNameString, showTextStyle:  textStyleDesign(size), fillColors: ColorConst.white, validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $companyNameString';
                  }
                  return null;
                }),
                
                heightSpacer(size.height * 0.015),
                CommonTextField(controller: registrationProvider.address, hintText: '$enterYourString $addressString', showHeading: addressString, showTextStyle:  textStyleDesign(size), fillColors: ColorConst.white, validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $addressString';
                  }
                  return null;
                }),
                
                heightSpacer(size.height * 0.015),
                CommonTextField(controller: registrationProvider.adminemail, hintText: '$enterYourString $emailString', showHeading: emailString, showTextStyle:  textStyleDesign(size), fillColors: ColorConst.white, validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $emailString';
                  }
                  return null;
                }),
                
                heightSpacer(size.height * 0.015),
                Padding(
                   padding:  EdgeInsets.only(top: size.height * 0.02),
                   child: PhoneNumberTextFiled(showHeading: mobile1String, hintText: '$enterYourString $mobile1String', getcodes: registrationProvider.countrytype, onChanged: (value) {
                    registrationProvider.countryCodes = value.countryCode.toString();
                   }, controller: registrationProvider.mobile, fillColors: ColorConst.white),
                ),
                
                heightSpacer(size.height * 0.015),
                CommonTextField(controller: registrationProvider.uname, hintText: '$enterYourString $userNameString', showHeading: userNameString, showTextStyle:  textStyleDesign(size), fillColors: ColorConst.white, validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $addressString';
                  } else if(registrationProvider.showUserExsiterror == true) {
                    return 'UserName Already Exist';
                  }
                  return null;
                }, onChanged: (value) {
                  registrationProvider.checkUserNameData();
                }),
                
                heightSpacer(size.height * 0.015),
                CommonTextField(controller: registrationProvider.password, hintText: '$enterYourString $passwordString', showHeading: passwordString, showTextStyle:  textStyleDesign(size), fillColors: ColorConst.white, validator: (value) {
                  if(value!.isEmpty) {
                    return '$pleaseEnterString $passwordString';
                  }
                  return null;
                }, suffixIcon: IconButton(
                  onPressed: () {
                    registrationProvider.setVisiblePassword();
                  },
                  icon: Icon(registrationProvider.showVisiblePassword ? Icons.visibility : Icons.visibility_off),
                ), obscureText: registrationProvider.showVisiblePassword),

                heightSpacer(size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle textStyleDesign(size) {
    return TextStyle(fontSize: size.height * 0.018, fontWeight: FontWeight.w500, fontFamily: fontInterMediumString);
  }
}