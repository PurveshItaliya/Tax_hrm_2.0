// ignore_for_file: strict_top_level_inference, empty_catches, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/shiftapi.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/models/employes/withoutimg.dart';
import 'package:tax_hrm/models/shiftclass/shiftgroup/createshiftgroup.dart';
import 'package:tax_hrm/models/shiftclass/shiftgroup/getallshifts.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/createshiftmaster_modal.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/page/shift/shift_mater_design.dart';
import 'package:tax_hrm/page/shift/shift_timing/add_shift_timing_master_screen.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class ShiftMasterProvider extends ChangeNotifier {
  bool islodering = false;
  
  bool get isloderings => islodering;
  
  setloading(bool value) {
    islodering = value;
  }

  List<ShiftGroup>  mainShiftGroupList = [];

  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  TextEditingController   shiftFNcontroller = TextEditingController();
  TextEditingController   shiftSNcontroller = TextEditingController();

  //-----------------------Get shift Master Data Page -----------------------\\

  shiftGroupMasterLoadingData() async {
    try {
      setloading(true);
      await getshiftGroupMasterData();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  Future getshiftGroupMasterData()async{
    await ShiftApiClass().getshiftGroupMaster().then((value) {
      mainShiftGroupList = value;
    });
    return mainShiftGroupList;
  }

  // Add Funcation
  Future<void> shiftGroupHandleSubmit(context,size,formKey,{addEditFlag,setdid}) async {
    autovalidateMode = AutovalidateMode.disabled;
    showAddShiftGroupDialog(context,size: size,formKey,addEditFlag,setdid: setdid);
  }

  // Edit Funcation
  Future editShiftGroupHandleSubmit(context,size,formKey,{setdid}) async {
    try {
      shiftFNcontroller.text = setdid.shiftGroupFname.toString();
      shiftSNcontroller.text = setdid.shiftGroupSname.toString();   
      shiftGroupHandleSubmit(context,size,formKey,addEditFlag:false,setdid: setdid,);
    } catch (e) { /* ignored */ }
  }

  // add and Edit api Funcation
  Future addShiftGroupHandleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate()) {
        Navigator.pop(context);
        setloading(true);
        notifyListeners();
        String setGuids = generateCustomUuid();
        await ShiftApiClass().createshiftgroup(
          setCguid: addEditFlag ? setGuids : setdid.cguid,shiftfullname: shiftFNcontroller.text.toString(), shiftshortname: shiftSNcontroller.text.toString(),setinsertmood: addEditFlag  ? true : false,shitid: addEditFlag  ? setdid : setdid.shiftGroupID,).then((value) async {
          ShiftGroupCreate responseData = value as ShiftGroupCreate;
          if (responseData.success == true) {
            shiftFNcontroller.clear();
            shiftSNcontroller.clear();
            if (addEditFlag == true) {
              showtoastmessage('ShiftGroup Created Successfully');
            } else {
              showtoastmessage('ShiftGroup Update Successfully');
            }
            await getshiftGroupMasterData();
          }
          setloading(false);
        }).onError((error, stackTrace) {
          setloading(false);
          notifyListeners();
        },);
        autovalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  // delete Funcation
  Future deleteShiftHandleSubmit(context,{setdid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await  ShiftApiClass().deleteShiftGroupMaster(setdid.shiftGroupID).then((value) async {
        GetCompanyListModel deleteReponse = value as GetCompanyListModel;
        if (deleteReponse.success == true) {
          if(deleteReponse.data == "Success"){
            showtoastmessage('Delete Successfully');
            await getshiftGroupMasterData();
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

  //-----------------------Get shift Master Data Page -----------------------\\

  //-----------------------Get shift Timing Data Page -----------------------\\

  shiftTimingLoadingData() async {
    try {
      setloading(true);
      await getShiftTimintgMasterData();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  List<GetShiftMasterData> mainShiftMasterList = [];
  List<GetShiftMasterData> mainShiftMasterGroupList = [];

  //-----------------------Get shift Timing Data -----------------------\\

  Future  getShiftTimintgMasterData()async{
    await ShiftApiClass().getShiftTimingMaster().then((value){
      mainShiftMasterList = value;
      mainShiftMasterGroupList = value;
    });
    return mainShiftMasterList;
  }

  //-----------------------Get shift Timing Data -----------------------\\

  //-----------------------Delete shift Timing Data -----------------------\\

  Future deleteShiftTimingHandleSubmit(context,{setdid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await ShiftApiClass().deleteShiftTimingmasters(setdid.shiftID).then((value) async {
        GetCompanyListModel deleteReponse = value as GetCompanyListModel;
        if (deleteReponse.success == true) {
          if(deleteReponse.data == "Success"){
            showtoastmessage('Delete Successfully');
            await getShiftTimintgMasterData();
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

  //-----------------------Delete shift Timing Data -----------------------\\

  //-----------------------Get shift Timing Data Page -----------------------\\

  //----------------------- shift Timing Data Add Page -----------------------\\

  TextEditingController addShiftSNcontroller = TextEditingController();
  TextEditingController addShiftDurationcontroller = TextEditingController(text: "00:00:00");
  DepartMnetModel? selectedDepartment;
  ShiftGroup? selectedShiftGroup;
  PositionDataL? selectedDesignation;
  List<PositionDataL>  getFiltersPostionList= [];

  List<String> daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  List<bool> checkBoxValues = List.generate(7, (index) => true);
  bool selectWeekDayValue = false;
  
  TimeOfDay pickedBeginTime = TimeOfDay.now();
  TimeOfDay pickedEndTime = TimeOfDay.now();
  TimeOfDay diffrenceTime = const TimeOfDay(hour: 00, minute: 00);

  TimeOfDay pickedBreak1Time = TimeOfDay(hour: 00, minute: 00);
  String pickbreak1Seconds = "00";
  TimeOfDay pickedBreak2Time =  TimeOfDay(hour: 00, minute: 00);
  String pickbreak2Seconds = "00";
  bool break1Value = true;
  bool break2Value = false;
  AutovalidateMode autoShiftTimingvalidateMode = AutovalidateMode.disabled;

  // shift Full Name searching
  Future<List<ShiftGroup>> getFilterShiftGroup(String ss)async{
    return mainShiftGroupList.where((e) {return e.shiftGroupFname.toString().toLowerCase().contains(ss.toLowerCase());}).toList();
  }

  // shift Full Name select
  shiftFullNameontap(value) {
    selectedShiftGroup = value;
    addShiftSNcontroller.text = selectedShiftGroup!.shiftGroupSname.toString();
    notifyListeners();
  }

  // designation searching
  Future<List<PositionDataL>> getFilterDesignation(String ss)async{
    return getFiltersPostionList.where((e) {return e.positionName.toString().toLowerCase().contains(ss.toLowerCase());}).toList();
  }

  // department Name select
  depatmentontap(value,PositionMasterService position) {
    selectedDepartment = value;
    getFiltersPostionList.clear();
    selectedDesignation = null;
    for (var element in position.showPositions) {
      if(element.departmentName == selectedDepartment!.departmentName){
        if(element.isActive == true) {
          getFiltersPostionList.add(element);
        }
      }
    }
    notifyListeners();
  }

  // designation Name select
  designationontap(value) {
    selectedDesignation = value;
    notifyListeners();
  }

  // select work Days select
  selectWeekDay(indexs) {
    if (checkBoxValues[indexs] == true) {
      checkBoxValues[indexs] = false;
    } else {
      checkBoxValues[indexs] = true;
    }
    if(checkBoxValues.any((i) => i,)){
      selectWeekDayValue = false;
    } else {
      selectWeekDayValue = true;
    }
    notifyListeners();
  }

  // time handle Submit 
  Future timerHadleSubmit(context,timerboolValue) async {
    final TimeOfDay? timersPicked = await openTimePicker(
      context,
      initialTime: timerboolValue ?pickedBeginTime:pickedEndTime,
    );
    if (timersPicked != null) {
      if (timerboolValue == true) {
        pickedBeginTime = timersPicked;
      } else {
        pickedEndTime = timersPicked;
      }
      notifyListeners();
      calculateDuration();
    }
  }

  void calculateDuration() {
    DateTime startDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, pickedBeginTime.hour, pickedBeginTime.minute);
    DateTime endDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,  pickedEndTime.hour, pickedEndTime.minute);

    Duration difference = endDate.difference(startDate);

    int hours = difference.inHours;
    int minutes = difference.inMinutes - difference.inHours * 60;

    diffrenceTime = TimeOfDay(hour: hours, minute: minutes,);
    if (hours < 0) {
      hours += 24; // Add 24 hours if the end time is before the start time
    }

    addShiftDurationcontroller.text = "${diffrenceTime.hour}:${(diffrenceTime.minute % 60).toString().padLeft(2, '0')} Hr";
    notifyListeners();
  }
  
  // break bool value
  breakBoolValue(changeValue,bool breakTimeValue) {
    if (breakTimeValue == true) {
      break1Value = changeValue;
    } else {
      break2Value = changeValue;
    }
    notifyListeners();
  }

  // break time handle Submit 
  Future breaktimerHadleSubmit(context,timerboolValue) async {
    final Duration? durationTimerPicked = await showHmsTimeDialog(context,initialHour: pickedBreak1Time.hour,initialMinute: pickedBreak1Time.minute,initialSecond: int.parse(pickbreak1Seconds));
    if (durationTimerPicked != null) {      
      TimeOfDay timeOfDay = TimeOfDay(
        hour: durationTimerPicked.inHours % 24,
        minute: durationTimerPicked.inMinutes % 60,
      );
      if (timerboolValue == true) {
        pickedBreak1Time = timeOfDay;
        pickbreak1Seconds = (durationTimerPicked.inSeconds % 60).toString().padLeft(2, '0');
      } else {
        pickedBreak2Time = timeOfDay;
        pickbreak2Seconds = (durationTimerPicked.inSeconds % 60).toString().padLeft(2, '0');
      }
    }
    notifyListeners();
  }

  
  // button ontap 
  Future handleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      if(!checkBoxValues.any((i) => i,)){
        selectWeekDayValue = true;
      }
      if (formkey.currentState!.validate()) {
        final value = mainShiftMasterGroupList.where((element) => (element.positionName == selectedDesignation!.positionName && element.departmentId == selectedDepartment!.id));
        if(value.isEmpty || !addEditFlag){
          setloading(true);
          String setGuids = generateCustomUuid();
          await ShiftApiClass().createShifttimingMastergroup(
            shiftGroupGuid: selectedShiftGroup!.shiftGroupID,
            departmentId: selectedDepartment!.id,
            positionId: selectedDesignation!.id,
            shiftfullname: selectedShiftGroup!.shiftGroupFname,
            shiftshortname: addShiftSNcontroller.text.toString(),
            beginTime:"${pickedBeginTime.hour.toString().padLeft(2, '0')}:${pickedBeginTime.minute.toString().padLeft(2, '0')}",
            endTime: "${pickedEndTime.hour.toString().padLeft(2, '0')}:${pickedEndTime.minute.toString().padLeft(2, '0')}",
            break1: break1Value,
            break2: break2Value,
            shiftDuration: addShiftDurationcontroller.text.toString().replaceAll("[", "").replaceAll("]", "").toString().split(" ").first,
            break1Duration: "${pickedBreak1Time.hour.toString().padLeft(2, '0')}:${pickedBreak1Time.minute.toString().padLeft(2, '0')}:${pickbreak1Seconds.toString().padLeft(2, '0')}",
            break2Duration: "${pickedBreak2Time.hour.toString().padLeft(2, '0')}:${pickedBreak2Time.minute.toString().padLeft(2, '0')}:${pickbreak2Seconds.toString().padLeft(2, '0')}",
            shiftType: "",
            setCguid: addEditFlag == true ? setGuids : setdid.cguid,
            mon: checkBoxValues[1],
            tue: checkBoxValues[2],
            wed: checkBoxValues[3],
            thru: checkBoxValues[4],
            fri: checkBoxValues[5],
            sat: checkBoxValues[6],
            sun: checkBoxValues[0],
            setinsertmood: addEditFlag,
            shitid: addEditFlag == true ?"":setdid.shiftID,
            context: context,).then((value) {
            ShiftMasterCreate responseData = value as ShiftMasterCreate;

            if (responseData.success == true) {
              if (addEditFlag == true) {
                showtoastmessage('ShiftMaster Created Successfully');
              } else {
                showtoastmessage('ShiftMaster Update Successfully');
              }
              clearData();
              setloading(false);
              Navigator.pop(context);
            }
          }).onError((error, stackTrace) {
            setloading(false);
          },);
        } else {
          showtoastmessage(positionErrorString);
        }
        autovalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  clearData() {
    selectedShiftGroup = null;
    addShiftSNcontroller.text = "";
    selectedDepartment = null;
    selectedDesignation = null;
    break1Value = true;
    break2Value = false;
    checkBoxValues = List.generate(7, (index) => true);
    pickedBreak1Time = TimeOfDay(hour: 00, minute: 00);
    pickbreak1Seconds = "00";
    pickedBreak2Time =  TimeOfDay(hour: 00, minute: 00);
    pickbreak2Seconds = "00";
    addShiftDurationcontroller.text = "00:00:00";
    pickedBeginTime = TimeOfDay.now();
    pickedEndTime = TimeOfDay.now();
    autovalidateMode = AutovalidateMode.disabled;
  }

  Future editHandleSubmit(context,GetShiftMasterData getShiftMasterData) async {
    try {
      islodering = true;
      notifyListeners();
      checkBoxValues[0] = getShiftMasterData.sun ?? false;
      checkBoxValues[1] = getShiftMasterData.mon ?? false;
      checkBoxValues[2] = getShiftMasterData.tue ?? false;
      checkBoxValues[3] = getShiftMasterData.wed ?? false;
      checkBoxValues[4] = getShiftMasterData.thu ?? false;
      checkBoxValues[5] = getShiftMasterData.fri ?? false;
      checkBoxValues[6] = getShiftMasterData.sat ?? false;
      break1Value = getShiftMasterData.break1!;
      break2Value = getShiftMasterData.break2!;
      for (var element in Provider.of<DepartmentServices>(context, listen: false).showedepartment) {
        if (element.id == getShiftMasterData.departmentId) {
          selectedDepartment = element;
        }
      }
      for (var element in Provider.of<PositionMasterService>(context, listen: false).showPositions) {
        if (element.id == getShiftMasterData.positionId) {
          selectedDesignation = element;
        }
      }
      for (var element in mainShiftGroupList) {
        if (element.shiftGroupFname == getShiftMasterData.shiftFName) {
          selectedShiftGroup = element;
          addShiftSNcontroller.text = selectedShiftGroup!.shiftGroupSname.toString();
        }
      }
      pickedBeginTime = TimeOfDay.fromDateTime(DateTime.parse(getShiftMasterData.beginTime.toString()));
      pickedEndTime = TimeOfDay.fromDateTime(DateTime.parse(getShiftMasterData.endTime.toString()));
      calculateDuration();
      var break1Counter = DateTime.parse(getShiftMasterData.break1Duration.toString());
      pickedBreak1Time = TimeOfDay(hour: break1Counter.hour, minute: break1Counter.minute);
      pickbreak1Seconds = break1Counter.second.toString();
      var break2Counter = DateTime.parse(getShiftMasterData.break2Duration.toString());
      pickedBreak2Time = TimeOfDay(hour: break2Counter.hour, minute: break2Counter.minute);
      pickbreak2Seconds = break2Counter.second.toString();
      islodering = false;
      notifyListeners();
      await nextScreen(context,AddShiftTimingMasterScreen(getShiftMasterData: getShiftMasterData, addEditFlag: false,),onthenValue: (value) {});
    } catch (e) {
      islodering = false;
    }
    notifyListeners();
  }
  
  //----------------------- shift Timing Data Add Page -----------------------\\

// -----------------------Get ShiftMasterList -----------------------\\

}
