// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/shift/shift_mater_design.dart';
import 'package:tax_hrm/page/shift/shift_timing/add_shift_timing_master_screen.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/common_popmenu.dart';
import 'package:tax_hrm/widigets/commonpaginator.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class ShiftTimingMasterScreen extends StatefulWidget {
  const ShiftTimingMasterScreen({super.key});

  @override
  State<ShiftTimingMasterScreen> createState() => _ShiftTimingMasterScreenState();
}

class _ShiftTimingMasterScreenState extends State<ShiftTimingMasterScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<ShiftMasterProvider>(context,listen: false,).shiftTimingLoadingData().then((value) {
      Provider.of<AppPaginationProvider>(context,listen: false).countPaginationPage(Provider.of<ShiftMasterProvider>(context,listen: false).mainShiftMasterGroupList,0);
    },);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final shiftTiminigMasterProvider =  Provider.of<ShiftMasterProvider>(context);
    final appPaginationController = Provider.of<AppPaginationProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: shiftTiminigMasterProvider.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.06),
                child: iconWithTextBtnDesign(size,addShiftMasterString,isIcon: false,onTap: () {
                  shiftTiminigMasterProvider.clearData();
                  nextScreen(context,AddShiftTimingMasterScreen(getShiftMasterData: null,addEditFlag: true,),onthenValue: (value) {
                    _loadAllData();
                  });
                },isgradient: true,isImage: false),
              ),
              appBar: showCustomeAppBar(shiftMasterString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);},actions: [
                IconButton(onPressed: (){
                  showNumberOfData(context, size,shiftTiminigMasterProvider.mainShiftMasterGroupList,);
                }, icon:const Icon(Icons.more_vert))
              ],),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData();
                },
                widgetDesign: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: shiftTiminigMasterProvider.islodering ? departmentMasterShimmer(size,false) : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shiftTiminigMasterProvider.mainShiftMasterGroupList.isEmpty
                      ? Expanded(child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, addShiftMasterString,nodataFoundsImagString)))) 
                      : Expanded(
                        child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: shiftTiminigMasterProvider.mainShiftMasterGroupList.length,
                          padding: EdgeInsets.only(bottom: size.height * 0.075),
                          itemBuilder: (context, index) {
                            final shiftStr = shiftTiminigMasterProvider.mainShiftMasterGroupList[index].shiftDuration.toString();
                            String formatted = '';
                            if (shiftStr.isNotEmpty) {
                              final parsed = dateFormatdateHours(shiftStr);
                              formatted = dateFormatHours(parsed);
                            }
                            if(appPaginationController.endIndexShow > index && appPaginationController.startIndextoShow <= index) {
                              return shiftTimingCard(size: size,titles: shiftTiminigMasterProvider.mainShiftMasterGroupList[index].shiftFName,shotName: shiftTiminigMasterProvider.mainShiftMasterGroupList[index].positionName,shiftDuration: '$formatted Hr',shiftBeginTime: shiftTiminigMasterProvider.mainShiftMasterGroupList[index].beginTime == null ?'':dateFormatTimeHours(DateTime.parse(shiftTiminigMasterProvider.mainShiftMasterList[index].beginTime.toString())),shiftEndTime: shiftTiminigMasterProvider.mainShiftMasterGroupList[index].endTime == null ?'':dateFormatTimeHours(DateTime.parse(shiftTiminigMasterProvider.mainShiftMasterList[index].endTime.toString())),deleteOntap: () {
                                showDeleteDialog(context,size,yesOntap: () {
                                  shiftTiminigMasterProvider.deleteShiftTimingHandleSubmit(context,setdid: shiftTiminigMasterProvider.mainShiftMasterGroupList[index]).then((value) async {
                                    await appPaginationController.countPaginationPage(shiftTiminigMasterProvider.mainShiftMasterGroupList,0);
                                  },);
                                },noOnTap: (){Navigator.pop(context);});
                              },editOntap: () async {
                                await shiftTiminigMasterProvider.editHandleSubmit(context,shiftTiminigMasterProvider.mainShiftMasterGroupList[index],).then((value) {
                                  _loadAllData();
                                },);
                              });
                            } else{
                              return SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      shiftTiminigMasterProvider.mainShiftMasterGroupList.isEmpty ? SizedBox() : CommonPagination(appPaginationController.setSelectedPaginationPage, appPaginationController.setTotalPaginationPage, (int index) {
                        appPaginationController.countPaginationPage(shiftTiminigMasterProvider.mainShiftMasterGroupList, index);
                      },),
                    ],
                  )
                ),
              ),
            );
  }
}
