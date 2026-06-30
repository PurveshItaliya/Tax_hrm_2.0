// ignore_for_file: must_be_immutable

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/usermasterprovider.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/utils/validation.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:tax_hrm/page/employee_master/employee_add_edit_screen.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';

class ProfileViewPage extends StatefulWidget {
  bool isEdit;
  ProfileViewPage({super.key,required this.isEdit});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {

  final userProfileFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeAreaBgAndTextColor(context,);
    });
    Provider.of<UserMasterService>(context, listen: false).userProfileData(context);
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(
      context,
    );
    final userMasterService = Provider.of<UserMasterService>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomeAppBar(
                personalInfoString,
                size,
                titleColors: ColorConst.appbarTextColor,
                iconsOntap: () {
                  backScreen(context);
                },
                actions: curentUser['Role'] == 'Admin'
                    ? <Widget>[
                        IconButton(
                          onPressed: () async {
                            Employeelists? targetEmp = userMasterService.setEmpProfile;
                            if (targetEmp == null && userMasterService.setAdminProfile != null) {
                              final admin = userMasterService.setAdminProfile!;
                              targetEmp = Employeelists()
                                ..id = admin.id
                                ..firstName = admin.firstName
                                ..lastName = admin.lastName
                                ..mobile1 = admin.mobile
                                ..email = admin.email
                                ..userName = admin.username
                                ..password = admin.password
                                ..role = admin.role ?? 'Admin'
                                ..isActive = admin.isActive ?? true
                                ..isAdmin = true
                                ..custId = admin.custId
                                ..cguid = admin.cguid
                                ..iPAddress = admin.iPAddress
                                ..cRM = admin.cRM
                                ..officeman = admin.officeman
                                ..hRM = admin.hRM;
                            }
                            if (targetEmp != null) {
                              await nextScreen(
                                context,
                                EmployeeMasterAddEditScreen(
                                  flag: 'U',
                                  selectedemp: targetEmp,
                                ),
                                onthenValue: (value) {},
                              );
                              if (context.mounted) {
                                userMasterService.userProfileData(context);
                              }
                            } else {
                              showtoastmessage('Profile data not available');
                            }
                          },
                          icon: Icon(
                            Icons.edit_square,
                            color: ColorConst.appbarTextColor,
                          ),
                        ),
                        widthSpacer(10),
                      ]
                    : null,
              ),
              body: userMasterService.islodering ? userProfileShimmer(size) : Padding(
                padding: EdgeInsets.all(size.height * 0.02,),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: userProfileFormKey,
                          autovalidateMode: userMasterService.autovalidateMode,
                          child:Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(curentUser['Role'] == 'Admin')...{
                                Center(child: Container(height: size.height * 0.15,width: size.width * 0.3,decoration: BoxDecoration(color: ColorConst.grey,shape: BoxShape.circle,border: Border.all(color: Colors.black),),child: Center(child: Text(curentUser['Username'].toString().substring(0, 1),style: TextStyle(fontSize: size.height * 0.065, fontWeight: FontWeight.bold),),),),)    
                              } else ...{
                                if(!widget.isEdit)...[
                                  Stack(
                                    children: [
                                      Center(child: Container(height: size.height * 0.15,width: size.width * 0.3,decoration: BoxDecoration(color: ColorConst.grey,shape: BoxShape.circle,border: Border.all(color: Colors.black),image: userMasterService.images != null? DecorationImage(image: FileImage(File(userMasterService.images!.path))): userMasterService.setEmpProfile?.img != null? DecorationImage(image: NetworkImage('${apibaseurl}UploadFiles/Emp/${userMasterService.setEmpProfile!.img}'), fit: BoxFit.cover): null,),child: userMasterService.images == null && userMasterService.setEmpProfile?.img == null ? Center(child: Text(curentUser['FirstName'].toString().substring(0, 1),style: TextStyle(fontSize: size.height * 0.065, fontWeight: FontWeight.bold),),): null,),),
                                      Padding(padding:  EdgeInsets.only(top: size.height * 0.079,left: size.height * 0.26),child: GestureDetector(onTap: (){userMasterService.getImage();},child: Container(decoration:  BoxDecoration(color: ColorConst.themeColor, shape: BoxShape.circle, ),child: Padding(  padding: const EdgeInsets.all(8.0),  child: Icon(Icons.photo_camera,color: ColorConst.white,size: size.height * 0.03,),)),),),
                                    ],
                                  ),
                                  heightSpacer(size.height*0.01),
                                  Center(child: Text('${userMasterService.firstNameControllerS.text} ${userMasterService.lastNameControllerS.text}',style: TextStyle(fontSize: size.height * 0.02,fontWeight: FontWeight.bold),)),
                                ],
                              },
                              if(curentUser['Role'] == 'User')...[
                                heightSpacer(size.height*0.01),
                                CommonTextField(controller: userMasterService.departmentControllerS,hintText: departmentYourNameString,fillColors: ColorConst.white,readOnly: true,showHeading: departmentNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,),
                                heightSpacer(size.height*0.02),
                                CommonTextField(controller: userMasterService.positionControllerS,hintText: enterYourPositionString,fillColors: ColorConst.white,readOnly: true,showHeading: positionString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,),
                              ],
                              heightSpacer(size.height*0.02),
                              CommonTextField(controller: userMasterService.usernamecontroller,hintText: enterYourUsernameString,fillColors: ColorConst.white,readOnly: true,showHeading: userNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,),
                              heightSpacer(size.height*0.02),
                              CommonTextField(controller: userMasterService.passwordController,obscureText: userMasterService.showpassword,hintText: enterYourPasswordString,fillColors: ColorConst.white,readOnly: curentUser['Role'] == 'User' ?true:widget.isEdit?true:false,showHeading: passwordString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,suffixIcon: IconButton(onPressed: userMasterService.passordHideShow, icon: Icon(userMasterService.showpassword == true ? Icons.visibility :Icons.visibility_off,color: ColorConst.passwordColor,)),validator: (p0) => allValidation(p0!)),
                              heightSpacer(size.height*0.02),
                              if(curentUser['Role'] == 'User')...[
                                Row(
                                  children: [
                                    Expanded(child: CommonTextField(controller: userMasterService.officeControoler,hintText: enterOfficeString,fillColors: ColorConst.white,readOnly: true,showHeading: officeString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,),),
                                    widthSpacer(size.width*0.02),
                                    Expanded(child: CommonTextField(controller: userMasterService.workTypeController,hintText: enterWorkTypeString,fillColors: ColorConst.white,readOnly: true,showHeading: workTypeString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,),),
                                  ],
                                ),
                                heightSpacer(size.height*0.02),
                              ],
                              CommonTextField(controller: userMasterService.firstNameControllerS,hintText: enterYourFirstNameString,fillColors: ColorConst.white,readOnly: widget.isEdit?true:false,showHeading: firstNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,validator: (p0) => allValidation(p0!),),
                              heightSpacer(size.height*0.02),
                              CommonTextField(controller: userMasterService.lastNameControllerS,hintText: enterYourLastNameString,fillColors: ColorConst.white,readOnly:  widget.isEdit?true:false,showHeading: lastNameString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,),
                              heightSpacer(size.height*0.02),
                              CommonTextField(controller: userMasterService.emailController,hintText: enterYourEmailString,fillColors: ColorConst.white,readOnly:  widget.isEdit?true:false,showHeading: emailString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,validator: (p0) => allValidEmail(p0!),),
                              heightSpacer(size.height*0.02),
                              PhoneNumberTextFiled(controller: userMasterService.mobileController,hintText: enterYourMobile1String,fillColors: ColorConst.white,showHeading: mobile1String,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,getcodes: userMasterService.phoneNumber!.countryISOCode,onChanged: (val){
                              userMasterService.mobil1countryCodes = val.countryCode.toString();
                              },readOnly:  widget.isEdit?true:false,validator: (phone) {if (phone == null || phone.number.isEmpty) {return 'Mobile number is required';}if(phone.number.isNotEmpty){if (phone.number.length < 10) {return 'Enter valid mobile number';}} else {return null;}return null;},),
                              heightSpacer(size.height*0.02),
                              if(curentUser['Role'] == 'User')...[
                                PhoneNumberTextFiled(controller: userMasterService.mobileController2,hintText: enterYourMobile2String,fillColors: ColorConst.white,showHeading: mobile2String,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,getcodes: userMasterService.phoneNumber2?.countryISOCode,onChanged: (val){
                                userMasterService.mobil2countryCodes = val.countryCode.toString();
                                },readOnly:  widget.isEdit?true:false,validator: (phone) {if(phone!.number.isNotEmpty){if (phone.number.length < 10) {return 'Enter valid mobile number';}} else {return null;}return null;},),
                                heightSpacer(size.height*0.02),
                              ],
                              if(curentUser['Role'] == 'User')...[
                                Row(
                                  children: [
                                    Expanded(child: CommonTextField(controller: userMasterService.selectDOBController,hintText: selectDOBString,fillColors: ColorConst.white,readOnly:  true,showHeading: dateofBirthString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,prefixIcon: IconButton(onPressed: widget.isEdit?(){}:(){
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      userMasterService.pickUserStartDate(context,true);}, icon: Icon(Icons.calendar_month_outlined,color: ColorConst.selectDateColors,),),),
                                    ),
                                    widthSpacer(size.width*0.02),
                                    Expanded(child: CommonTextField(controller: userMasterService.selectDOJController,hintText: selectDOJString,fillColors: ColorConst.white,readOnly:  true,showHeading: dateOfJoiningString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,prefixIcon: IconButton(onPressed: widget.isEdit?(){}:(){
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      userMasterService.pickUserStartDate(context,false);}, icon: Icon(Icons.calendar_month_outlined,color: ColorConst.selectDateColors,),),),
                                    ),
                                  ],
                                ),
                              ]else...[
                                CommonTextField(controller: userMasterService.regtypecontroller,hintText: enterYourRegistrationFirmTypString,fillColors: ColorConst.white,readOnly: true,showHeading: registrationFirmTypString,fontFamilys: fontInterMediumString,hintColor: ColorConst.hintextFormColors,),
                              ],
                            ],
                          ) 
                        ),
                      ),
                    ),
                    heightSpacer(size.height*0.02),
                    widget.isEdit ? SizedBox() : btnDesign(size,titles: saveString,onTap: (){
                      userMasterService.updateHandleSubmit(context,userProfileFormKey);
                    }, isgradient: true,borderRadiused: 25.0),
                  ],
                ),
              ),
            );
  }
}
