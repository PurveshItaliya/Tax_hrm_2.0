// ignore_for_file: strict_top_level_inference, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tax_hrm/api/leavesapi.dart';
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/customeclass/simpleclass.dart';
import 'package:tax_hrm/models/leaveM/deleteleave_modal.dart';
import 'package:tax_hrm/models/leaveM/getleavemaster.dart';
import 'package:tax_hrm/models/leaveM/newleavemaster.dart';
import 'package:tax_hrm/page/admin_leave_master/add_admin_leave_master_screen.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class LeaveEmployeeeMastServices extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  // ************************************************** admin Leave Management *******************************************************

  AutovalidateMode autoLeaveMatervalidateMode = AutovalidateMode.disabled;
  TextEditingController txtAdminLeaveFullNController = TextEditingController();
  TextEditingController txtAdminLeaveSNameController = TextEditingController();
  TextEditingController txtAdminLeaveDesController = TextEditingController();
  TextEditingController txtAdminLeaveLimitController = TextEditingController();
  TextEditingController txtAdminPolicyDateController = TextEditingController();
  DateTime leavePolicyDate = DateTime.now();
  String selectedLeaveType = paidLeaveString.toString().split(" ").first.toString();
  bool considerWeeklyOffValue = true;
  bool considerHolidayValue = false;
  TypedClass? selectMasterselection;

  
  adminloadingData() async {
    try {
      setloading(true);
      await getAdminLeaveData();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  List<GetLeaveMaster> maonLeaveTyeList = [];
  List<GetLeaveMaster> getAllleaveTypesList = [];

  Future getAdminLeaveData()async{
    await LeaveMasterApiService().getLeaveMlist().then((value) {
      maonLeaveTyeList = value;
      getAllleaveTypesList = value;
      notifyListeners();
    });
  }

  // select Date Functionlity
  Future selectDatePicker(context,size,{required CommandWidigetsProvider dateController,selectDatePic,pickerStartDate}) async {
    await dateController.pickDate(context, size, selectDatePic, pickerStartDate??DateTime(1900), DateTime(3100), (value){selectDatePic = value;notifyListeners();});
    return selectDatePic;
  }

  selectLeaveType(value) {
    selectedLeaveType = value;
    notifyListeners();
  }

  selectConsiderWeeklyOffValue(value) {
    considerWeeklyOffValue = value;
    notifyListeners();
  }

  selectConsiderHolidayValue(value) {
    considerHolidayValue = value;
    notifyListeners();
  }

  // delete Admin Leave Master
  deleteAdminLeaveMaster(context,{leaveTypeID}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await LeaveMasterApiService().deleteLeaveApi(leaveTypeID: leaveTypeID).then((value) async {
        GetDeleteLeaveModal deleteResponse = value as GetDeleteLeaveModal;
        if (deleteResponse.success == true) {
          if(deleteResponse.data == "Success"){
            await adminloadingData();
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

  ontapSelections(value) {
    selectMasterselection = value;
    notifyListeners();
  }

  iconAddOntap(context) async {
    selectMasterselection = null;
    notifyListeners();
  }

  clearData() {
    autoLeaveMatervalidateMode = AutovalidateMode.disabled;
    txtAdminLeaveFullNController.text = "";
    txtAdminLeaveSNameController.text = "";
    txtAdminLeaveDesController.text = "";
    txtAdminLeaveLimitController.text = "";
    leavePolicyDate = DateTime.now();
    txtAdminPolicyDateController.text = dateFormatdate(leavePolicyDate);
    selectedLeaveType = paidLeaveString.toString().split(" ").first.toString();
    considerWeeklyOffValue = true;
    considerHolidayValue = false;
    selectMasterselection = null;
  }

  // add admin Leave and edit button ontap 
  Future adminLeaveHandleSubmit(context,formkey,addEditFlag,setdid) async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      autoLeaveMatervalidateMode = AutovalidateMode.always;
      if (formkey.currentState!.validate() && selectMasterselection != null) {
        if (txtAdminLeaveSNameController.text.trim().length > 5) {
          showtoastmessage('Leave Type Short Name maximum 5 characters');
          return;
        }

        setloading(true);
        notifyListeners();
        String setGuid = generateCustomUuid();
        final leaveLimitValue = int.tryParse(txtAdminLeaveLimitController.text.trim()) ?? 0;
        final selectedLimit = selectMasterselection!.values;
        await LeaveMasterApiService().createNewLeaveType(
          carryForwards: 0,
          leaveTypeFnames: txtAdminLeaveFullNController.text,
          leaveTypesnames: txtAdminLeaveSNameController.text,
          setCguid:  addEditFlag == true ? setGuid : setdid.cguid,
          setDescriptions: txtAdminLeaveDesController.text,
          setMonthlys: selectedLimit == 'Monthly' ? leaveLimitValue : 0,
          setPolicydate: dateFormatdateYMDate(leavePolicyDate).toString(),
          setholiday: considerHolidayValue,
          setquartely: selectedLimit == 'Quarterly' ? leaveLimitValue : 0,
          setweekoff:considerWeeklyOffValue,
          yearlimits: selectedLimit == 'Yearly' ? leaveLimitValue : 0,
          insertMoods: addEditFlag,
          setLeaveids: addEditFlag ? "" : setdid.leaveTypeId, 
          leaveType: selectedLeaveType,
          halfYear: selectedLimit == 'HalfYearly' ? leaveLimitValue : 0,
          leaveLimit: selectedLimit,
        ).then((value) async {
          NewLeaveTypes responseData = value as NewLeaveTypes;
          if(responseData.success == true) {
            if(addEditFlag == true){
              showtoastmessage('Add Successfully');
            } else{
              showtoastmessage('Update Successfully');
            }
            await getAdminLeaveData();
            await clearData();
            setloading(false);
            Navigator.pop(context);
          } else {
            showtoastmessage('Leave type save failed');
            setloading(false);
          }
        }).onError((error, stackTrace) {
          showtoastmessage(error.toString());
          setloading(false);
        },);
        autoLeaveMatervalidateMode = AutovalidateMode.disabled;
      } else {
        showtoastmessage(pleaseSelectLeaveLimitString);
      }
    } catch (e) {
      showtoastmessage(e.toString());
      setloading(false);
    }
    notifyListeners();
  }

  // edit Leave master Funcation
  addEditFunction(context,addEditFlag,{getAdminLeaveData}) async {
    try {
      setloading(true);
      notifyListeners();
      txtAdminLeaveFullNController.text = getAdminLeaveData.leaveTypeFName.toString();
      txtAdminLeaveSNameController.text = getAdminLeaveData.leaveTypeSName.toString();
      txtAdminLeaveDesController.text = getAdminLeaveData.description.toString();
      considerWeeklyOffValue = getAdminLeaveData.considerWeeklyOff.toString() == 'true' ? true : false;
      considerHolidayValue = getAdminLeaveData.considerHoliday.toString() == 'true' ? true : false;
      txtAdminPolicyDateController.text = dateFormatdate(DateTime.parse(getAdminLeaveData.policyIssueDate));
      leavePolicyDate = DateTime.parse(getAdminLeaveData.policyIssueDate.toString());
      selectMasterselection = leaveTypeMasters.firstWhere((item) => item.values == getAdminLeaveData.leaveLimit,);
      if(selectMasterselection != null){
        if(selectMasterselection!.keys == "Monthly") {
          txtAdminLeaveLimitController.text = getAdminLeaveData.monthly.toString();
        } else if(selectMasterselection!.keys == "Quarterly") {
          txtAdminLeaveLimitController.text = getAdminLeaveData.quarterly.toString();
        } else if(selectMasterselection!.keys == "HalfYearly") {
          txtAdminLeaveLimitController.text = getAdminLeaveData.halfYear.toString();
        } else {
          txtAdminLeaveLimitController.text = getAdminLeaveData.yearlyLimit.toString();
        }
      }
      nextScreen(context, AddAdminLeaveMasterScreen(addEditFlag: addEditFlag, getAdminLeaveData: getAdminLeaveData),onthenValue: (value) {});
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }


  // ************************************************** admin Leave Management *******************************************************
}
