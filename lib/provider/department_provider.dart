// ignore_for_file: strict_top_level_inference, avoid_function_literals_in_foreach_calls, empty_catches, use_build_context_synchronously


import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:tax_hrm/services/local_cache_service.dart';
import 'package:tax_hrm/api/departmentapi.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/createdepartment.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/deletedepartment.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class DepartmentServices extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  List<DepartMnetModel> alldepartment = [];
  List<DepartMnetModel> showedepartment = [];
  List<DepartMnetModel> activepartment = [];

  String departmentStatus = 'true';

  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  TextEditingController   departmentnamecontroller = TextEditingController();
  TextEditingController   txtdepartmentSerchController = TextEditingController();

  //--------------------  Get All Department --------------------------\\

  bool _hasLoadedDepartmentsThisSession = false;

  departmentLoadingData({bool forceRefresh = false}) async {
    final cacheKey = '${LocalCacheService.keyMasterData}_departments';
    const ttlMs = 24 * 60 * 60 * 1000; // 24 hours

    if (!forceRefresh && _hasLoadedDepartmentsThisSession) {
      islodering = false;
      notifyListeners();
      return;
    }

    try {
      bool loadedFromCache = false;
      txtdepartmentSerchController.clear();

      if (!forceRefresh) {
        final cachedData = await LocalCacheService.instance.getCache(cacheKey, ttlMilliseconds: ttlMs);
        if (cachedData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(cachedData);
            final cachedList = jsonList.map((e) => DepartMnetModel.fromJson(e)).toList();
            
            alldepartment = cachedList;
            showedepartment = cachedList;
            activepartment.clear();
            for (var element in cachedList) {
              if (element.isActive != false) {
                activepartment.add(element);
              }
            }
            
            _hasLoadedDepartmentsThisSession = true;
            loadedFromCache = true;
            islodering = false;
            notifyListeners();
          } catch (e) {
             // silent fallback
          }
        }
      }

      if (!loadedFromCache || forceRefresh) {
        setloading(true);
      }

      unawaited(_fetchDepartmentFromApi(cacheKey));

    } catch (e) {
      setloading(false);
    }
  }

  Future<void> _fetchDepartmentFromApi(String cacheKey) async {
    try {
      final value = await DepartMentData().getdepartmentdata();
      alldepartment = value;
      showedepartment = value;
      activepartment.clear();
      for (var element in value) {
        if (element.isActive != false) {
          activepartment.add(element);
        }
      }
      
      _hasLoadedDepartmentsThisSession = true;
      setloading(false);

      // Save cache
      final jsonList = value.map((e) => e.toJson()).toList();
      await LocalCacheService.instance.saveCache(cacheKey, jsonEncode(jsonList));

      notifyListeners();
    } catch (e) {
      setloading(false);
    }
  }

  // department get 
  Future getDepartmentMasterData() async {
    activepartment.clear();
    await DepartMentData().getdepartmentdata().then((value) {
      alldepartment = value;
      showedepartment = value;
      alldepartment.forEach((element) {
        if (element.isActive != false) {
          activepartment.add(element);
          notifyListeners();
        }
      });
    });
    return alldepartment;
  }

  //===========================================================================\\

  // dropdown searching
  Future<List<DepartMnetModel>> getFilterDepartment(String ss)async{
    return alldepartment.where((e) {return e.departmentName.toString().toLowerCase().contains(ss.toLowerCase());}).toList();
  }

  // Add Funcation
  Future<void> departmentHandleSubmit(context,size,formKey,{addEditFlag,setdid}) async {
    autovalidateMode = AutovalidateMode.disabled;
    showAddDepartmentDialog(context,size: size,formKey,addEditFlag,setdid: setdid);
  }

  // active and in active
  handleChangeValue(value) {
    departmentStatus = value;
    notifyListeners();
  }

  // Edit Funcation
  Future editDepartmentHandleSubmit(context,size,formKey,{setdid}) async {
    try {
      departmentnamecontroller.text = setdid.departmentName.toString();
      departmentStatus = setdid.isActive.toString().toLowerCase() == 'null' ? "true"  : setdid.isActive.toString();
      departmentHandleSubmit(context,size,formKey,addEditFlag:false,setdid: setdid,);
    } catch (e) { /* ignored */ }
  }

  // add and Edit api Funcation
  Future addDepartHandleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate()) {Navigator.pop(context);
        setloading(true);
        notifyListeners();
        await DepartMentData().createdepartment(tname: departmentnamecontroller.text.toString(),status: departmentStatus,insertmood: addEditFlag  ? true : false,setdid: addEditFlag ? setdid  : setdid!.id).then((value) async {
          CretaeDepartMent departmetresponse = value as CretaeDepartMent;
          if (departmetresponse.success == true) {
            departmentnamecontroller.clear();
            departmentStatus = 'true';
            if (addEditFlag == true) {
              showtoastmessage('New Department Add Successfully');
            } else {
              showtoastmessage(' Department Update Successfully');
            }
            await getDepartmentMasterData();
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
  Future deleteDepartmentHandleSubmit(context,{setdid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await DepartMentData().departdeletefiles(setdid.id).then((value) async {
        DeleteDepartmentmodel deleteResponse = value as DeleteDepartmentmodel;
        if (deleteResponse.success == true) {
          if(deleteResponse.data == "Success"){
            showtoastmessage('Department Delete Successfully');
            await getDepartmentMasterData();
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

  //------------------   Get Department ById ---------------\\
  DepartMnetModel?  getDepartmetData;

  Future departmentbyId(setdepartmentid)async{
    setloading(true);
  await DepartMentData().departmetById(setdepartmentid).then((value) {
  getDepartmetData = value;
    setloading(false);
  notifyListeners();
  },);
    setloading(false);
  notifyListeners();
  return getDepartmetData;
  }

}
