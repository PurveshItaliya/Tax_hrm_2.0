// ignore_for_file: deprecated_member_use, use_build_context_synchronously, strict_top_level_inference, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/holidayprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class AddHolidayScreen extends StatefulWidget {
  final bool addEditFlag;final getHolidayViewsData;
  const AddHolidayScreen({super.key,required this.addEditFlag,required this.getHolidayViewsData});

  @override
  State<AddHolidayScreen> createState() => _AddHolidayScreenState();
}

class _AddHolidayScreenState extends State<AddHolidayScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    if(!widget.addEditFlag){
      Provider.of<HolidayeMastServices>(context,listen: false).editHandleSubmit(context, widget.getHolidayViewsData);
    }
  }

  final userHolidaysFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
     final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final holidayeMastServices = Provider.of<HolidayeMastServices>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor:ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(addNewHolidayString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            body: holidayeMastServices.islodering ? userProfileShimmer(size) : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: userHolidaysFormKey,
                        autovalidateMode: holidayeMastServices.autoHolidaysvalidateMode,
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonTextField(controller: holidayeMastServices.txtTitle,hintText: enterTitleString,showHeading: "$titleString :-",validator: (value) {
                              if(value!.isEmpty) {
                                return '$pleaseEnterString $titleString';
                              }
                              return null;
                            }),
                            heightSpacer(size.height*0.01),
                            Text("$dateString :-", style: normalHeadingText(size)),
                            heightSpacer(size.height * 0.01),
                            TableCalendar(
                              focusedDay: holidayeMastServices.focusedDay,
                              firstDay: DateTime.now(),
                              lastDay: DateTime.utc(2050, 12, 31),
                              selectedDayPredicate: holidayeMastServices.isSelected,
                              onDaySelected: holidayeMastServices.onDaySelected,
                              calendarStyle: CalendarStyle(
                                tablePadding: EdgeInsets.zero,
                                cellPadding: EdgeInsets.zero,
                                isTodayHighlighted: true,
                                selectedDecoration:  BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: ColorConst.themeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: HeaderStyle(
                                headerPadding: EdgeInsets.only(bottom: 5),
                                leftChevronPadding: EdgeInsets.zero,
                                rightChevronPadding: EdgeInsets.zero,
                                leftChevronMargin: EdgeInsets.zero,
                                rightChevronMargin: EdgeInsets.zero,
                              ),
                              calendarFormat: holidayeMastServices.calendarFormat,
                              availableGestures: AvailableGestures.horizontalSwipe,
                              onFormatChanged: (format) {
                                holidayeMastServices.dateselectOntap(format);
                              },
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: holidayeMastServices.selectedDates
                                  .map(
                                    (date) => Chip(
                                      backgroundColor: ColorConst.transparent,
                                      side: BorderSide(color: ColorConst.textBorder,width: 1.2,),
                                      iconTheme: IconThemeData(color: ColorConst.black),
                                      label: Text(formatDate(date),style: TextStyle(color: ColorConst.black,fontSize: 10,fontWeight: FontWeight.w500,),),
                                      deleteIcon: const Icon(Icons.close),
                                      onDeleted: () {
                                        holidayeMastServices.removeSelectDate(date);
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            if (holidayeMastServices.dateError)...[
                              Text(daterErrorSrtring,style: TextStyle(color: ColorConst.red, fontSize: size.height * 0.015),),
                            ],
                            heightSpacer(size.height * 0.01),
                            CommonTextField(controller: holidayeMastServices.txtDescription,hintText: enterDescriptionString,showHeading: "$descriptionString :-",maxLines: 3,),
                            heightSpacer(size.height * 0.01),
                            Text("$holidayTypeString :-", style: normalHeadingText(size)),
                            heightSpacer(size.height * 0.01),
                            Row(
                              children: [
                                Radio(activeColor: ColorConst.themeColor,value: paidHolidayString.toString().split(" ").first.toString(), groupValue: holidayeMastServices.selectedHolidayType, onChanged: (val){holidayeMastServices.selectHolidayType(val);},materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,visualDensity: VisualDensity.compact,),
                                Text(paidHolidayString,style: normalHeadingText(size),),
                                Radio(activeColor: ColorConst.themeColor,value: unpaidHolidayString.toString().split(" ").first.toString(), groupValue: holidayeMastServices.selectedHolidayType, onChanged: (val){holidayeMastServices.selectHolidayType(val);},materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,visualDensity: VisualDensity.compact,),
                                Text(unpaidHolidayString,style: normalHeadingText(size),),
                              ],
                            ),
                          ],
                        ) 
                      ),
                    ),
                  ),
                  heightSpacer(size.height *0.02),
                  Row(
                    children: [
                      Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                        await holidayeMastServices.handleSubmit(context, userHolidaysFormKey, widget.addEditFlag, widget.addEditFlag?"":widget.getHolidayViewsData);
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
