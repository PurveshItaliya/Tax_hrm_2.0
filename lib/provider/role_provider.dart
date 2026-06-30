// ignore_for_file: empty_catches, strict_top_level_inference


import 'package:flutter/material.dart';
import 'package:tax_hrm/api/roleApi.dart';
import 'package:tax_hrm/models/role/create_role.dart';
import 'package:tax_hrm/models/role/delete_role.dart';
import 'package:tax_hrm/models/role/get_role_model.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class RoleMstServices extends ChangeNotifier {
  List<Getrolemodel> getRoleList = [];
  List<Getrolemodel> mainRoleList = [];

  bool islodering = false;
  bool get isloderings => islodering;
  setloading(bool value) {
    islodering = value;
    // notifyListeners();
  }
  
  Future getAllRoleTypes() async {
    setloading(true);
    try {
      final value = await Roleapi().getRole();
      mainRoleList = value;
      getRoleList = value;
    } catch (e) { /* ignored */ } finally {
      setloading(false);
      notifyListeners();
    }
  }
  //---------------------------Create New Role-----------------------------------------\\
  createNewRole(rolename, context, setMood, setrid) {
    Roleapi().roleecreate(rolename, setMood, setrid).then((value) {
      NewRoles newRoleResponse = value as NewRoles;
      if (newRoleResponse.success == true) {
        if (setMood == true) {
          showtoastmessage('Role Add Successfully');
        } else {
          showtoastmessage('Role Update Successfully');
        }

        getAllRoleTypes();
        Navigator.pop(context);
      }
    });
  }
  //-----------------------------------------------------------------\\
  deletedRole(roleids) {
    Roleapi().roledeletefiles(roleids).then((value) {
      try {
        DeleteRoles deletedResponse = value as DeleteRoles;
        if (deletedResponse.success == true) {
          showtoastmessage('Delete Successfully');
        }
        getAllRoleTypes();
      } catch (e) { /* ignored */ }
    });
  }
}
