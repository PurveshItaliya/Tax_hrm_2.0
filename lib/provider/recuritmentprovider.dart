// ignore_for_file: strict_top_level_inference, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/recuritmentApi.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/recruitment/createrecuritment_modal.dart';
import 'package:tax_hrm/models/recruitment/deleterecuritment_model.dart';
import 'package:tax_hrm/models/recruitment/recruitmentmodel.dart';
import 'package:tax_hrm/page/recruitment/add_recruitment_screen.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class RecuritmentProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  // Get Recuritment List
  List<RecruitmentModal> mainRecuirtmentLists = [];
  List<RecruitmentModal> getRecuirtmentGroupList = [];

  AutovalidateMode autoRecuritmentvalidateMode = AutovalidateMode.disabled;
  TextEditingController txtSerchController = TextEditingController();
  TextEditingController txtCandidateNameController = TextEditingController();
  TextEditingController txtCandidateDateController = TextEditingController();
  TextEditingController txtreferenceByController = TextEditingController();
  TextEditingController txtVenueController = TextEditingController();
  TextEditingController txtExperienceController = TextEditingController();
  TextEditingController txtMobileController = TextEditingController();
  TextEditingController txtEmailController = TextEditingController();
  TextEditingController txtLastSalaryController = TextEditingController();
  TextEditingController txtExperienceSalaryController = TextEditingController();
  TextEditingController txtRemarkController = TextEditingController();
  DateTime recurimentStartDate = DateTime.now();
  DepartMnetModel? selectedDepartment;
  PositionDataL? selectedDesignation;
  Employeelists? selectedEmployeeList;
  List<PositionDataL>  getFiltersPostionList= [];

  recuritmentLoadingData() async {
    try {
      setloading(true);
      txtSerchController.clear();
      await getrecuritmentMasterData();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  // get to recuritment master
  Future getrecuritmentMasterData()async{
    await RecuritmetntApiClass().getrecuritmentgroup().then((value) {
     mainRecuirtmentLists = value;
     getRecuirtmentGroupList = value;
    });
  }

  // search All Recuritment Data
  void searchAllRecuritmentData(String inputText) {
    final query = inputText.toLowerCase();
    getRecuirtmentGroupList = mainRecuirtmentLists.where((element) {return element.name.toString().toLowerCase().contains(query);}).toList();
    notifyListeners(); // ✅ ONLY HERE
  }

  //****************************************** Delete recuritment Master ****************************************************** */

  // delete recuritment master
  deleteRecuritmentMaster(context,{setRecuritmentid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await RecuritmetntApiClass().deleteRecuritment(setId: setRecuritmentid).then((value) async {
        DeleteRecuritmentModal deleteReponse = value as DeleteRecuritmentModal;
        if (deleteReponse.success == true) {
          if(deleteReponse.data == "Success"){
            await getrecuritmentMasterData();
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

  //****************************************** Delete recuritment Master ****************************************************** */

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

  // select Date Functionlity
  Future selectDatePicker(context,size,{required CommandWidigetsProvider dateController,selectDatePic,pickerStartDate}) async {
    await dateController.pickDate(context, size, selectDatePic, pickerStartDate??DateTime(1900), DateTime(3100), (value){selectDatePic = value;notifyListeners();});
    return selectDatePic;
  }

  // employee Name select
  employessontap(value) {
    selectedEmployeeList = value;
    notifyListeners();
  }

  // clear data
  clearDataRecuriment(context,addEditFlag) {
    autoRecuritmentvalidateMode = AutovalidateMode.disabled;
    txtSerchController = TextEditingController();
    txtCandidateNameController = TextEditingController();
    txtreferenceByController = TextEditingController();
    txtVenueController = TextEditingController();
    txtExperienceController = TextEditingController();
    txtMobileController = TextEditingController();
    txtEmailController = TextEditingController();
    txtLastSalaryController = TextEditingController();
    txtExperienceSalaryController = TextEditingController();
    txtRemarkController = TextEditingController();
    recurimentStartDate = DateTime.now();
    txtCandidateDateController.text = dateFormatdate(recurimentStartDate);
    selectedDepartment= null;
    selectedDesignation= null;
    Provider.of<EmployeMastServices>(context,listen: false).getAllEmployesData().then((value) {
      if(addEditFlag) {
        selectedEmployeeList = Provider.of<EmployeMastServices>(context,listen: false).emplists.first;
        notifyListeners();
      }
    },);
    getFiltersPostionList= [];
  }

  // add and edit button ontap 
  Future handleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autoRecuritmentvalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate()) {
        setloading(true);
        notifyListeners();
        String setGuid = generateCustomUuid();
        await RecuritmetntApiClass().createrecruitmentgroup(addEditFlag,recruitmentId: addEditFlag?"":setdid.recruitmentID, name: txtCandidateNameController.text.toString(),recruitmentDate: dateFormatdateYMDate(recurimentStartDate).toString(), departmentId: selectedDepartment == null ? ""  : selectedDepartment!.id, positionId: selectedDesignation == null ? ""  : selectedDesignation!.id, conductedBy: selectedEmployeeList == null ?  ""  : selectedEmployeeList!.id, referenceBy: txtreferenceByController.text.toString(), venue: txtVenueController.text.toString(), experience: txtExperienceController.text.toString(), mobile: txtMobileController.text.toString(), email: txtEmailController.text.toString(), lastSalary: txtLastSalaryController.text.toString(), expectedSalary: txtExperienceSalaryController.text.toString(), remark: txtRemarkController.text.toString(),custId: curentUser['CustId'], cguId: addEditFlag == true ? setGuid :setdid.cguid.toString()).then((value) async { 
          CreateRecuritmentModal responseData = value as CreateRecuritmentModal;
          if(responseData.success == true) {
            if(addEditFlag == true){
              showtoastmessage('Recuritment Created Successfully');
            } else  {
              await recuritmentLoadingData();
              showtoastmessage('Recuritment Update Successfully');
            }
          }
          clearDataRecuriment(context,addEditFlag);

          setloading(false);
          Navigator.pop(context);  
        }).onError((error, stackTrace) {
          setloading(false);
        },);
        autoRecuritmentvalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  // edit handle Submit
  Future editHandleSubmit(context,RecruitmentModal getRecruitmentData) async {
    try {
      islodering = true;
      notifyListeners();
      txtCandidateNameController.text = getRecruitmentData.name.toString();
      txtreferenceByController.text = getRecruitmentData.referenceBy.toString();
      txtVenueController.text = getRecruitmentData.venue.toString();
      txtExperienceController.text = getRecruitmentData.experience.toString();
      txtMobileController.text = getRecruitmentData.mobileNo.toString();
      txtEmailController.text = getRecruitmentData.email.toString();
      txtLastSalaryController.text = getRecruitmentData.lastSalary.toString();
      txtExperienceSalaryController.text = getRecruitmentData.expectedSalary.toString();
      txtRemarkController.text = getRecruitmentData.remark.toString();
      recurimentStartDate = DateTime.parse(getRecruitmentData.recruitmentDate.toString());
      txtCandidateDateController.text = dateFormatdate(DateTime.parse(getRecruitmentData.recruitmentDate.toString()));
      if(getRecruitmentData.departmentId != 0) {
        for (var element in Provider.of<DepartmentServices>(context, listen: false).showedepartment) {
          if (element.id == getRecruitmentData.departmentId) {
            selectedDepartment = element;
          }
        }
        getFiltersPostionList.clear();
        selectedDesignation = null;
        for (var element in Provider.of<PositionMasterService>(context,listen: false).showPositions) {
          if(element.departmentName == selectedDepartment!.departmentName){
            if(element.isActive == true) {
              getFiltersPostionList.add(element);
            }
          }
        }
      }
      if(getRecruitmentData.positionId != "") {
        for (var element in Provider.of<PositionMasterService>(context, listen: false).showPositions) {
          if (element.id == getRecruitmentData.positionId) {
            selectedDesignation = element;
          }
        }
      }
      if(getRecruitmentData.conductedBy != "") {
        Provider.of<EmployeMastServices>(context,listen: false).getAllEmployesData().then((value) {
          for (var element in Provider.of<EmployeMastServices>(context, listen: false).emplists) {
            if (element.id.toString() == getRecruitmentData.conductedBy) {
              selectedEmployeeList = element;
            }
          }
          notifyListeners();
        },);
      } else {
        Provider.of<EmployeMastServices>(context,listen: false).getAllEmployesData().then((value) {
          selectedEmployeeList = Provider.of<EmployeMastServices>(context,listen: false).emplists.first;
          notifyListeners();
        },);
      }
      nextScreen(context, AddRecruitmentScreen(addEditFlag: false, getRecruitmentData: getRecruitmentData),onthenValue: (value) {});
      islodering = false;
      notifyListeners();
    } catch (e) {
      islodering = false;
    }
    notifyListeners();
  }
}
