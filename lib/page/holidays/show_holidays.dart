// ignore_for_file: strict_top_level_inference, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/page/holidays/add_holidays.dart';
import 'package:tax_hrm/provider/holidayprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class ShowHolidayViews extends StatefulWidget {
  const ShowHolidayViews({super.key});

  @override
  State<ShowHolidayViews> createState() => _ShowHolidayViewsState();
}

class _ShowHolidayViewsState extends State<ShowHolidayViews> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    await Provider.of<HolidayeMastServices>(context, listen: false).loadingData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final holidayeMastServices = Provider.of<HolidayeMastServices>(context);
    safeAreaBgAndTextColor(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(holidayString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: holidayeMastServices.islodering ? SizedBox() : curentUser['Role'] == 'Admin' ? Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.03),
              child: iconWithTextBtnDesign(size,addNewHolidayString,isIcon: false,onTap: () async {
                await holidayeMastServices.clearHolidayData();
                nextScreen(context, AddHolidayScreen(addEditFlag: true, getHolidayViewsData: null),onthenValue: (value) {});
              },isgradient: true,isImage: false),
            ):SizedBox(),
            body: refreshIndicatorDesign(
              onRefreshOntap: () {
                return _loadAllData();
              },
              widgetDesign: Padding(
                padding: EdgeInsets.only(top: size.height*0.03,bottom: size.height*0.03),
                child: holidayeMastServices.islodering ? 
                  holidaysShimmer(size): 
                  holidayeMastServices.showHolidayList.isEmpty
                    ? SizedBox(width: size.width,child: noDataFoundsDesign(size, noHolidaysAddedString,nodataFoundsImagString))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: holidayeMastServices.showHolidayList.length,
                        padding: EdgeInsets.only(top: size.height*0.01,bottom: curentUser['Role'] == 'Admin' ? size.height*0.12 : size.height*0.01),
                        separatorBuilder: (context, index) {
                          return heightSpacer(size.height * 0.02);
                        },
                        itemBuilder: (context, index) {
                          return Container(
                            padding: EdgeInsets.all(size.width*0.025),
                            decoration: BoxDecoration(
                              color: ColorConst.white,
                              border: Border(bottom: BorderSide(color: ColorConst.containerBorderColor,width: 1),top: BorderSide(color: ColorConst.containerBorderColor,width: 1))
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 25,backgroundColor: ColorConst.circleBgColors,child: Image.asset(calendarIconsString,height: size.width*0.07,width: size.width*0.07,)),
                                widthSpacer(size.width*0.03,),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(holidayeMastServices.showHolidayList[index].holidayName.toString(),style: TextStyle(fontFamily: fontInterSemiBoldString,fontSize: 17,fontWeight: FontWeight.w700,color: ColorConst.holidayTitleColors),),
                                      Text(dateFormatddMMMyyyy(DateTime.parse(holidayeMastServices.showHolidayList[index].holidayDate.toString())),style: TextStyle(fontFamily: fontInterMediumString,fontSize: 13,fontWeight: FontWeight.w500,color: ColorConst.holidaySubTitleColors),),
                                    ],
                                  ),
                                ),
                                if(curentUser['Role'] == 'Admin')...[
                                  widthSpacer(size.width*0.03,),
                                  iconBtn(Icons.edit, ColorConst.themeColor,() async {
                                    await holidayeMastServices.clearHolidayData();
                                    nextScreen(context, AddHolidayScreen(addEditFlag: false, getHolidayViewsData: holidayeMastServices.showHolidayList[index]),onthenValue: (value) {});
                                  },),
                                  widthSpacer(size.width *0.02),
                                  iconBtn(Icons.delete, ColorConst.redDarkColors,(){
                                    showDeleteDialog(context,size,yesOntap: () {holidayeMastServices.deleteHolidayHandleSubmit(context,setdid: holidayeMastServices.showHolidayList[index]);},noOnTap: (){Navigator.pop(context);});
                                  },),
                                ],
                              ],
                            )
                          );
                        },
                      ), 
              ),
            ),
          );
  }
}
