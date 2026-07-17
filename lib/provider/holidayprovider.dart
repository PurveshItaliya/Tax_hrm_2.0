// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:tax_hrm/services/local_cache_service.dart';
import 'package:tax_hrm/api/holidayapi.dart';
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tax_hrm/models/Holidays/holidaybyid.dart';
import 'package:tax_hrm/models/Holidays/newgrop.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/employes/withoutimg.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class HolidayeMastServices extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  List<GetHolidayViews> mainHolidayList = [];
  List<GetHolidayViews> showHolidayList = [];

  AutovalidateMode autoHolidaysvalidateMode = AutovalidateMode.disabled;
  TextEditingController txtTitle = TextEditingController();
  TextEditingController txtDescription = TextEditingController();
  String selectedHolidayType = paidHolidayString.toString().split(" ").first.toString();
  List<DateTime> selectedDates = [];
  DateTime focusedDay = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.week;
  bool dateError = false;
  HolidayById?  getholiday;

  bool _hasLoadedHolidaysThisSession = false;

  Future<void> loadingData({bool forceRefresh = false}) async {
    final cacheKey = '${LocalCacheService.keyMasterData}_holidays';
    const ttlMs = 24 * 60 * 60 * 1000; // 24 hours

    if (!forceRefresh && _hasLoadedHolidaysThisSession) {
      islodering = false;
      notifyListeners();
      return;
    }

    try {
      bool loadedFromCache = false;
      if (!forceRefresh) {
        final cachedData = await LocalCacheService.instance.getCache(cacheKey, ttlMilliseconds: ttlMs);
        if (cachedData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(cachedData);
            final cachedList = jsonList.map((e) => GetHolidayViews.fromJson(e)).toList();
            
            _processHolidayList(cachedList);
            
            _hasLoadedHolidaysThisSession = true;
            loadedFromCache = true;
            islodering = false;
            notifyListeners();
          } catch (e) {
             // silent fallback
          }
        }
      }

      if (!loadedFromCache || forceRefresh) {
        islodering = true;
        notifyListeners();
      }

      unawaited(_fetchHolidaysFromApi(cacheKey));

    } catch (e) {
      islodering = false;
      notifyListeners();
    }
  }

  void _processHolidayList(List<GetHolidayViews> value) {
    int currentYear = DateTime.now().year;
    mainHolidayList = value;
    showHolidayList = value.where((element) {
      if (element.holidayDate != null) {
        try {
          DateTime d = DateTime.parse(element.holidayDate.toString());
          return d.year == currentYear;
        } catch (e) {
          return false;
        }
      }
      return false;
    }).toList();
  }

  Future<void> _fetchHolidaysFromApi(String cacheKey) async {
    try {
      final value = await HolidayAPIS().getHolidays();
      _processHolidayList(value);
      
      _hasLoadedHolidaysThisSession = true;
      islodering = false;

      // Save to cache
      final jsonList = value.map((e) => e.toJson()).toList();
      await LocalCacheService.instance.saveCache(cacheKey, jsonEncode(jsonList));

      notifyListeners();
    } catch (e) {
      islodering = false;
      notifyListeners();
    }
  }

  //----------------------------------Get Holiday List -------------------\\

  Future<void> getAllHoliday() async {
    try {
      final value = await HolidayAPIS().getHolidays();
      _processHolidayList(value);
    } catch (e) {
      setloading(false);
    }
  }

  //----------------------------------Get Holiday List -------------------\\

  //----------------------- Delete Holiday Data -----------------------\\

  // delete Funcation
  Future deleteHolidayHandleSubmit(context,{setdid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await  HolidayAPIS().deleteHoliday(setdid.holidayId).then((value) async {
        GetCompanyListModel deleteResponse = value as GetCompanyListModel;
        if (deleteResponse.success == true) {
          if(deleteResponse.data == "Success"){
            showtoastmessage('Delete Successfully');
            await loadingData();
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

  //----------------------- Delete Holiday Data -----------------------\\

  selectHolidayType(value) {
    selectedHolidayType = value;
    notifyListeners();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    if (selectedDates.contains(normalizedDay)) {
      selectedDates.remove(normalizedDay);
    } else {
      selectedDates.add(normalizedDay);
    }

    selectedDates.sort((a, b) => a.compareTo(b));
    this.focusedDay = focusedDay;
    notifyListeners();
  }

  bool isSelected(DateTime day) {
    dateError = false;
    return selectedDates.any(
      (d) =>
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day,
    );
  }

  dateselectOntap(format) {
    calendarFormat = format;
    dateError = false;
    notifyListeners();
  }

  removeSelectDate(date) {
    selectedDates.remove(date);
    notifyListeners();
  }

  clearHolidayData() {
    autoHolidaysvalidateMode = AutovalidateMode.disabled;
    txtTitle.text = "";
    txtDescription.text = "";
    selectedHolidayType = paidHolidayString.toString().split(" ").first.toString();
    selectedDates.clear();
    focusedDay = DateTime.now();
    calendarFormat = CalendarFormat.week;
    dateError = false;
    notifyListeners();
  }

  // add and edit button ontap 
  Future handleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autoHolidaysvalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate() && selectedDates.isNotEmpty) {
        setloading(true);
        notifyListeners();
        String setGuid = generateCustomUuid();
        List selectedDateStrings = selectedDates.map((date) {
          return date.toIso8601String();
        }).toSet().toList();
        await HolidayAPIS().newHolidayCreate(
          setCguid: addEditFlag == true ? setGuid :setdid.cguid.toString(),
          insertmood: addEditFlag,
          setDecription: txtDescription.text,
          holidayDates:  selectedDateStrings,
          holidaynames: txtTitle.text,
          holidayType: selectedHolidayType,masterCguid: addEditFlag == true ?"":setdid.masterCguid).then((value) async { 
          NewHolidayCreate newHolidayCreateResponse = value  as NewHolidayCreate;
          if(newHolidayCreateResponse.success == true){
            if(addEditFlag == true){
              showtoastmessage('Add Successfully');
            }else{
              showtoastmessage('Update Successfully');
            }
          }
          await loadingData();
          await clearHolidayData();
          setloading(false);
          Navigator.pop(context);  
        }).onError((error, stackTrace) {
          setloading(false);
        },);
        autoHolidaysvalidateMode = AutovalidateMode.disabled;
      } else{
        if (selectedDates.isEmpty) {dateError = true;notifyListeners();return;} else {dateError = false;notifyListeners();}
      }
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  // edit handle Submit
  Future editHandleSubmit(context,GetHolidayViews getHolidayById) async {
    try {
      setloading(true);
      await HolidayAPIS().getHolidayById(getHolidayById.masterCguid).then((value) {
        getholiday = value;
        notifyListeners();
        txtTitle.text = getHolidayById.holidayName.toString();
        txtDescription.text = getHolidayById.description.toString();
        selectedDates = (getholiday!.holidayDate as List<dynamic>).map((e) => DateTime.parse(e.toString()),).toList();
        selectedHolidayType = getHolidayById.holidayType ?? '';
      });
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }
}
