// ignore_for_file: strict_top_level_inference

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/models/fixeddat.dart';

class SaveUser {
  String savecompany = 'companysave';

  String data = 'data';
  saveUserData(String userdat) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(data, userdat);
  }

  Future<String> getUserDatas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userdata = prefs.getString(data) ?? '';
    return userdata;
  }

  //------------------------------Select company ----------------------\\ 
  saveselectedcopany(String userdat) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(savecompany, userdat);
  }

  Future<String> getselectedcompany() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userdata = prefs.getString(savecompany) ?? '';
    return userdata;
  }
  
  //---------------  Admin Switch Data Save ------------\\
  Future<void> saveAdminSwitch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdminSwitch', value);
    loadAdminSwitch();
  }

  Future<void> loadAdminSwitch() async {
    final prefs = await SharedPreferences.getInstance();
    switchValue = prefs.getBool('isAdminSwitch') ?? false;
  }
}
