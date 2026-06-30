import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_hrm/page/authpages/userloginpage.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<SelectLoginClass> loginClassList = [
    SelectLoginClass(title: welcomeTitle1String, description: welcomeDec1String, icon: Icons.keyboard_arrow_right_rounded,),
    SelectLoginClass(title: welcomeTitle2String, description: welcomeDec2String, icon: Icons.keyboard_arrow_right_rounded,),
  ];
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    return WillPopScope(
      onWillPop: () => commonDialogBoxDesign(context: context, size: size, title: exitString),
      child: Scaffold(
          backgroundColor: ColorConst.scaffoldColor,
          body: Padding(
            padding:  EdgeInsets.all(size.width * 0.03),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/lottie/welcome.json', height: size.height * 0.35, fit: BoxFit.cover),
          
                  heightSpacer(size.height * 0.03),
          
                  Text(welcomeTaxHrmString, style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * 0.07)),
                  Text(welcomeDecString, style: TextStyle(fontFamily: fontInterBoldString, fontSize: size.width * 0.04,  color: ColorConst.grey), textAlign: TextAlign.center),
          
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: loginClassList.length,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: size.height * 0.03),
                    separatorBuilder: (context, index) {
                      return heightSpacer(size.height * 0.015);
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: (){
                          if(index == 0){
                            nextScreen(context, UserLoginPage(isAdmin: false),onthenValue: (value){});
                          } else {
                            nextScreen(context, UserLoginPage(isAdmin: true),onthenValue: (value){});
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.only(left:size.width * 0.02,top: size.width * 0.02,bottom: size.width * 0.02,),
                          decoration: BoxDecoration(
                            color: ColorConst.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: ColorConst.grey, spreadRadius: 0.1, blurRadius: 0.1),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              titleAlignment: ListTileTitleAlignment.top,
                              title: Text(loginClassList[index].title, style: TextStyle(fontFamily: fontInterBoldString, fontSize: size.width * 0.05)),
                              subtitle: Text(loginClassList[index].description, style: TextStyle(fontFamily: fontInterMediumString, fontSize: size.width * 0.035, color: ColorConst.textgrey)),
                              trailing: Icon(loginClassList[index].icon, size: 30),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}