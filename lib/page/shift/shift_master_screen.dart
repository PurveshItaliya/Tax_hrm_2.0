import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class ShiftMasterScreen extends StatefulWidget {
  const ShiftMasterScreen({super.key});

  @override
  State<ShiftMasterScreen> createState() => _ShiftMasterScreenState();
}

class _ShiftMasterScreenState extends State<ShiftMasterScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<ShiftMasterProvider>(context,listen: false).shiftGroupMasterLoadingData();
  }

  final userShiftGrounpFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final shiftMasterProvider =  Provider.of<ShiftMasterProvider>(context);
    Provider.of<LanguageProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: shiftMasterProvider.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.03),
                child: iconWithTextBtnDesign(size,addShiftGroupString,isIcon: false,onTap: () {
                  shiftMasterProvider.shiftFNcontroller.text = "";
                  shiftMasterProvider.shiftSNcontroller.text = "";
                  shiftMasterProvider.shiftGroupHandleSubmit(context,size,userShiftGrounpFormKey,addEditFlag:true,setdid: "",);
                },isgradient: true,isImage: false),
              ),
              appBar: showCustomeAppBar(shiftGroupMasterString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData();
                },
                widgetDesign: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: shiftMasterProvider.islodering ? departmentMasterShimmer(size,false) : Column(
                    children: [
                      shiftMasterProvider.mainShiftGroupList.isEmpty
                          ? Expanded(child: SingleChildScrollView(child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noShiftAddedString,nodataFoundsImagString)))) 
                          : Expanded(
                            child: ListView.builder(
                              itemCount: shiftMasterProvider.mainShiftGroupList.length,
                              padding: EdgeInsets.only(
                                left: size.height * 0.01,
                                right: size.height * 0.01,
                                bottom: size.height * 0.10, // ✅ IMPORTANT
                              ),
                              itemBuilder: (context, index) {
                                return departmentCard(
                                false,
                                size: size,titles: shiftMasterProvider.mainShiftGroupList[index].shiftGroupFname.toString().toLowerCase() == 'null' ?"": shiftMasterProvider.mainShiftGroupList[index].shiftGroupFname.toString(),deleteOntap: (){
                                  showDeleteDialog(context,size,yesOntap: () {
                                    shiftMasterProvider.deleteShiftHandleSubmit(context,setdid: shiftMasterProvider.mainShiftGroupList[index]);
                                  },noOnTap: (){Navigator.pop(context);});
                                },editOntap: (){
                                  shiftMasterProvider.editShiftGroupHandleSubmit(context,size,userShiftGrounpFormKey,setdid: shiftMasterProvider.mainShiftGroupList[index]);
                                },borderColor: ColorConst.greyColor,
                                departmentName:  "$shiftShortNameString :- ${shiftMasterProvider.mainShiftGroupList[index].shiftGroupSname.toString().toLowerCase() == 'null' ?"": shiftMasterProvider.mainShiftGroupList[index].shiftGroupSname.toString()}",
                              );
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            );
  }
}
