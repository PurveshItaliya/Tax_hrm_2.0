import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/event/add_event_screen.dart';
import 'package:tax_hrm/page/event/event_screen_design.dart';
import 'package:tax_hrm/provider/eventProvider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class EventPageScreen extends StatefulWidget {
  const EventPageScreen({super.key});

  @override
  State<EventPageScreen> createState() => _EventPageScreenState();
}

class _EventPageScreenState extends State<EventPageScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<EventsMastServices>(context,listen: false).eventLoadingData(forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final eventsMastServices =  Provider.of<EventsMastServices>(context);
    Provider.of<LanguageProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: eventsMastServices.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.03),
                child: iconWithTextBtnDesign(size,addEventString,isIcon: false,onTap: () {
                  eventsMastServices.clearData();
                  nextScreen(context, AddEventScreen(addEditFlag: true, getEventsData: null),onthenValue: (value) {
                    _loadAllData(forceRefresh: true);
                  });
                },isgradient: true,isImage: false),
              ),
              appBar: showCustomeAppBar(eventString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData(forceRefresh: true);
                },
                widgetDesign: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: eventsMastServices.islodering ? departmentMasterShimmer(size,false) : Column(
                    children: [
                      CommonTextField(controller: eventsMastServices.txtEventSerchController,fillColors: ColorConst.white,borderColor: ColorConst.transparent,hintText: searchEventString,prefixIcon: Padding(padding: const EdgeInsets.only(left: 10,right: 10),child: Icon(Icons.search,color: ColorConst.commatextIconsColors,),),onChanged: (value) {eventsMastServices.searchAllEventData(value);},),
                      heightSpacer(size.height*0.02,),
                      eventsMastServices.getEventList.isEmpty
                          ? Expanded(child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noEventAddedString,nodataFoundsImagString)))) 
                          : Expanded(
                            child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: eventsMastServices.getEventList.length,
                              padding: EdgeInsets.only(
                                bottom: size.height * 0.10,
                              ),
                              itemBuilder: (context, index) {
                                return eventCard(
                                  size: size,
                                  titles: eventsMastServices.getEventList[index].eventName,place: eventsMastServices.getEventList[index].eventPlace,remark: eventsMastServices.getEventList[index].description,startDate: dateFormatdate(DateTime.parse(eventsMastServices.getEventList[index].startDate.toString())),endDate: dateFormatdate(DateTime.parse(eventsMastServices.getEventList[index].endDate.toString())),editOntap: () async {
                                    await eventsMastServices.editHandleSubmit(context,eventsMastServices.getEventList[index],).then((value) {
                                      _loadAllData();
                                    },);
                                  },deleteOntap: () {
                                    showDeleteDialog(context,size,yesOntap: () {eventsMastServices.deleteEventMaster(context,setEventid: eventsMastServices.getEventList[index].eventId);},noOnTap: (){Navigator.pop(context);});
                                  },
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
