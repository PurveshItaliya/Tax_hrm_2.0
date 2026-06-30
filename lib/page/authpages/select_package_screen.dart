import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/authpages/registration.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/registrationprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class SelectPackageScreen extends StatefulWidget {
  const SelectPackageScreen({super.key});

  @override
  State<SelectPackageScreen> createState() => _SelectPackageScreenState();
}

class _SelectPackageScreenState extends State<SelectPackageScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<RegistrationProvider>(context, listen: false).selectedPackages.clear();
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(size.width * 0.03),
        child: Row(
          children: [
            Expanded(child: btnDesign(size, titles: cancelString,onTap: (){
              backScreen(context);
            },borderRadiused: 4.0, bgColor: ColorConst.scaffoldColor, borderColors: ColorConst.themeColor, textColors: ColorConst.darkGreenColor, fontSizes: size.width * 0.04,  borderWidth: 2.5)),
            widthSpacer(size.width * 0.04),
            Expanded(child: btnDesign(size, titles: nextString,onTap: (){
              registrationProvider.selectDefaultIfEmpty(registrationProvider.packageList);
              nextScreen(context, RegistrationForm(), onthenValue: (value) {});
            },borderRadiused: 4.0,isgradient: true, fontSizes: size.width * 0.04)),
          ],
        ),
      ),
      body: Padding(
        padding:  EdgeInsets.all(size.width * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:  EdgeInsets.symmetric(vertical: size.height * 0.02),
              child: Text(selectPackageString, style: TextStyle(fontWeight: FontWeight.w500,  fontFamily: fontInterMediumString, fontSize: size.width * 0.055)),
            ),

            ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: registrationProvider.packageList.length,
              itemBuilder: (context, index) {
                final isSelected = registrationProvider.selectedPackages.contains(registrationProvider.packageList[index]);
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? ColorConst.themeColor : ColorConst.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? ColorConst.transparent : ColorConst.grey, width: 2),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Transform.scale(
                        scale: size.width * 0.0035, 
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            registrationProvider.setSelectPackage(registrationProvider.packageList[index]);
                          },
                          activeColor: ColorConst.white,
                          checkColor: ColorConst.themeColor,
                          side: BorderSide(color: ColorConst.grey, width: 2),
                        ),
                      ),
                      title: Text(registrationProvider.packageList[index], style: TextStyle(fontWeight: FontWeight.w500,  fontFamily: fontInterMediumString, fontSize: size.width * 0.045, color: isSelected ? ColorConst.white : ColorConst.black)),
                      onTap: () {
                        registrationProvider.setSelectPackage(registrationProvider.packageList[index]);
                      },
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return heightSpacer(size.height * 0.02);
              },
            ),
          ],
        ),
      ),
    );
  }
}