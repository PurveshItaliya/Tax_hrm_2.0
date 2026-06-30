// ignore_for_file: strict_top_level_inference, empty_catches


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/api/additionApi.dart';
import 'package:tax_hrm/models/additions/additem.dart';
import 'package:tax_hrm/models/additions/createadditionmodal.dart';
import 'package:tax_hrm/models/additions/deleteaddionmodal.dart';
import 'package:tax_hrm/models/additions/editadditionmodal.dart';
import 'package:tax_hrm/models/additions/employeaddition.dart';
import 'package:tax_hrm/models/additions/getaddtionmodal.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/addition_deduction/add_addition_deduction_screen.dart';
import 'package:tax_hrm/page/addition_deduction/addition_deduction_design.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class AdditionProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  additionLoadingData() async {
    try {
      setloading(true);
      await getAdditionMasterData();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  // Get Addition List
  List<AdditionModal> mainAdditionLists = [];
  List<AdditionModal> mainAdditionGroupList = [];
  List<Employeelists> employesDataList  = [];
  AutovalidateMode autoAdditionDeductionvalidateMode = AutovalidateMode.disabled;
  TextEditingController txthraController = TextEditingController();
  TextEditingController txtdaController = TextEditingController();
  TextEditingController txtConveyanceController = TextEditingController();
  TextEditingController txtSpecialAllowanceController = TextEditingController();
  TextEditingController txtMedicalAllowanceController = TextEditingController();
  TextEditingController txtPfController = TextEditingController();
  TextEditingController txtTdsController = TextEditingController();
  TextEditingController txtEsicController = TextEditingController();
  TextEditingController txtProfessionalTaxController = TextEditingController();
  TextEditingController txtRemarkController = TextEditingController();
  TextEditingController txtAmountController = TextEditingController();
  TextEditingController txtdateController = TextEditingController();
  DateTime selectDate = DateTime.now();
  Employeelists? selectedEmployeeList;
  var selectType = additionOrDeductionString.toString().split("/").first.toString();
  List<String> selectAdditionSelect = [
    additionOrDeductionString.toString().split("/").first.toString(),
    additionOrDeductionString.toString().split("/").last.toString(),
  ];
  bool hraValue = false;
  bool daValue = false;
  bool conveyanceValue = false;
  bool specialAllowanceValue = false;
  bool medicalAllowanceValue = false;
  bool pfValue = false;
  bool tdsValue = false;
  bool esicValue = false;
  bool professionalTaxValue = false;
  int currentSelection = 0;
  Map<int, Widget> options = {
    0: Text(additionOrDeductionString.toString().split("/").first),
    1: Text(additionOrDeductionString.toString().split("/").last),
  };

  //-----------------------Get Addition Deduction Data -----------------------\\

  Future  getAdditionMasterData()async{
    await AdditionApiClass().getadditiongroup().then((value) {
      mainAdditionLists = value;
      mainAdditionGroupList = value;
    });
  }

  //-----------------------Get Addition Deduction Data -----------------------\\

  //----------------------- Delete Addition Deduction Data -----------------------\\

  // delete Funcation
  Future deleteAdditionDeductionHandleSubmit(context,{setdid}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await  AdditionApiClass().deleteAddition(setdid.cguid).then((value) async {
        DeleteAdditionModal deleteReponse = value as DeleteAdditionModal;
        if (deleteReponse.success == true) {
          if(deleteReponse.data == "Success"){
            showtoastmessage('Delete Successfully');
            await getAdditionMasterData();
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

  //----------------------- Delete Addition Deduction Data -----------------------\\

  checkBoxhrmValueChange(value) {
    hraValue = value!;
    notifyListeners();
  }

  checkBoxdaValueChange(value) {
    daValue = value!;
    notifyListeners();
  }

  checkBoxconveyanceValueChange(value) {
    conveyanceValue = value!;
    notifyListeners();
  }

  checkBoxspecialAllowanceValueChange(value) {
    specialAllowanceValue = value!;
    notifyListeners();
  }

  checkBoxmedicalAllowanceValueChange(value) {
    medicalAllowanceValue = value!;
    notifyListeners();
  }

  checkBoxpfValueChange(value) {
    pfValue = value!;
    notifyListeners();
  }

  checkBoxtdsValueChange(value) {
    tdsValue = value!;
    notifyListeners();
  }

  checkBoxesicValueChange(value) {
    esicValue = value!;
    notifyListeners();
  }

  checkBoxprofessionalTaxValueChange(value) {
    professionalTaxValue = value!;
    notifyListeners();
  }

  hintTextValue(filedsValue,boolValue) {
    return "Enter $filedsValue ${!boolValue ?"in Rs.":"in %"} ";
  }

  // employee Name select
  employessontap(value) {
    selectedEmployeeList = value;
    notifyListeners();
  }

  // employee Name select
  selectTypeontap(value) {
    selectType = value;
    notifyListeners();
  }

  ontabMaterioal(int indexs) {
    currentSelection = indexs;
    notifyListeners();
  }

  // handle Submit List

  Future handleSubmitList(context,getAdditionData,addEditFlag) async {
    try {
      clearData();
      nextScreen(context,AddAdditionDeductionScreen(getAdditionData: getAdditionData,addEditFlag: addEditFlag,),onthenValue: (value) {});
    } catch (e){ /* ignored */ }
  }

  // add additional deduction button u
  addHandleAdditionCardDesign(context,{size,formKey,datePickerProvider}) {
    if (formKey.currentState!.validate()) {
      clearDialogData();
      additiondeductionSelectDialog(context,size: size,datePickerProvider: datePickerProvider,addEditFlag: true,index: 0);
    }
  }

  // select Date Functionlity
  Future selectDatePicker(context,size,{required CommandWidigetsProvider dateController,selectDatePic,pickerStartDate}) async {
    await dateController.pickDate(context, size, selectDatePic, pickerStartDate??DateTime(1900), DateTime(3100), (value){selectDatePic = value;notifyListeners();});
    return selectDatePic;
  }

  btnAddAdditionDeduction(context,addEditFlag,index) {
    try {
      if(txtAmountController.text.isEmpty) {
        showtoastmessage(pleaseAmountString);
      } else {
        setloading(true);
        notifyListeners();
        if(addEditFlag){
          additionList.add(ItemsAddAddition(
            empId: selectedEmployeeList!.id.toString(),
            type: selectType,
            amount: txtAmountController.text,
            date: dateFormatdateYMDate(selectDate).toString(),
            remarks: txtRemarkController.text,
            payment: false,
          ));
        } else {
          additionList[index].empId = selectedEmployeeList!.id.toString();
          additionList[index].type = selectType;
          additionList[index].amount = txtAmountController.text;
          additionList[index].date = dateFormatdateYMDate(selectDate).toString();
          additionList[index].remarks = txtRemarkController.text;
        }
        clearDialogData();
        Navigator.pop(context);
      }
      setloading(false);
    } catch (e) {
      setloading(false);
    }
  }

  removeadditionValue(index){
    additionList.removeAt(index);
    notifyListeners();
  }

  editadditionValue(index,context,size,datePickerProvider) {
    selectType = additionList[index].type;
    txtAmountController.text = additionList[index].amount == null ? '' :  additionList[index].amount.toString();
    selectDate = DateTime.parse(additionList[index].date.toString());
    txtdateController.text = dateFormatdate(selectDate);
    txtRemarkController.text = additionList[index].remarks ?? '';
    notifyListeners();
    additiondeductionSelectDialog(context,size: size,datePickerProvider: datePickerProvider,addEditFlag: false,index: index);
  }

  clearData() {
    autoAdditionDeductionvalidateMode = AutovalidateMode.disabled;
    txthraController.text = "";
    txtdaController.text = "";
    txtConveyanceController.text = "";
    txtSpecialAllowanceController.text = "";
    txtMedicalAllowanceController.text = "";
    txtPfController.text = "";
    txtTdsController.text = "";
    txtEsicController.text = "";
    txtProfessionalTaxController.text = "";
    selectedEmployeeList = null;
    hraValue = false;
    daValue = false;
    conveyanceValue = false;
    specialAllowanceValue = false;
    medicalAllowanceValue = false;
    pfValue = false;
    tdsValue = false;
    esicValue = false;
    additionList.clear();
    additionList2.clear();
    professionalTaxValue = false;
    currentSelection = 0;
  }

  clearDialogData() {
    txtAmountController.text = "";
    selectDate = DateTime.now();
    txtdateController.text = dateFormatdate(selectDate);
    txtRemarkController.text = "";
    selectType = additionOrDeductionString.toString().split("/").first.toString();
    notifyListeners();
  }

  // add and edit button ontap 
  Future handleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autoAdditionDeductionvalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate()) {
        setloading(true);
        notifyListeners();
        String setGuid = generateCustomUuid();
        additionList2.clear();
        for(var i=0; i<additionList.length; i++) {
          additionList2.add(ItemsAddAddition(
            empId: selectedEmployeeList!.id ?? 0,
            type: additionList[i].type,
            amount: double.parse(additionList[i].amount.toString()),
            date: additionList[i].date.toString(),
            remarks: additionList[i].remarks,
            cguid: addEditFlag == true ? setGuid :setdid.cguid.toString(),
            companyId: selectedcurentcompany!.companyId,
          ));
        }
        await AdditionApiClass().createadditiongroup(
          cguId: addEditFlag == true ? setGuid :setdid.cguid.toString(),
          checkInsert: addEditFlag,
          empId: selectedEmployeeList!.id ??0,
          name: '${selectedEmployeeList!.firstName ?? ''} ${selectedEmployeeList!.lastName ?? ''}',
          hra: txthraController.text,
          hRAApplicable: hraValue,
          da: txtdaController.text,
          dAApplicable: daValue,
          conveyance: txtConveyanceController.text,
          conveyApplicable: conveyanceValue,
          tds: txtTdsController.text,
          tDSApplicable: tdsValue,
          esic: txtEsicController.text,
          eSICApplicable: esicValue,
          pf: txtPfController.text,
          pFApplicable: pfValue,
          medicalAmt: txtMedicalAllowanceController.text,
          medicalAmtApplicable: medicalAllowanceValue,
          specialAllowance: txtSpecialAllowanceController.text,
          specialApplicable: specialAllowanceValue,
          professinalTax: txtProfessionalTaxController.text,
          professinalApplicable: professionalTaxValue,

          addDecId: addEditFlag ?"":setdid.empId.toString(),).then((value) async { 
          CreateAdditionModal responseData = value as CreateAdditionModal;
          if(responseData.success == true) {
            if(addEditFlag == true){
              showtoastmessage('Addition Created Successfully');
            }else{
              showtoastmessage('Addition Update Successfully');
            }
          }
          await additionLoadingData().then((value) {
            Provider.of<AppPaginationProvider>(context,listen: false).countPaginationPage(mainAdditionGroupList,0);
          },);
          await clearData();
          setloading(false);
          Navigator.pop(context);  
        }).onError((error, stackTrace) {
          setloading(false);
        },);
        autoAdditionDeductionvalidateMode = AutovalidateMode.disabled;
      }
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  //-----------------------Get Update Additions -----------------------\\
  EditAdditionModal? editAdditionModal;

  editHandleSubmit(context,AdditionModal getAdditionData) async {
    try {
      setloading(true);
      notifyListeners();
      await AdditionApiClass().updateAdditions(empId:  getAdditionData.empId).then((value) async {
        editAdditionModal = value;
        txthraController.text = editAdditionModal!.addDedMst!.hRA ?? '';
        txtdaController.text = editAdditionModal!.addDedMst!.dA ?? '';
        txtConveyanceController.text = editAdditionModal!.addDedMst!.conveyance ?? '';
        txtSpecialAllowanceController.text = editAdditionModal!.addDedMst!.specialAllowance == null ? '' : editAdditionModal!.addDedMst!.specialAllowance.toString();
        txtMedicalAllowanceController.text = editAdditionModal!.addDedMst!.medicalAmt == null ? '' : editAdditionModal!.addDedMst!.medicalAmt.toString();
        hraValue = editAdditionModal!.addDedMst!.hRAApplicable ?? false;
        daValue = editAdditionModal!.addDedMst!.dAApplicable ?? false;
        conveyanceValue = editAdditionModal!.addDedMst!.conveyanceApplicable ?? false;
        specialAllowanceValue = editAdditionModal!.addDedMst!.specialApplicable ?? false;
        medicalAllowanceValue = editAdditionModal!.addDedMst!.medicalAmtApplicable ?? false;
        pfValue = editAdditionModal!.addDedMst!.pFApplicable ?? false;
        esicValue = editAdditionModal!.addDedMst!.eSICApplicable ?? false;
        tdsValue = editAdditionModal!.addDedMst!.tDSApplicable ?? false;
        professionalTaxValue = editAdditionModal!.addDedMst!.professinalApplicable ?? false;
        txtPfController.text = editAdditionModal!.addDedMst!.pF ?? '';
        txtEsicController.text = editAdditionModal!.addDedMst!.eSIC ?? '';
        txtTdsController.text = editAdditionModal!.addDedMst!.tDS ?? '';
        txtProfessionalTaxController.text = editAdditionModal!.addDedMst!.professinalTax.toString();
        for(var i=0; i < editAdditionModal!.addDedDetail!.length; i++) {
          additionList.add(ItemsAddAddition(
            empId: editAdditionModal!.addDedDetail![i].empId ?? '',
            type: editAdditionModal!.addDedDetail![i].type ?? '',
            amount: editAdditionModal!.addDedDetail![i].amount ?? '',
            date: editAdditionModal!.addDedDetail![i].date ?? '',
            remarks: editAdditionModal!.addDedDetail![i].remarks ?? '',
          ));
        }
        setloading(false);
        notifyListeners();
      },).onError((error, stackTrace) {
        setloading(false);
      },);
    } catch (e) {
      setloading(false);
    }
    setloading(false);
  }

  addEditFunction(context,addEditFlag,{getAdditionData}) async {
    try {
      setloading(true);
      await Provider.of<EmployeMastServices>(context,listen: false).getAllEmployesData().then((value) async {
        employesDataList = Provider.of<EmployeMastServices>(context,listen: false).allemployes.where((element) => element.role != 'Admin').toList();
        if(!addEditFlag){
          await AdditionApiClass().updateAdditions(empId:  getAdditionData.empId).then((value) async {
            editAdditionModal = value;
            for (var element in employesDataList) {
              if (element.id == getAdditionData.empId) {
                selectedEmployeeList = element;
              }
            }
            txthraController.text = editAdditionModal!.addDedMst!.hRA ?? '';
            txtdaController.text = editAdditionModal!.addDedMst!.dA ?? '';
            txtConveyanceController.text = editAdditionModal!.addDedMst!.conveyance ?? '';
            txtSpecialAllowanceController.text = editAdditionModal!.addDedMst!.specialAllowance == null ? '' : editAdditionModal!.addDedMst!.specialAllowance.toString();
            txtMedicalAllowanceController.text = editAdditionModal!.addDedMst!.medicalAmt == null ? '' : editAdditionModal!.addDedMst!.medicalAmt.toString();
            hraValue = editAdditionModal!.addDedMst!.hRAApplicable ?? false;
            daValue = editAdditionModal!.addDedMst!.dAApplicable ?? false;
            conveyanceValue = editAdditionModal!.addDedMst!.conveyanceApplicable ?? false;
            specialAllowanceValue = editAdditionModal!.addDedMst!.specialApplicable ?? false;
            medicalAllowanceValue = editAdditionModal!.addDedMst!.medicalAmtApplicable ?? false;
            pfValue = editAdditionModal!.addDedMst!.pFApplicable ?? false;
            esicValue = editAdditionModal!.addDedMst!.eSICApplicable ?? false;
            tdsValue = editAdditionModal!.addDedMst!.tDSApplicable ?? false;
            professionalTaxValue = editAdditionModal!.addDedMst!.professinalApplicable ?? false;
            txtPfController.text = editAdditionModal!.addDedMst!.pF ?? '';
            txtEsicController.text = editAdditionModal!.addDedMst!.eSIC ?? '';
            txtTdsController.text = editAdditionModal!.addDedMst!.tDS ?? '';
            txtProfessionalTaxController.text = editAdditionModal!.addDedMst!.professinalTax.toString();
            for(var i=0; i < editAdditionModal!.addDedDetail!.length; i++) {
              additionList.add(ItemsAddAddition(
                empId: '${selectedEmployeeList!.firstName  ?? ''} ${selectedEmployeeList!.lastName  ?? ''}',
                type: editAdditionModal!.addDedDetail![i].type ?? '',
                amount: editAdditionModal!.addDedDetail![i].amount ?? '',
                date: editAdditionModal!.addDedDetail![i].date ?? '',
                remarks: editAdditionModal!.addDedDetail![i].remarks ?? '',
              ));
            }
          },).onError((error, stackTrace) {
            setloading(false);
          },);
        }
      },);
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  
  double totalDeduction =0;
  double totalAddtion =0;
  AdditionDeducationEmploye?  setAdditionValues;
  
  Future  getEmployeWiseAdditionDeduction({setemployeId,setmonth,setyear})async{
    setloading(true);
    totalDeduction =0;
    totalAddtion =0;
    await AdditionApiClass().getAdditionDeducation(employeId: setemployeId,month: setmonth,year: setyear).then((value) {
      setAdditionValues  = value;
      if(setAdditionValues!.addDedDetail!.isNotEmpty) {
        for (var element in setAdditionValues!.addDedDetail!) {
          if(element.type == 'Deduction'){
            totalDeduction = totalDeduction + double.parse(element.amount.toString());
          }else{
            totalAddtion = totalAddtion + double.parse(element.amount.toString());
          }
        }
      }
      notifyListeners();
      setloading(false);
    },).onError((error, stackTrace) {
      showtoastmessage('Something Wrong');
      setloading(false);
    },);
  }
}
