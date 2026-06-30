// ignore_for_file: strict_top_level_inference
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tax_hrm/api/authapi.dart';
import 'package:tax_hrm/api/newUser.dart';
import 'package:tax_hrm/api/registration_api.dart';
import 'package:tax_hrm/models/authclass/adminloginclass.dart';
import 'package:tax_hrm/models/regiostrationmodel/admin.dart';
import 'package:tax_hrm/models/regiostrationmodel/databasecreate.dart';
import 'package:tax_hrm/models/regiostrationmodel/registration.dart';
import 'package:tax_hrm/page/authpages/otpverification.dart';
import 'package:tax_hrm/page/bottom_bar_screen.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/randomcguid.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class RegistrationProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
    notifyListeners();
  }

  String?  setIpAddresUser;

  List packageList = [
    'TAX CRM',
    'TAX HRM',
  ];
  List<String> selectedPackages = [];

  setSelectPackage(item) {
    if(selectedPackages.contains(item)) {
      selectedPackages.remove(item);
    } else{
      selectedPackages.add(item);
    }

    notifyListeners();
  }

  void selectDefaultIfEmpty(List packageList) {
    if (selectedPackages.isEmpty && packageList.isNotEmpty) {
      selectedPackages.add(packageList[0]);
      notifyListeners();
    }
  }

  
  bool showVisiblePassword = true;
  setVisiblePassword() {
    showVisiblePassword = !showVisiblePassword;
    notifyListeners();
  }

  final formKey = GlobalKey<FormState>();

  TextEditingController fname = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController companyNames = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController adminemail = TextEditingController();
  TextEditingController mobile = TextEditingController();
  String countryCodes = '91';
  String countrytype ='IN';
  var rndnumber="";
  TextEditingController uname = TextEditingController();
  TextEditingController password = TextEditingController();

  List<RegistrationType> showregstypelist = [];
  RegistrationType? selectedFirms;

  void setSelectedFirms(RegistrationType? value) {
    selectedFirms = value;
    notifyListeners();
  }

  getRegistrationdata() async {
    islodering = true;
    await RegistrationApi().getRegistrationApi('').then((value) {
      showregstypelist = value;
      selectedFirms = showregstypelist.first;
    });
    setloading(false);
  }

  sendOtpMobile() {
    RegistrationApi().sendOtp('$countryCodes${'$countryCodes${mobile.text}'}').then((value) {
      var holdrespons = value;
      rndnumber =  holdrespons['data']; 
    });
    notifyListeners();
  }

  bool showUserExsiterror =false;
  bool showMobileExsiterror =false;
  checkUserNameData() {
    RegistrationApi().checkUserName(chcekusernames: uname.text).then((value) {
      var setReponse = value;
                                  
      showUserExsiterror = setReponse['Success'] ?? false;
    });
    notifyListeners();
  }

  Future checkUserMobileData(context) async {
    setloading(true);
   await RegistrationApi().checkUserMobileApi('${countryCodes.replaceAll("+", "")}${mobile.text}').then((value) {
      var setResponse = value;
                                  
      showMobileExsiterror = setResponse['Success'];

      if(showMobileExsiterror == true) {
        showtoastmessage('This mobile number is already registered $countryCodes${mobile.text}');
      } else{
        var rnd= Random();
        for (var i = 0; i < 6; i++) {
          rndnumber = rndnumber + rnd.nextInt(9).toString();
        }
        RegistrationApi().sendOtp('$countryCodes${mobile.text}').then((value) {
          var holdrespons = value;

          nextScreen(context, OtpVerificationOfLogin(holdrespons['data'], '${countryCodes.replaceAll("+", "")}${mobile.text}', '', 'create'), onthenValue: (value) {});
        });
      }
      setloading(false);
    });
  }

  //Create New User
  Future createnewuser(context) async{
    setloading(true);
    String  customerCjid =  generateGuid();
    var rndnumber = "";
    var rnd = Random();
    for (var i = 0; i < 3; i++) {
      rndnumber = rndnumber + rnd.nextInt(9).toString();
    }
    String joinname =   fname.text + lname.text;
    String first3word = joinname.substring(0,3).toUpperCase();
    String createdcuid = first3word + rndnumber;

    await RegistrationApi().createDataBase(setCustid: createdcuid).then((value)async{
      DataBaseCreate  databaseReponse =  value as DataBaseCreate;

      if(databaseReponse.success == true){
        await CreateUserMaster().createUserM(
            addres1: address.text,
            cguid: customerCjid,
            creatPassword: password.text,
            emails: adminemail.text,
            usernames: uname.text,
            lname: lname.text,
            fname: fname.text,
            newcompanyname: companyNames.text,
            mobilenumber: mobile.text,
            customerId: createdcuid,
            regsid: selectedFirms!.id,
            crmStatus: selectedPackages.contains('TAX CRM') ? true : false,
            hrmStatus: selectedPackages.contains('TAX HRM') ? true : false,
            officemanStatus:  false,
            setIpaddres: setIpAddresUser,
            context: context).then((value) async {
              CreateAdmin newuser = value as CreateAdmin;

               if(newuser.sucess == true){
                //-----------------------------  Login  ---------------------------------------\\
                await AuthLoginService().calllogin(uname.text.toString(), password.text.toString()).then((values) {

                  UserLogin loginReponse =values as UserLogin;

                  if(loginReponse.id == 0 && loginReponse.role == null){
                    showtoastmessage('Invaild Data');
                  }else{

                    if(loginReponse.hRM  != null){
                      if(loginReponse.role == 'Admin'){
                        nextScreen(context, AnimatedBottomBar(), onthenValue: (value) {});
                      }
                    }
                  }
                }).onError((error, stackTrace) {
                  setloading(false);
                });

              showtoastmessage('Registration Successful');
         }else{
          Navigator.pop(context);
          showtoastmessage('registration Failed');
         }
        });
      }
    });
  }
}
