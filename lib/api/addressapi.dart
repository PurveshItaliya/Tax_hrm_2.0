// ignore_for_file: non_constant_identifier_names
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/address/citylist_model.dart';
import 'package:tax_hrm/models/address/ip_address.dart';
import 'package:tax_hrm/models/address/pincode_model.dart';
import 'package:tax_hrm/models/address/statelist_model.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class AddresDataApi{
Future PinCode() async {
  var url = Uri.parse("$apibaseurl/api/Master/PincodeList");

  var response = await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'},);

  return pincodemFromJson(response.body);
}

Future citylist() async {
  var url = Uri.parse("$apibaseurl/api/Master/CityList");

  var response = await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'},);

  return citylistmFromJson(response.body);
}

Future statelist() async {
  var url = Uri.parse("$apibaseurl/api/Master/StateList");

  var response = await http.get(url, headers: {'Authorization': 'bearer ${curentUser['token']}'},);

  return statelistmFromJson(response.body);
}


Future getIpAddres() async {
  var url = Uri.parse("https://api.ipify.org?format=json");

  var response = await http.get(url,);
  return   getIpAddresFromJson(response.body);
}

}