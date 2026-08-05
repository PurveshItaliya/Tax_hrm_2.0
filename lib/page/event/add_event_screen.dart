// ignore_for_file: deprecated_member_use

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/eventclass/getevents.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/eventProvider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/customedropdownfiled.dart';
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
            appBar: showCustomeAppBar(eventsMastServices.dynamicAppBarTitle(widget.addEditFlag), size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(eventsMastServices.dynamicDropdownHeading, style: TextStyle(fontFamily: fontInterBoldString)),
                                heightSpacer(size.height * 0.015),
                                commonDropDownField(
                                  size: size,
                                  onChanged: (value) => eventsMastServices.selectEventName(value),
                                  listName: eventsMastServices.eventNameList,
                                  selectedValue: eventsMastServices.selectedEventName,
                                  hintextString: eventsMastServices.dynamicDropdownHeading,
                                  borderColor: (eventsMastServices.autoEventvalidateMode == AutovalidateMode.always && eventsMastServices.selectedEventName == null) ? ColorConst.red : ColorConst.textBorder,
                                ),
                                if (eventsMastServices.autoEventvalidateMode == AutovalidateMode.always && eventsMastServices.selectedEventName == null) ...[
                                  heightSpacer(size.height * 0.005),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: Text(
                                      eventsMastServices.dynamicValidationDropdownMessage,
                                      style: TextStyle(color: ColorConst.red, fontSize: 12, fontFamily: fontInterRegularString),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (eventsMastServices.selectedEventName == 'Other') ...[
                              heightSpacer(size.height * 0.02),
                              CommonTextField(
                                controller: eventsMastServices.txtOtherEventNameController,
                                hintText: eventsMastServices.dynamicNameHint,
                                showHeading: '${eventsMastServices.dynamicNameHeading} *',
                                validator: (value) {
                                  if (eventsMastServices.selectedEventName == 'Other' && (value == null || value.trim().isEmpty)) {
                                    return eventsMastServices.dynamicValidationNameMessage;
                                  }
                                  return null;
                                },
                              ),
                            ],
                            heightSpacer(size.height*0.02),
                            Row(
                              children: [
                                Expanded(child: CommonTextField(controller: eventsMastServices.txtEventStratDateController,readOnly: true,hintText: eventsMastServices.dynamicStartDateHint,suffixIcon: IgnorePointer(child: IconButton(onPressed: (){}, icon: Icon(Icons.calendar_today_outlined,color: ColorConst.passwordColor,),)),showHeading: eventsMastServices.dynamicStartDateHeading,onTap: () {
                                 eventsMastServices.selectDatePicker(context,size,dateController: datePickerProvider,selectDatePic: eventsMastServices.eventStartDate,).then((value) {
                                    if (value != null) {
                                      eventsMastServices.updateEventStartDate(value);
                                      if(eventsMastServices.eventStartDate.isAfter(eventsMastServices.eventEndDate)) {
                                        eventsMastServices.updateEventEndDate(eventsMastServices.eventStartDate);
                                      }
                                    }
                                 },);
                                },)),
                                widthSpacer(size.width*0.02),
                                Expanded(child: CommonTextField(controller: eventsMastServices.txtEventEndDateController,readOnly: true,hintText: eventsMastServices.dynamicEndDateHint,suffixIcon: IgnorePointer(child: IconButton(onPressed: (){}, icon: Icon(Icons.calendar_today_outlined,color: ColorConst.passwordColor,),)),showHeading: eventsMastServices.dynamicEndDateHeading,onTap: () {
                                  eventsMastServices.selectDatePicker(context,size,dateController: datePickerProvider,selectDatePic: eventsMastServices.eventEndDate,pickerStartDate: eventsMastServices.eventStartDate).then((value) {
                                    if (value != null) {
                                      eventsMastServices.updateEventEndDate(value);
                                    }
                                  },);
                                },)),
                              ],
                            ),
                            heightSpacer(size.height*0.02),
                            CommonTextField(controller: eventsMastServices.txtEventPlaceController,hintText: eventsMastServices.dynamicPlaceHint,showHeading: eventsMastServices.dynamicPlaceHeading),
                            heightSpacer(size.height*0.02),
                            CommonTextField(controller: eventsMastServices.txtEventRemarksController,hintText: eventsMastServices.dynamicDetailsHint,showHeading: eventsMastServices.dynamicDetailsHeading,maxLines: 3,),
                            heightSpacer(size.height*0.02),
                            Text(LanguageProvider.translate('Attachments', 'Attachments'), style: TextStyle(fontFamily: fontInterBoldString, fontSize: 15, color: ColorConst.black)),
                            heightSpacer(size.height * 0.012),
                            InkWell(
                              onTap: () => eventsMastServices.pickEventAttachments(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: size.height * 0.022, horizontal: size.width * 0.04),
                                decoration: BoxDecoration(
                                  color: ColorConst.white,
                                  border: Border.all(color: ColorConst.themeColor.withOpacity(0.5), width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, color: ColorConst.themeColor, size: 34),
                                    heightSpacer(size.height * 0.008),
                                    Text(
                                      LanguageProvider.translate('Click to upload attachments', 'Click to upload attachments'),
                                      style: TextStyle(color: ColorConst.themeColor, fontFamily: fontInterSemiBoldString, fontSize: 14),
                                    ),
                                    heightSpacer(size.height * 0.004),
                                    Text(
                                      LanguageProvider.translate('Supported: Images, PDF, Word, Excel files', 'Supported: Images, PDF, Word, Excel files'),
                                      style: TextStyle(color: ColorConst.hintextColor, fontFamily: fontInterRegularString, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (eventsMastServices.attachedFiles.isNotEmpty) ...[
                              heightSpacer(size.height * 0.015),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: eventsMastServices.attachedFiles.length,
                                separatorBuilder: (context, index) => heightSpacer(size.height * 0.01),
                                itemBuilder: (context, index) {
                                  final file = eventsMastServices.attachedFiles[index];
                                  return _buildAttachmentItem(size, file, index, eventsMastServices);
                                },
                              ),
                            ],
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

  Widget _buildAttachmentItem(Size size, PlatformFile file, int index, EventsMastServices services) {
    String ext = file.extension?.toLowerCase() ?? file.name.split('.').last.toLowerCase();
    IconData iconData;
    Color iconColor;
    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (ext == 'doc' || ext == 'docx') {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (ext == 'xls' || ext == 'xlsx') {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      iconData = Icons.image;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey.shade700;
    }

    String sizeString = _formatBytes(file.size);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.035, vertical: size.height * 0.012),
      decoration: BoxDecoration(
        color: ColorConst.white,
        border: Border.all(color: ColorConst.textBorder, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(fontFamily: fontInterSemiBoldString, fontSize: 13.5, color: ColorConst.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sizeString,
                  style: TextStyle(fontFamily: fontInterRegularString, fontSize: 11.5, color: ColorConst.hintextColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => services.removeAttachment(index),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            tooltip: 'Remove file',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
