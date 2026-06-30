import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/department/Department_master_screen.dart';
import 'package:tax_hrm/page/department/designation_master_screen.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class DepartmentMenuScreen extends StatefulWidget {
  const DepartmentMenuScreen({super.key});

  @override
  State<DepartmentMenuScreen> createState() => _DepartmentMenuScreenState();
}

class _DepartmentMenuScreenState extends State<DepartmentMenuScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomeAppBar(departmentString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
              body: Padding(
                padding: EdgeInsets.all(size.height*0.03),
                child:  Row(
                  children: [
                    Expanded(
                      child: departmentImageandTitle(size, departmentMasterString, departmentimgString, (){
                        nextScreen(context, DepartmentScreen(),onthenValue: (val){},);
                      },),
                    ),
                    widthSpacer(size.width*0.03),
                    Expanded(
                      child: departmentImageandTitle(size, designationMasterString, designationimgString, (){
                        nextScreen(context, DesignationScreen(),onthenValue: (val){},);
                      },),
                    ),
                  ],
                )  
              )
            );
  }
}
