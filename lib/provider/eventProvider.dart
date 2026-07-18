// ignore_for_file: strict_top_level_inference, file_names

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:tax_hrm/services/local_cache_service.dart';
import 'package:tax_hrm/api/companiapi.dart';
import 'package:tax_hrm/api/eventsapi.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/eventclass/getevents.dart';
import 'package:tax_hrm/models/eventclass/newevents.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/notes/newnotes.dart';
import 'package:tax_hrm/page/event/add_event_screen.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class EventsMastServices extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  List<GetEvents> mainEventLists = [];
  List<GetEvents> getEventList = [];

  AutovalidateMode autoEventvalidateMode = AutovalidateMode.disabled;

  TextEditingController txtEventNameController = TextEditingController();
  TextEditingController txtEventStratDateController = TextEditingController();
  TextEditingController txtEventEndDateController = TextEditingController();
  TextEditingController txtEventPlaceController = TextEditingController();
  TextEditingController txtEventRemarksController = TextEditingController();
  TextEditingController txtEventSerchController = TextEditingController();
  TextEditingController txtOtherEventNameController = TextEditingController();
  List<PlatformFile> attachedFiles = [];
  DateTime eventStartDate = DateTime.now();
  DateTime eventEndDate = DateTime.now();

  List<String> eventNameList = [
    'Event',
    'General Announcement',
    'Company Update',
    'HR Notice',
    'Policy Update',
    'Emergency Notice',
    'Salary Credit',
    'Other',
  ];
  String? selectedEventName;

  bool get isEventMode => selectedEventName == 'Event';

  String dynamicAppBarTitle(bool addEditFlag) {
    if (isEventMode) {
      return addEditFlag
          ? LanguageProvider.translate("Create Event", "Create Event")
          : LanguageProvider.translate("Edit Event", "Edit Event");
    }
    return addEditFlag
        ? LanguageProvider.translate("Create Announcement", "Create Announcement")
        : LanguageProvider.translate("Edit Announcement", "Edit Announcement");
  }

  String get dynamicDropdownHeading => isEventMode
      ? LanguageProvider.translate("Event Type", "Event Type")
      : LanguageProvider.translate("Announcement Type", "Announcement Type");

  String get dynamicNameHeading {
    if (isEventMode) return LanguageProvider.translate("Event Name", "Event Name");
    if (selectedEventName == 'Other') return LanguageProvider.translate("Custom Event Type", "Custom Event Type");
    return LanguageProvider.translate("Announcement Title", "Announcement Title");
  }

  String get dynamicNameHint {
    if (isEventMode) return LanguageProvider.translate("Enter Event Name", "Enter Event Name");
    if (selectedEventName == 'Other') return LanguageProvider.translate("Enter custom event type", "Enter custom event type");
    return LanguageProvider.translate("Enter Announcement Title", "Enter Announcement Title");
  }

  String get dynamicStartDateHeading => isEventMode
      ? LanguageProvider.translate("Event Date", "Event Date")
      : LanguageProvider.translate("Announcement Date", "Announcement Date");

  String get dynamicStartDateHint => isEventMode
      ? LanguageProvider.translate("Select Event Date", "Select Event Date")
      : LanguageProvider.translate("Select Announcement Date", "Select Announcement Date");

  String get dynamicEndDateHeading => isEventMode
      ? LanguageProvider.translate("Event End Date", "Event End Date")
      : LanguageProvider.translate("Announcement End Date", "Announcement End Date");

  String get dynamicEndDateHint => isEventMode
      ? LanguageProvider.translate("Select Event End Date", "Select Event End Date")
      : LanguageProvider.translate("Select Announcement End Date", "Select Announcement End Date");

  String get dynamicPlaceHeading => isEventMode
      ? LanguageProvider.translate("Event Place", "Event Place")
      : LanguageProvider.translate("Announcement Place", "Announcement Place");

  String get dynamicPlaceHint => isEventMode
      ? LanguageProvider.translate("Enter Event Place", "Enter Event Place")
      : LanguageProvider.translate("Enter Announcement Place", "Enter Announcement Place");

  String get dynamicDetailsHeading => isEventMode
      ? LanguageProvider.translate("Event Details", "Event Details")
      : LanguageProvider.translate("Announcement Details", "Announcement Details");

  String get dynamicDetailsHint => isEventMode
      ? LanguageProvider.translate("Enter Event Details", "Enter Event Details")
      : LanguageProvider.translate("Enter Announcement Details", "Enter Announcement Details");

  String dynamicSubmitButtonTitle(bool addEditFlag) {
    if (isEventMode) {
      return addEditFlag
          ? LanguageProvider.translate("Create Event", "Create Event")
          : LanguageProvider.translate("Update Event", "Update Event");
    }
    return addEditFlag
        ? LanguageProvider.translate("Create Announcement", "Create Announcement")
        : LanguageProvider.translate("Update Announcement", "Update Announcement");
  }

  String dynamicSuccessMessage(bool addEditFlag) {
    if (isEventMode) {
      return addEditFlag
          ? LanguageProvider.translate("Event Created Successfully", "Event Created Successfully")
          : LanguageProvider.translate("Event Updated Successfully", "Event Updated Successfully");
    }
    return addEditFlag
        ? LanguageProvider.translate("Announcement Published Successfully", "Announcement Published Successfully")
        : LanguageProvider.translate("Announcement Updated Successfully", "Announcement Updated Successfully");
  }

  String get dynamicValidationDropdownMessage => isEventMode
      ? LanguageProvider.translate("Please select Event Type", "Please select Event Type")
      : LanguageProvider.translate("Please select Announcement Type", "Please select Announcement Type");

  String get dynamicValidationNameMessage {
    if (isEventMode) return LanguageProvider.translate("Please enter Event Name", "Please enter Event Name");
    if (selectedEventName == 'Other') return LanguageProvider.translate("Please enter custom event type", "Please enter custom event type");
    return LanguageProvider.translate("Please enter Announcement Title", "Please enter Announcement Title");
  }

  void selectEventName(String? value) {
    if (value != null) {
      selectedEventName = value;
      if (value != 'Other') {
        txtEventNameController.text = value;
      } else {
        txtEventNameController.text = txtOtherEventNameController.text.trim();
      }
      notifyListeners();
    }
  }

  Future<void> pickEventAttachments(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );
      if (result != null) {
        for (var file in result.files) {
          if (file.path != null && !attachedFiles.any((e) => e.path == file.path)) {
            attachedFiles.add(file);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      showtoastmessage('Error picking files: $e');
    }
  }

  void removeAttachment(int index) {
    if (index >= 0 && index < attachedFiles.length) {
      attachedFiles.removeAt(index);
      notifyListeners();
    }
  }

  bool _hasLoadedEventsThisSession = false;

  eventLoadingData({bool forceRefresh = false}) async {
    final cacheKey = '${LocalCacheService.keyMasterData}_events';
    const ttlMs = 24 * 60 * 60 * 1000;

    if (!forceRefresh && _hasLoadedEventsThisSession) {
      islodering = false;
      notifyListeners();
      return;
    }

    try {
      bool loadedFromCache = false;
      txtEventSerchController = TextEditingController();

      if (!forceRefresh) {
        final cachedData = await LocalCacheService.instance.getCache(cacheKey, ttlMilliseconds: ttlMs);
        if (cachedData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(cachedData);
            final cachedList = jsonList.map((e) => GetEvents.fromJson(e)).toList();
            mainEventLists = cachedList;
            getEventList = cachedList;
            
            _hasLoadedEventsThisSession = true;
            loadedFromCache = true;
            islodering = false;
            notifyListeners();
          } catch (e) {}
        }
      }

      if (!loadedFromCache || forceRefresh) {
        setloading(true);
      }

      unawaited(_fetchEventsFromApi(cacheKey));
    } catch (e) {
      setloading(false);
    }
  }

  Future<void> _fetchEventsFromApi(String cacheKey) async {
    try {
      final value = await EventsApiClass().getEventsData();
      mainEventLists = value;
      getEventList = value;
      _hasLoadedEventsThisSession = true;
      setloading(false);

      final jsonList = value.map((e) => e.toJson()).toList();
      await LocalCacheService.instance.saveCache(cacheKey, jsonEncode(jsonList));

      notifyListeners();
    } catch (e) {
      setloading(false);
    }
  }

  // get to event master
  Future getEventMasterData()async{
    await EventsApiClass().getEventsData().then((value) {
      mainEventLists =value;
      getEventList = value;
    });
  }

  //****************************************** Delete event Master ****************************************************** */

  // delete event master
  deleteEventMaster(context,{setEventid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await EventsApiClass().deleteEvents(setEventid: setEventid).then((value) async {
        NotesClass deleteResponse = value as NotesClass;
        if(deleteResponse.success == true) {
          if(deleteResponse.data == "Success"){
            await getEventMasterData();
          }
        }
        setloading(false);
      }).onError((error, stackTrace) {
        setloading(false);
      },);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  //****************************************** Delete event Master ****************************************************** */

  //****************************************** add & edit event Master ****************************************************** */

  // data clear Functionality

  clearData() {
    autoEventvalidateMode = AutovalidateMode.disabled;
    txtEventNameController = TextEditingController();
    txtOtherEventNameController = TextEditingController();
    attachedFiles = [];
    selectedEventName = null;
    eventNameList = [
      'Event',
      'General Announcement',
      'Company Update',
      'HR Notice',
      'Policy Update',
      'Emergency Notice',
      'Salary Credit',
      'Other',
    ];
    txtEventStratDateController = TextEditingController();
    txtEventEndDateController = TextEditingController();
    txtEventPlaceController = TextEditingController();
    txtEventSerchController = TextEditingController();
    txtEventRemarksController = TextEditingController();
    eventStartDate = DateTime.now();
    eventEndDate = DateTime.now();
    txtEventStratDateController.text = dateFormatdate(eventStartDate);
    txtEventEndDateController.text = dateFormatdate(eventEndDate);
  }
  
  // select Date Functionlity
  Future selectDatePicker(context,size,{required CommandWidigetsProvider dateController,selectDatePic,pickerStartDate}) async {
    await dateController.pickDate(context, size, selectDatePic, pickerStartDate??DateTime(1900), DateTime(3100), (value){selectDatePic = value;notifyListeners();});
    return selectDatePic;
  }

  Future addNewDocuments({List<FileUploadClass>? setlist, setCompanyId, setCguid}) async {
    log('------------------------>>>> addNewDocuments | setCguid: $setCguid | CompanyId: $setCompanyId | files count: ${setlist?.length}');
    await CompanyMasterApi().uploadDocuments(companyid: setCompanyId, files: setlist, cguid: setCguid).then((value) {
      if (value == 200) {
        showtoastmessage('Document Uploaded Successfully');
      }
      log('------------------------>>>> uploadDocuments status code: $value');
    });
  }

  // add and edit button ontap 
  Future handleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autoEventvalidateMode = AutovalidateMode.always;
      bool isFormValid = formkey.currentState!.validate();
      if (selectedEventName == null) {
        showtoastmessage(dynamicValidationDropdownMessage);
        notifyListeners();
        return;
      }
      String finalEventName = selectedEventName == 'Other' ? txtOtherEventNameController.text.trim() : selectedEventName!;
      if (selectedEventName == 'Other' && finalEventName.isEmpty) {
        showtoastmessage(dynamicValidationNameMessage);
        notifyListeners();
        return;
      }
      if (isFormValid) {
        setloading(true);
        String setGuid = generateCustomUuid();
        await EventsApiClass().createEvent(setCguid:addEditFlag == true? setGuid: setdid.cguid,eventPlaces: txtEventPlaceController.text.toString(),setDescription: txtEventRemarksController.text.toString(),setEndDate: dateFormatdateYMDate(eventEndDate).toString(),setEventname: txtEventNameController.text.toString(),setStartDat: dateFormatdateYMDate(eventStartDate).toString(),checkInsert: addEditFlag,setEventIds: addEditFlag ?setdid:setdid.eventId).then((value) async {
          NewEvents setResponse = value as NewEvents;
          if (setResponse.success == true) {
            
            if (attachedFiles.isNotEmpty && selectedcurentcompany != null) {
              List<FileUploadClass> fileUploadList = [];
              String imgType = 'Event';
              for (var file in attachedFiles) {
                if (file.path != null) {
                  log('------------------------>>>> FileUploadClass | File: ${file.path} | cguid: ${addEditFlag == true ? setGuid : setdid.cguid}');
                  fileUploadList.add(
                    FileUploadClass(
                      selectedImages: File(file.path!),
                      setImgType: imgType,
                      cguid: addEditFlag == true ? setGuid : setdid.cguid,
                    ),
                  );
                }
              }
              if (fileUploadList.isNotEmpty) {
                log('------------------------>>>> Calling addNewDocuments | cguid: ${addEditFlag == true ? setGuid : setdid.cguid}');
                await addNewDocuments(
                  setlist: fileUploadList,
                  setCompanyId: selectedcurentcompany!.companyId,
                  setCguid: addEditFlag == true ? setGuid : setdid.cguid,
                );
              }
              if (addEditFlag == true) {
                showtoastmessage('Add Successfully');
              } else {
                showtoastmessage('Update Successfully');
              }
            } else {
              if (addEditFlag == true) {
                showtoastmessage('Add Successfully');
              } else {
                showtoastmessage('Update Successfully');
              }
            }
          }
          setloading(false);
          Navigator.pop(context);
        }).onError((error, stackTrace) {
          setloading(false);
          String errMsg = isEventMode 
              ? LanguageProvider.translate("Failed to submit event: ", "Failed to submit event: ") 
              : LanguageProvider.translate("Failed to submit announcement: ", "Failed to submit announcement: ");
          showtoastmessage('$errMsg$error');
        });
        autoEventvalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
      showtoastmessage('${LanguageProvider.translate("Error occurred: ", "Error occurred: ")}$e');
    }
    notifyListeners();
  }

  // edit handle Submit
  Future editHandleSubmit(context,GetEvents getEventsData) async {
    try {
      islodering = true;
      notifyListeners();
      txtEventNameController.text = getEventsData.eventName.toString();
      txtOtherEventNameController = TextEditingController();
      attachedFiles = [];
      String eventNameStr = getEventsData.eventName.toString();
      List<String> defaultList = [
        'Event',
        'General Announcement',
        'Company Update',
        'HR Notice',
        'Policy Update',
        'Emergency Notice',
        'Salary Credit',
      ];
      if (eventNameStr.isNotEmpty) {
        if (defaultList.contains(eventNameStr)) {
          selectedEventName = eventNameStr;
        } else {
          selectedEventName = 'Other';
          txtOtherEventNameController.text = eventNameStr;
        }
      } else {
        selectedEventName = null;
      }
      txtEventStratDateController.text = dateFormatdate(DateTime.parse(getEventsData.startDate.toString()));
      txtEventEndDateController.text = dateFormatdate(DateTime.parse(getEventsData.endDate.toString()));
      txtEventPlaceController.text = getEventsData.eventPlace.toString();
      txtEventRemarksController.text = getEventsData.description.toString();
      eventStartDate = DateTime.parse(getEventsData.startDate.toString());
      eventEndDate = DateTime.parse(getEventsData.endDate.toString());
      islodering = false;
      notifyListeners();
      await nextScreen(context,AddEventScreen(getEventsData: getEventsData, addEditFlag: false,),onthenValue: (value) {});
     
    } catch (e) {
      islodering = false;
    }
    notifyListeners();
  }
  
  // search all events
  void searchAllEventData(String inputText) {
    final query = inputText.toLowerCase();
    getEventList = mainEventLists.where((element) {return element.eventName.toString().toLowerCase().contains(query);}).toList();
    notifyListeners(); // ✅ ONLY HERE
  }
  
  //****************************************** add & edit event Master ****************************************************** */
}
