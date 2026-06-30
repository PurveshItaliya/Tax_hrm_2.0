// ignore_for_file: strict_top_level_inference, file_names

import 'package:flutter/material.dart';
import 'package:tax_hrm/api/eventsapi.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/eventclass/getevents.dart';
import 'package:tax_hrm/models/eventclass/newevents.dart';
import 'package:tax_hrm/models/notes/newnotes.dart';
import 'package:tax_hrm/page/event/add_event_screen.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/navigation.dart';
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
  DateTime eventStartDate = DateTime.now();
  DateTime eventEndDate = DateTime.now();

  eventLoadingData() async {
    try {
      setloading(true);
      txtEventSerchController = TextEditingController();
      await getEventMasterData();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
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

  // add and edit button ontap 
  Future handleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autoEventvalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate()) {
        setloading(true);
        String setGuid = generateCustomUuid();
        await EventsApiClass().createEvent(setCguid:addEditFlag == true? setGuid: setdid.cguid,eventPlaces: txtEventPlaceController.text.toString(),setDescription: txtEventRemarksController.text.toString(),setEndDate: dateFormatdateYMDate(eventEndDate).toString(),setEventname: txtEventNameController.text.toString(),setStartDat: dateFormatdateYMDate(eventStartDate).toString(),checkInsert: addEditFlag,setEventIds: addEditFlag ?setdid:setdid.eventId).then((value){
          NewEvents  setResponse = value as NewEvents;
          if(setResponse.success == true){
            if(addEditFlag == true){
              showtoastmessage('Add Successfully');
            }else{
              showtoastmessage('Update Successfully');
            }
          }
          setloading(false);
          Navigator.pop(context);  
        }).onError((error, stackTrace) {
          setloading(false);
        },);
        autoEventvalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  // edit handle Submit
  Future editHandleSubmit(context,GetEvents getEventsData) async {
    try {
      islodering = true;
      notifyListeners();
      txtEventNameController.text = getEventsData.eventName.toString();
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
