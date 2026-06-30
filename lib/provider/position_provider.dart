// ignore_for_file: strict_top_level_inference, empty_catches

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/positionapi.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/deletmodel.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/postmodel.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class PositionMasterService extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  List<PositionDataL>  showPositions = [];
  List<PositionDataL>  getFiltersPostionList= [];
  List<PositionDataL> positionlistt = []; 

  String designationStatus = 'true';
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  TextEditingController   designationnamecontroller = TextEditingController();
  DepartMnetModel?  selectedDepartment;

  //==========================  Get All Position ==========================\\

  designatiionLoadingData() async {
    try {
      setloading(true);
      await getpositionfiles();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }
  
  // data Get to designation
  Future  getpositionfiles() async {
    await  PositionsApiCall().positionss().then((value) {
      showPositions = value;
      positionlistt = value;
      notifyListeners();
    });
  }

  //==========================  Get All Position ==========================\\

  // Add Funcation
  Future<void> designationHandleSubmit(context,size,formKey,{addEditFlag,setdid}) async {
    autovalidateMode = AutovalidateMode.disabled;
    showAddDesignationDialog(context,size: size,formKey,addEditFlag,setdid: setdid);
  }

  // active and in active
  handleChangeValue(value) {
    designationStatus = value;
    notifyListeners();
  }

  // department Name select
  depatmentontap(value) {
    selectedDepartment = value;
    notifyListeners();
  }

  // add and Edit api Funcation
  Future addDesignationHandleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autovalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate()) {
        Navigator.pop(context);
        setloading(true);
        notifyListeners();
        await PositionsApiCall().designationcreate(departmentname: selectedDepartment == null? 0 : selectedDepartment!.id,positionname: designationnamecontroller.text.toString(),positionststatus: designationStatus,insertmod:addEditFlag  ? true : false,positionid: addEditFlag ? setdid  : setdid!.id).then((value) async {
          PositionCreate  positioncreateResponse = value as PositionCreate;     
          if (positioncreateResponse.success == true) {
            designationnamecontroller.clear();
            designationStatus = 'true';
            selectedDepartment = null;
            if (addEditFlag == true) {
              showtoastmessage('New Designation Add Successfully');
            } else {
              showtoastmessage(' Designation Update Successfully');
            }
            await getpositionfiles();
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

    // Edit Funcation
  Future editDesignationHandleSubmit(context,size,formKey,{setdid}) async {
    try {
      Provider.of<DepartmentServices>(context,listen: false).alldepartment.forEach((element) {
        if(element.id == setdid!.departmentId){
          selectedDepartment = element;
          notifyListeners();
        }
      });
      designationnamecontroller.text = setdid.positionName.toString();
      designationStatus = setdid.isActive.toString().toLowerCase() == 'null' ? "true"  : setdid.isActive.toString();
      designationHandleSubmit(context,size,formKey,addEditFlag:false,setdid: setdid,);
    } catch (e) { /* ignored */ }
  }

  
  // delete Funcation
  Future deleteDesignationHandleSubmit(context,{setdid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await PositionsApiCall().deletepositionfiles(setdid.id).then((value) async {
        Deleteposition   deleteResponse = value as Deleteposition;
        if (deleteResponse.success == true) {
          if(deleteResponse.data == "Success"){
            showtoastmessage('Designation Delete Successfully');
            await getpositionfiles();
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

}
