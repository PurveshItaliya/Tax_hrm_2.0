// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/admin_leave_master/add_admin_leave_master_screen.dart';
import 'package:tax_hrm/page/admin_leave_master/admin_leave_master_design.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/leavemployeeprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class AdminLeaveMasterScreen extends StatefulWidget {
  const AdminLeaveMasterScreen({super.key});

  @override
  State<AdminLeaveMasterScreen> createState() => _AdminLeaveMasterScreenState();
}

class _AdminLeaveMasterScreenState extends State<AdminLeaveMasterScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    await Provider.of<LeaveEmployeeeMastServices>(context, listen: false).adminloadingData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final leaveEmployeeeMastServices =  Provider.of<LeaveEmployeeeMastServices>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: leaveEmployeeeMastServices.islodering ? SizedBox() : iconWithTextBtnDesign(size,addLeaveString,isIcon: false,onTap: () async {
                await leaveEmployeeeMastServices.clearData();
                nextScreen(context, AddAdminLeaveMasterScreen(addEditFlag: true, getAdminLeaveData: null),onthenValue: (value) {});
              },isgradient: true,isImage: false),
              appBar: showCustomeAppBar(leaveMasterString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);},),
              body: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: leaveEmployeeeMastServices.islodering ? departmentMasterShimmer(size,false) : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leaveEmployeeeMastServices.getAllleaveTypesList.isEmpty
                      ? Expanded(
                        child: RefreshIndicator(
                          color: ColorConst.white,
                          backgroundColor: ColorConst.themeColor,
                          onRefresh: _loadAllData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              width: size.width,
                              height: size.height*0.65,
                              child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString),
                            ),
                          ),
                        ),
                      ) 
                      : Expanded(
                        child: RefreshIndicator(
                          color: ColorConst.white,
                          backgroundColor: ColorConst.themeColor,
                          onRefresh: _loadAllData,
                          child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: leaveEmployeeeMastServices.getAllleaveTypesList.length,
                          padding: EdgeInsets.only(bottom: size.height * 0.075),
                          itemBuilder: (context, index) {
                            return adminLeaveCard(size: size,titles: leaveEmployeeeMastServices.getAllleaveTypesList[index].leaveTypeFName,leaveTypes: "${leaveEmployeeeMastServices.getAllleaveTypesList[index].leaveType} Leave",monthlyValue: leaveEmployeeeMastServices.getAllleaveTypesList[index].monthly.toString(),yearlyValue: leaveEmployeeeMastServices.getAllleaveTypesList[index].yearlyLimit.toString(),quarterlyValue: leaveEmployeeeMastServices.getAllleaveTypesList[index].quarterly.toString(),halfYearlyValue: leaveEmployeeeMastServices.getAllleaveTypesList[index].halfYear == "" ? "0" : leaveEmployeeeMastServices.getAllleaveTypesList[index].halfYear.toString(),considerWeekly: leaveEmployeeeMastServices.getAllleaveTypesList[index].considerWeeklyOff == true ?yesDeleteString.toString().split(",").first.toString():noCancelString.toString().split(",").first.toString(),bgColorValue: leaveEmployeeeMastServices.getAllleaveTypesList[index].considerWeeklyOff == true ?ColorConst.themeColor:ColorConst.red,considerHoliday: leaveEmployeeeMastServices.getAllleaveTypesList[index].considerHoliday == true ?yesDeleteString.toString().split(",").first.toString():noCancelString.toString().split(",").first.toString(),holidayColors: leaveEmployeeeMastServices.getAllleaveTypesList[index].considerHoliday == true ?ColorConst.themeColor:ColorConst.red,editOntap: () async {
                              await leaveEmployeeeMastServices.addEditFunction(context,false,getAdminLeaveData: leaveEmployeeeMastServices.getAllleaveTypesList[index]); 
                            },deleteOntap: (){
                              showDeleteDialog(context,size,yesOntap: () {leaveEmployeeeMastServices.deleteAdminLeaveMaster(context,leaveTypeID: leaveEmployeeeMastServices.getAllleaveTypesList[index].leaveTypeId,);},noOnTap: (){Navigator.pop(context);});
                            },);
                          },
                        ),
                        ),
                      ),
                    ],
                  )
                ),
            );
  }
}
