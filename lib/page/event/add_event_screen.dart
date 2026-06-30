// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/eventclass/getevents.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/eventProvider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class AddEventScreen extends StatefulWidget {
  final bool addEditFlag;final GetEvents? getEventsData;
  const AddEventScreen({super.key,required this.addEditFlag,required this.getEventsData});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
  }

  final userEventFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final eventsMastServices = Provider.of<EventsMastServices>(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor:ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(widget.addEditFlag ?addEventString:editEventString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            body: eventsMastServices.islodering ? userProfileShimmer(size) : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: userEventFormKey,
                        autovalidateMode: eventsMastServices.autoEventvalidateMode,
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonTextField(controller: eventsMastServices.txtEventNameController,hintText: enterEventNameString,showHeading: eventNameString, validator: (value) {
                              if(value!.isEmpty) {
                                return '$pleaseEnterString $eventNameString';
                              }
                              return null;
                            }),
                            heightSpacer(size.height*0.02),
                            Row(
                              children: [
                                Expanded(child: CommonTextField(controller: eventsMastServices.txtEventStratDateController,readOnly: true,hintText: selectEventStartDateString,suffixIcon: IgnorePointer(child: IconButton(onPressed: (){}, icon: Icon(Icons.calendar_today_outlined,color: ColorConst.passwordColor,),)),showHeading: eventStartDateString,onTap: () {
                                 eventsMastServices.selectDatePicker(context,size,dateController: datePickerProvider,selectDatePic: eventsMastServices.eventStartDate,).then((value) {
                                    eventsMastServices.eventStartDate = value;
                                    eventsMastServices.txtEventStratDateController.text = dateFormatdate(eventsMastServices.eventStartDate);
                                    if(eventsMastServices.eventStartDate.isAfter(eventsMastServices.eventEndDate)) {
                                      eventsMastServices.eventEndDate = eventsMastServices.eventStartDate;
                                      eventsMastServices.txtEventEndDateController.text = dateFormatdate(eventsMastServices.eventEndDate);
                                    }
                                 },);
                                },)),
                                widthSpacer(size.width*0.02),
                                Expanded(child: CommonTextField(controller: eventsMastServices.txtEventEndDateController,readOnly: true,hintText: selectEventEndDateString,suffixIcon: IgnorePointer(child: IconButton(onPressed: (){}, icon: Icon(Icons.calendar_today_outlined,color: ColorConst.passwordColor,),)),showHeading: eventEndDateString,onTap: () {
                                  String apiDate = eventsMastServices.eventStartDate.toString();
                                  eventsMastServices.eventStartDate = DateTime.parse(apiDate);
                                  eventsMastServices.selectDatePicker(context,size,dateController: datePickerProvider,selectDatePic: eventsMastServices.eventEndDate,pickerStartDate: eventsMastServices.eventStartDate).then((value) {
                                    eventsMastServices.eventEndDate = value;

                                    eventsMastServices.txtEventEndDateController.text = dateFormatdate(eventsMastServices.eventEndDate);
                                  },);
                                },)),
                              ],
                            ),
                            heightSpacer(size.height*0.02),
                            CommonTextField(controller: eventsMastServices.txtEventPlaceController,hintText: enterEventPlaceString,showHeading: eventPlaceString),
                            heightSpacer(size.height*0.02),
                            CommonTextField(controller: eventsMastServices.txtEventRemarksController,hintText: enterEventRemarksString,showHeading: eventRemarkString,maxLines: 3,),
                            heightSpacer(size.height*0.02),
                          ],
                        ) 
                      ),
                    ),
                  ),
                  heightSpacer(size.height *0.02),
                  Row(
                    children: [
                      Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                        await eventsMastServices.handleSubmit(context, userEventFormKey, widget.addEditFlag, widget.addEditFlag?"":widget.getEventsData);
                      }, isgradient: true,)),
                      widthSpacer(size.width *0.02),
                      Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () {Navigator.pop(context);},)),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
